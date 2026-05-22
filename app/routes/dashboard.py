from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)

# ==========================================
# DASHBOARD FERMES
# ==========================================
@router.get("/fermes")
def get_dashboard_fermes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT *
        FROM vue_tableau_bord_fermes
        WHERE entreprise = (
            SELECT nom
            FROM entreprises
            WHERE id = :eid
        )
        ORDER BY ferme
    """), {
        "eid": current_user.entreprise_id
    })

    data = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(data),
        "items": data
    }


# ==========================================
# ABONNEMENTS
# ==========================================
@router.get("/abonnements")
def get_dashboard_abonnements(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT *
        FROM vue_abonnements_paiements
        WHERE entreprise_id = :eid
        ORDER BY date_paiement DESC
    """), {
        "eid": current_user.entreprise_id
    })

    abonnements = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(abonnements),
        "items": abonnements
    }


# ==========================================
# ALERTES
# ==========================================
@router.get("/alertes")
def get_alertes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT a.*
        FROM alertes a
        JOIN fermes f
            ON f.id = a.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY a.date_creation DESC
        LIMIT 20
    """), {
        "eid": current_user.entreprise_id
    })

    alertes = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(alertes),
        "items": alertes
    }


# ==========================================
# STATISTIQUES GLOBALES
# ==========================================
@router.get("/stats")
def get_stats(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    # FERMES
    fermes = db.execute(text("""
        SELECT COUNT(*) as total
        FROM fermes
        WHERE entreprise_id = :eid
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # EMPLOYÉS
    employes = db.execute(text("""
        SELECT COUNT(*) as total
        FROM employes e
        JOIN fermes f
            ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # CYCLES ACTIFS
    cycles = db.execute(text("""
        SELECT COUNT(*) as total
        FROM cycles c
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
        AND c.statut = 'actif'
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # ALERTES CRITIQUES
    alertes = db.execute(text("""
        SELECT COUNT(*) as total
        FROM alertes a
        JOIN fermes f
            ON f.id = a.ferme_id
        WHERE f.entreprise_id = :eid
        AND a.niveau = 'critique'
        AND a.date_creation >= NOW() - INTERVAL '7 days'
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # PRODUCTION TOTALE
    production = db.execute(text("""
        SELECT COALESCE(SUM(dj.production), 0) as total
        FROM donnees_journalieres dj
        JOIN cycles c
            ON c.id = dj.cycle_id
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # MORTALITÉ TOTALE
    mortalite = db.execute(text("""
        SELECT COALESCE(SUM(dj.mortalite), 0) as total
        FROM donnees_journalieres dj
        JOIN cycles c
            ON c.id = dj.cycle_id
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # REVENUS
    revenus = db.execute(text("""
        SELECT COALESCE(SUM(montant), 0) as total
        FROM finances fi
        JOIN fermes f
            ON f.id = fi.ferme_id
        WHERE f.entreprise_id = :eid
        AND fi.type_operation = 'revenu'
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    # DÉPENSES
    depenses = db.execute(text("""
        SELECT COALESCE(SUM(montant), 0) as total
        FROM finances fi
        JOIN fermes f
            ON f.id = fi.ferme_id
        WHERE f.entreprise_id = :eid
        AND fi.type_operation = 'depense'
    """), {
        "eid": current_user.entreprise_id
    }).fetchone()

    benefice = revenus.total - depenses.total

    return {

        "total_fermes":
            fermes.total,

        "total_employes":
            employes.total,

        "cycles_actifs":
            cycles.total,

        "alertes_critiques_7j":
            alertes.total,

        "production_totale":
            production.total,

        "mortalite_totale":
            mortalite.total,

        "revenus_totaux":
            revenus.total,

        "depenses_totales":
            depenses.total,

        "benefice_total":
            benefice
    }