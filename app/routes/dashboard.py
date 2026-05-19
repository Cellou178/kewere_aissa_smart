from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

# ========== TABLEAU DE BORD FERMES ==========
@router.get("/fermes")
def get_dashboard_fermes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT * FROM vue_tableau_bord_fermes
        WHERE entreprise = (
            SELECT nom FROM entreprises WHERE id = :eid
        )
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== ABONNEMENTS & PAIEMENTS ==========
@router.get("/abonnements")
def get_dashboard_abonnements(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT * FROM vue_abonnements_paiements
        WHERE entreprise_id = :eid
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== ALERTES RECENTES ==========
@router.get("/alertes")
def get_alertes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT a.* FROM alertes a
        JOIN fermes f ON f.id = a.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY a.date_creation DESC
        LIMIT 20
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== STATISTIQUES GENERALES ==========
@router.get("/stats")
def get_stats(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    fermes = db.execute(text(
        "SELECT COUNT(*) as total FROM fermes WHERE entreprise_id = :eid"
    ), {"eid": current_user.entreprise_id}).fetchone()

    employes = db.execute(text("""
        SELECT COUNT(*) as total FROM employes e
        JOIN fermes f ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
    """), {"eid": current_user.entreprise_id}).fetchone()

    cycles = db.execute(text("""
        SELECT COUNT(*) as total FROM cycles c
        JOIN fermes f ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid AND c.statut = 'actif'
    """), {"eid": current_user.entreprise_id}).fetchone()

    alertes = db.execute(text("""
        SELECT COUNT(*) as total FROM alertes a
        JOIN fermes f ON f.id = a.ferme_id
        WHERE f.entreprise_id = :eid AND a.niveau = 'critique'
        AND a.date_creation >= NOW() - INTERVAL '7 days'
    """), {"eid": current_user.entreprise_id}).fetchone()

    return {
        "total_fermes": fermes.total,
        "total_employes": employes.total,
        "cycles_actifs": cycles.total,
        "alertes_critiques_7j": alertes.total
    }