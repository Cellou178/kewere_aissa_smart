from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/abonnements", tags=["Abonnements"])

def _get_plans(db: Session):
    rows = db.execute(text("SELECT * FROM plans WHERE actif = true ORDER BY prix_mensuel")).fetchall()
    return {r.id: {
        'nom': r.nom,
        'prix_mensuel': r.prix_mensuel,
        'prix_annuel': r.prix_annuel,
        'limites': {'fermes': r.max_fermes, 'cycles': r.max_cycles, 'utilisateurs': r.max_utilisateurs}
    } for r in rows}

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

@router.get("/plans")
def liste_plans(db: Session = Depends(get_db)):
    plans = _get_plans(db)
    return [{"id": k, **v} for k, v in plans.items()]

@router.get("/mon-abonnement")
def mon_abonnement(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    eid = str(current_user.entreprise_id)
    row = _get_or_create(eid, db)
    plans = _get_plans(db)
    limites = plans.get(row.plan, {}).get('limites', {'fermes': 1, 'cycles': 2, 'utilisateurs': 1})

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
        "limites": limites,
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
def renouveler(data: RenouvelerSchema, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    plans = _get_plans(db)
    if data.plan not in plans:
        raise HTTPException(status_code=400, detail="Plan invalide")
    prix = plans[data.plan]['prix_mensuel'] * data.duree_mois
    date_fin = None if data.plan == 'gratuit' else datetime.now() + timedelta(days=30 * data.duree_mois)
    db.execute(text("""
        UPDATE abonnements SET statut = 'expire'
        WHERE entreprise_id = :eid AND statut = 'actif'
    """), {"eid": data.entreprise_id})
    db.execute(text("""
        INSERT INTO abonnements (entreprise_id, plan, date_debut, date_fin, statut, prix)
        VALUES (:eid, :plan, NOW(), :df, 'actif', :prix)
    """), {"eid": data.entreprise_id, "plan": data.plan, "df": date_fin, "prix": prix})
    db.commit()
    msg = f"Plan {data.plan} activé" + (f" jusqu'au {date_fin.strftime('%d/%m/%Y')}" if date_fin else " (sans expiration)")
    return {"success": True, "plan": data.plan,
            "date_fin": date_fin.strftime('%d/%m/%Y') if date_fin else None,
            "message": msg}

@router.get("/tous")
def tous_abonnements(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role.nom.lower() != 'admin':
        raise HTTPException(status_code=403, detail="Accès admin requis")
    rows = db.execute(text("""
        SELECT e.id as entreprise_id, e.nom as entreprise_nom, e.email,
               a.plan, a.statut, a.date_debut, a.date_fin, a.prix,
               (SELECT COUNT(*) FROM utilisateurs u WHERE u.entreprise_id = e.id AND u.actif = true) as nb_users
        FROM entreprises e
        LEFT JOIN abonnements a ON a.entreprise_id = e.id
            AND a.created_at = (SELECT MAX(a2.created_at) FROM abonnements a2 WHERE a2.entreprise_id = e.id)
        ORDER BY e.nom
    """)).fetchall()
    return [{"entreprise_id": str(r.entreprise_id), "entreprise_nom": r.entreprise_nom,
             "email": r.email, "plan": r.plan or 'gratuit', "statut": r.statut or 'actif',
             "date_fin": r.date_fin.isoformat() if r.date_fin else None,
             "prix": r.prix or 0, "nb_users": r.nb_users or 0}
            for r in rows]

class UpdatePlanSchema(BaseModel):
    prix_mensuel: Optional[int] = None
    prix_annuel: Optional[int] = None
    max_fermes: Optional[int] = None
    max_cycles: Optional[int] = None
    max_utilisateurs: Optional[int] = None

@router.put("/plans/{plan_id}")
def modifier_plan(plan_id: str, data: UpdatePlanSchema,
                  current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role.nom.lower() != 'admin':
        raise HTTPException(status_code=403, detail="Accès admin requis")
    updates = {k: v for k, v in data.model_dump().items() if v is not None}
    if not updates:
        raise HTTPException(status_code=400, detail="Aucune donnée à modifier")
    set_clause = ', '.join([f"{k} = :{k}" for k in updates])
    updates['plan_id'] = plan_id
    db.execute(text(f"UPDATE plans SET {set_clause} WHERE id = :plan_id"), updates)
    db.commit()
    return {"success": True, "message": f"Plan {plan_id} mis à jour"}
