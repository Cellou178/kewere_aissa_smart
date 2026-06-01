from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user

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
