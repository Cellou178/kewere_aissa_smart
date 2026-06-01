from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from datetime import datetime, timedelta
from pydantic import BaseModel

router = APIRouter(prefix="/abonnements", tags=["Abonnements"])

LIMITES = {
    'gratuit':    {'fermes': 1,  'cycles': 2,  'utilisateurs': 1},
    'pro':        {'fermes': 5,  'cycles': -1, 'utilisateurs': 3},
    'enterprise': {'fermes': -1, 'cycles': -1, 'utilisateurs': -1},
}

PRIX = {'gratuit': 0, 'pro': 15000, 'enterprise': 35000}

def _get_or_create(eid: str, db: Session):
    db.execute(text("""
        UPDATE abonnements SET statut = 'expire'
        WHERE entreprise_id = :eid
          AND date_fin IS NOT NULL
          AND date_fin < NOW()
          AND statut = 'actif'
    """), {"eid": eid})
    db.commit()

    row = db.execute(text("""
        SELECT plan, date_debut, date_fin, statut, prix
        FROM abonnements
        WHERE entreprise_id = :eid
        ORDER BY created_at DESC LIMIT 1
    """), {"eid": eid}).fetchone()

    if not row:
        db.execute(text("""
            INSERT INTO abonnements (entreprise_id, plan, statut, prix)
            VALUES (:eid, 'gratuit', 'actif', 0)
        """), {"eid": eid})
        db.commit()
        row = db.execute(text("""
            SELECT plan, date_debut, date_fin, statut, prix
            FROM abonnements WHERE entreprise_id = :eid
            ORDER BY created_at DESC LIMIT 1
        """), {"eid": eid}).fetchone()

    return row

@router.get("/mon-abonnement")
def mon_abonnement(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    eid = str(current_user.entreprise_id)
    row = _get_or_create(eid, db)

    nb = db.execute(text("""
        SELECT
            (SELECT COUNT(*) FROM fermes WHERE entreprise_id = :eid) as fermes,
            (SELECT COUNT(*) FROM cycles c JOIN fermes f ON c.ferme_id = f.id
             WHERE f.entreprise_id = :eid AND c.statut = 'actif') as cycles,
            (SELECT COUNT(*) FROM utilisateurs WHERE entreprise_id = :eid AND actif = true) as utilisateurs
    """), {"eid": eid}).fetchone()

    return {
        "plan": row.plan,
        "statut": row.statut,
        "prix": row.prix,
        "date_debut": row.date_debut.isoformat() if row.date_debut else None,
        "date_fin": row.date_fin.isoformat() if row.date_fin else None,
        "nb_fermes": nb.fermes or 0,
        "nb_cycles": nb.cycles or 0,
        "nb_utilisateurs": nb.utilisateurs or 0,
        "limites": LIMITES.get(row.plan, LIMITES['gratuit']),
    }

@router.get("/historique")
def historique(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT plan, date_debut, date_fin, statut, prix
        FROM abonnements WHERE entreprise_id = :eid
        ORDER BY created_at DESC LIMIT 12
    """), {"eid": str(current_user.entreprise_id)}).fetchall()
    return [{"plan": r.plan, "statut": r.statut, "prix": r.prix,
             "date_debut": r.date_debut.isoformat() if r.date_debut else None,
             "date_fin": r.date_fin.isoformat() if r.date_fin else None}
            for r in rows]

class RenouvelerSchema(BaseModel):
    entreprise_id: str
    plan: str
    duree_mois: int = 1

@router.post("/renouveler")
def renouveler(data: RenouvelerSchema, db: Session = Depends(get_db)):
    if data.plan not in PRIX:
        raise HTTPException(status_code=400, detail="Plan invalide")
    prix = PRIX[data.plan] * data.duree_mois
    date_fin = datetime.now() + timedelta(days=30 * data.duree_mois)
    db.execute(text("""
        UPDATE abonnements SET statut = 'expire'
        WHERE entreprise_id = :eid AND statut = 'actif'
    """), {"eid": data.entreprise_id})
    db.execute(text("""
        INSERT INTO abonnements (entreprise_id, plan, date_debut, date_fin, statut, prix)
        VALUES (:eid, :plan, NOW(), :df, 'actif', :prix)
    """), {"eid": data.entreprise_id, "plan": data.plan, "df": date_fin, "prix": prix})
    db.commit()
    return {"success": True, "plan": data.plan,
            "date_fin": date_fin.strftime('%d/%m/%Y'),
            "message": f"Abonnement {data.plan} activé jusqu'au {date_fin.strftime('%d/%m/%Y')}"}
