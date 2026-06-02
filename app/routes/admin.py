from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.email_service import envoyer_email
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/admin", tags=["Super Admin"])

def _check_admin(current_user):
    if current_user.role.nom.lower() != 'admin':
        raise HTTPException(status_code=403, detail="Accès super admin requis")

@router.get("/stats")
def stats_globales(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    r = db.execute(text("""
        SELECT
            (SELECT COUNT(*) FROM entreprises) as nb_entreprises,
            (SELECT COUNT(*) FROM utilisateurs WHERE actif = true) as nb_utilisateurs,
            (SELECT COUNT(*) FROM fermes) as nb_fermes,
            (SELECT COUNT(*) FROM cycles WHERE statut = 'actif') as nb_cycles_actifs,
            (SELECT COUNT(*) FROM cycles) as nb_cycles_total,
            (SELECT COUNT(*) FROM employes) as nb_employes,
            (SELECT COALESCE(SUM(prix), 0) FROM abonnements WHERE statut = 'actif') as revenu_total,
            (SELECT COUNT(*) FROM abonnements WHERE plan = 'pro' AND statut = 'actif') as nb_pro,
            (SELECT COUNT(*) FROM abonnements WHERE plan = 'enterprise' AND statut = 'actif') as nb_enterprise,
            (SELECT COUNT(*) FROM abonnements WHERE statut = 'expire') as nb_expires
    """)).fetchone()
    return {
        "nb_entreprises": r.nb_entreprises,
        "nb_utilisateurs": r.nb_utilisateurs,
        "nb_fermes": r.nb_fermes,
        "nb_cycles_actifs": r.nb_cycles_actifs,
        "nb_cycles_total": r.nb_cycles_total,
        "nb_employes": r.nb_employes,
        "revenu_total": float(r.revenu_total or 0),
        "abonnements": {
            "pro": r.nb_pro,
            "enterprise": r.nb_enterprise,
            "expires": r.nb_expires,
        }
    }

@router.get("/entreprises")
def liste_entreprises(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    rows = db.execute(text("""
        SELECT
            e.id, e.nom, e.email, e.telephone, e.pays, e.date_creation,
            COALESCE(a.plan, 'gratuit') as plan,
            COALESCE(a.statut, 'actif') as statut_abo,
            a.date_fin,
            (SELECT COUNT(*) FROM fermes f WHERE f.entreprise_id = e.id) as nb_fermes,
            (SELECT COUNT(*) FROM utilisateurs u WHERE u.entreprise_id = e.id AND u.actif = true) as nb_users,
            (SELECT COUNT(*) FROM cycles c JOIN fermes f2 ON c.ferme_id = f2.id
             WHERE f2.entreprise_id = e.id AND c.statut = 'actif') as nb_cycles_actifs,
            (SELECT MAX(dj.date_releve) FROM donnees_journalieres dj
             JOIN cycles c2 ON dj.cycle_id = c2.id
             JOIN fermes f3 ON c2.ferme_id = f3.id
             WHERE f3.entreprise_id = e.id) as derniere_activite
        FROM entreprises e
        LEFT JOIN abonnements a ON a.entreprise_id = e.id
            AND a.created_at = (SELECT MAX(a2.created_at) FROM abonnements a2 WHERE a2.entreprise_id = e.id)
        ORDER BY e.date_creation DESC
    """)).fetchall()
    return [{
        "id": str(r.id), "nom": r.nom, "email": r.email,
        "telephone": r.telephone, "pays": r.pays,
        "date_creation": r.date_creation.isoformat() if r.date_creation else None,
        "plan": r.plan, "statut_abo": r.statut_abo,
        "date_fin_abo": r.date_fin.isoformat() if r.date_fin else None,
        "nb_fermes": r.nb_fermes or 0,
        "nb_users": r.nb_users or 0,
        "nb_cycles_actifs": r.nb_cycles_actifs or 0,
        "derniere_activite": r.derniere_activite.isoformat() if r.derniere_activite else None,
    } for r in rows]

class SanctionSchema(BaseModel):
    motif: str
    message_custom: Optional[str] = None  # remplace le message par défaut si fourni

class ParametreSchema(BaseModel):
    valeur: str


def _get_parametre(cle: str, db: Session, defaut: str = "") -> str:
    row = db.execute(text("SELECT valeur FROM parametres WHERE cle = :cle"), {"cle": cle}).fetchone()
    return row.valeur if row else defaut


def _envoyer_email_sanction(destinataire: str, nom: str, titre: str, corps: str, motif: str):
    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;background:#f8fafc;padding:20px;border-radius:12px">
      <div style="background:linear-gradient(135deg,#7F1D1D,#1B3A6B);padding:20px;border-radius:10px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px">⚠️ {titre}</h1>
        <p style="color:rgba(255,255,255,0.8);margin:5px 0 0">Kewere Aissa Smart</p>
      </div>
      <div style="background:white;padding:24px;border-radius:10px;margin-top:12px">
        <p style="color:#475569">Bonjour <strong>{nom}</strong>,</p>
        <p style="color:#475569">{corps}</p>
        <div style="background:#fef2f2;border-left:4px solid #DC2626;padding:12px;border-radius:6px;margin:16px 0">
          <p style="margin:0;color:#DC2626;font-weight:700">Motif : {motif}</p>
        </div>
        <p style="color:#94a3b8;font-size:13px">Pour toute question, contactez-nous à support@kewere.sn</p>
      </div>
    </div>
    """
    envoyer_email(destinataire, f"⚠️ {titre} - Kewere Aissa Smart", html)


@router.get("/parametres")
def get_parametres(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    rows = db.execute(text("SELECT cle, valeur, description FROM parametres ORDER BY cle")).fetchall()
    return [{"cle": r.cle, "valeur": r.valeur, "description": r.description} for r in rows]


@router.put("/parametres/{cle}")
def update_parametre(cle: str, data: ParametreSchema,
                     current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    db.execute(text("""
        INSERT INTO parametres (cle, valeur) VALUES (:cle, :val)
        ON CONFLICT (cle) DO UPDATE SET valeur = :val, updated_at = NOW()
    """), {"cle": cle, "val": data.valeur})
    db.commit()
    return {"success": True, "message": f"Paramètre '{cle}' mis à jour"}


@router.post("/entreprises/{eid}/suspendre")
def suspendre_entreprise(eid: str, data: SanctionSchema, background_tasks: BackgroundTasks,
                         current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    entreprise = db.execute(text("""
        SELECT nom, email FROM entreprises WHERE id = :id
    """), {"id": eid}).fetchone()
    if not entreprise:
        raise HTTPException(status_code=404, detail="Entreprise introuvable")

    db.execute(text("""
        UPDATE entreprises SET statut = 'suspendu', motif_sanction = :motif, date_sanction = NOW()
        WHERE id = :id
    """), {"id": eid, "motif": data.motif})
    db.commit()

    titre = _get_parametre("msg_suspension_titre", db, "Compte Suspendu")
    corps = data.message_custom or _get_parametre(
        "msg_suspension_corps", db,
        "Votre compte a été temporairement suspendu. Contactez le support."
    )
    background_tasks.add_task(_envoyer_email_sanction, entreprise.email, entreprise.nom, titre, corps, data.motif)

    return {"success": True, "message": f"Entreprise '{entreprise.nom}' suspendue"}


@router.post("/entreprises/{eid}/resilier")
def resilier_entreprise(eid: str, data: SanctionSchema, background_tasks: BackgroundTasks,
                        current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    entreprise = db.execute(text("""
        SELECT nom, email FROM entreprises WHERE id = :id
    """), {"id": eid}).fetchone()
    if not entreprise:
        raise HTTPException(status_code=404, detail="Entreprise introuvable")

    db.execute(text("""
        UPDATE entreprises SET statut = 'resilie', motif_sanction = :motif, date_sanction = NOW()
        WHERE id = :id
    """), {"id": eid, "motif": data.motif})
    db.execute(text("""
        UPDATE abonnements SET statut = 'expire' WHERE entreprise_id = :id AND statut = 'actif'
    """), {"id": eid})
    db.commit()

    titre = _get_parametre("msg_resiliation_titre", db, "Compte Résilié")
    corps = data.message_custom or _get_parametre(
        "msg_resiliation_corps", db,
        "Votre compte a été résilié suite au non-respect de nos conditions d'utilisation."
    )
    background_tasks.add_task(_envoyer_email_sanction, entreprise.email, entreprise.nom, titre, corps, data.motif)

    return {"success": True, "message": f"Entreprise '{entreprise.nom}' résiliée"}


@router.post("/entreprises/{eid}/reactiver")
def reactiver_entreprise(eid: str, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    db.execute(text("""
        UPDATE entreprises SET statut = 'actif', motif_sanction = NULL, date_sanction = NULL
        WHERE id = :id
    """), {"id": eid})
    db.commit()
    return {"success": True, "message": "Entreprise réactivée"}


@router.get("/entreprises/{eid}")
def detail_entreprise(eid: str, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    _check_admin(current_user)
    e = db.execute(text("SELECT * FROM entreprises WHERE id = :id"), {"id": eid}).fetchone()
    if not e:
        raise HTTPException(status_code=404, detail="Entreprise introuvable")

    fermes = db.execute(text("""
        SELECT f.id, f.nom, f.localisation,
               (SELECT COUNT(*) FROM cycles c WHERE c.ferme_id = f.id AND c.statut = 'actif') as cycles_actifs,
               (SELECT COUNT(*) FROM cycles c2 WHERE c2.ferme_id = f.id) as cycles_total,
               (SELECT COUNT(*) FROM employes emp WHERE emp.ferme_id = f.id) as nb_employes
        FROM fermes f WHERE f.entreprise_id = :eid ORDER BY f.nom
    """), {"eid": eid}).fetchall()

    utilisateurs = db.execute(text("""
        SELECT u.nom, u.email, u.telephone, r.nom as role, u.actif, u.date_creation
        FROM utilisateurs u JOIN roles r ON u.role_id = r.id
        WHERE u.entreprise_id = :eid ORDER BY u.date_creation
    """), {"eid": eid}).fetchall()

    cycles = db.execute(text("""
        SELECT c.id, c.nom, c.type_cycle, c.statut, c.date_debut, c.date_fin,
               c.nombre_sujets, f.nom as ferme_nom,
               (SELECT COUNT(*) FROM donnees_journalieres dj WHERE dj.cycle_id = c.id) as nb_saisies,
               (SELECT poids_moyen_global FROM donnees_journalieres dj2
                WHERE dj2.cycle_id = c.id ORDER BY dj2.date_releve DESC LIMIT 1) as dernier_poids
        FROM cycles c JOIN fermes f ON c.ferme_id = f.id
        WHERE f.entreprise_id = :eid ORDER BY c.date_debut DESC LIMIT 20
    """), {"eid": eid}).fetchall()

    abonnements = db.execute(text("""
        SELECT plan, statut, date_debut, date_fin, prix
        FROM abonnements WHERE entreprise_id = :eid
        ORDER BY created_at DESC LIMIT 5
    """), {"eid": eid}).fetchall()

    return {
        "entreprise": {
            "id": str(e.id), "nom": e.nom, "email": e.email,
            "telephone": e.telephone, "pays": e.pays,
            "date_creation": e.date_creation.isoformat() if e.date_creation else None,
        },
        "fermes": [{"id": str(f.id), "nom": f.nom, "localisation": f.localisation,
                    "cycles_actifs": f.cycles_actifs, "cycles_total": f.cycles_total,
                    "nb_employes": f.nb_employes} for f in fermes],
        "utilisateurs": [{"nom": u.nom, "email": u.email, "role": u.role,
                          "actif": u.actif} for u in utilisateurs],
        "cycles": [{"id": str(c.id), "nom": c.nom, "type": c.type_cycle,
                    "statut": c.statut, "ferme": c.ferme_nom,
                    "nombre_sujets": c.nombre_sujets, "nb_saisies": c.nb_saisies or 0,
                    "dernier_poids": float(c.dernier_poids) if c.dernier_poids else None,
                    "date_debut": c.date_debut.isoformat() if c.date_debut else None}
                   for c in cycles],
        "abonnements": [{"plan": a.plan, "statut": a.statut, "prix": a.prix,
                         "date_debut": a.date_debut.isoformat() if a.date_debut else None,
                         "date_fin": a.date_fin.isoformat() if a.date_fin else None}
                        for a in abonnements],
    }
