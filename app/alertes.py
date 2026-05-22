from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel, Field
from uuid import UUID
import uuid

router = APIRouter(
    prefix="/alertes",
    tags=["Alertes"]
)

# ==========================================
# SCHEMA
# ==========================================
class AlerteSchema(BaseModel):

    ferme_id: str

    titre: str = Field(
        min_length=2,
        max_length=100
    )

    message: str = Field(
        min_length=2,
        max_length=500
    )

    niveau: str = Field(
        min_length=2,
        max_length=20
    )
    # info / warning / critique


# ==========================================
# LISTE ALERTES
# ==========================================
@router.get("/")
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
# CRÉER ALERTE
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_alerte(
    data: AlerteSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    # Vérifier ferme entreprise
    ferme = db.execute(text("""
        SELECT id
        FROM fermes
        WHERE id = :fid
        AND entreprise_id = :eid
    """), {
        "fid": data.ferme_id,
        "eid": current_user.entreprise_id
    }).fetchone()

    if not ferme:

        raise HTTPException(
            status_code=403,
            detail="Accès interdit à cette ferme"
        )

    alerte_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO alertes (
            id,
            ferme_id,
            titre,
            message,
            niveau
        )
        VALUES (
            :id,
            :fid,
            :titre,
            :message,
            :niveau
        )
    """), {
        "id": alerte_id,
        "fid": data.ferme_id,
        "titre": data.titre.strip(),
        "message": data.message.strip(),
        "niveau": data.niveau.strip().lower()
    })

    db.commit()

    return {
        "success": True,
        "message": "Alerte créée avec succès",
        "id": alerte_id
    }


# ==========================================
# SUPPRIMER ALERTE
# ==========================================
@router.delete("/{alerte_id}")
def delete_alerte(
    alerte_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin")
    )
):

    result = db.execute(text("""
        DELETE FROM alertes
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": str(alerte_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Alerte introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Alerte supprimée"
    }


# ==========================================
# ALERTES AUTOMATIQUES
# ==========================================
@router.post("/scan")
def scan_alertes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    # TEMPÉRATURE ÉLEVÉE
    temp_rows = db.execute(text("""
        SELECT dj.*, c.ferme_id
        FROM donnees_journalieres dj
        JOIN cycles c
            ON c.id = dj.cycle_id
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
        AND dj.temperature > 35
    """), {
        "eid": current_user.entreprise_id
    }).fetchall()

    created = 0

    for row in temp_rows:

        db.execute(text("""
            INSERT INTO alertes (
                id,
                ferme_id,
                titre,
                message,
                niveau
            )
            VALUES (
                :id,
                :fid,
                :titre,
                :message,
                :niveau
            )
        """), {
            "id": str(uuid.uuid4()),
            "fid": row.ferme_id,
            "titre": "Température critique",
            "message":
                f"Température élevée détectée : {row.temperature}°C",
            "niveau": "critique"
        })

        created += 1

    # MORTALITÉ ÉLEVÉE
    mort_rows = db.execute(text("""
        SELECT dj.*, c.ferme_id
        FROM donnees_journalieres dj
        JOIN cycles c
            ON c.id = dj.cycle_id
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
        AND dj.mortalite >= 10
    """), {
        "eid": current_user.entreprise_id
    }).fetchall()

    for row in mort_rows:

        db.execute(text("""
            INSERT INTO alertes (
                id,
                ferme_id,
                titre,
                message,
                niveau
            )
            VALUES (
                :id,
                :fid,
                :titre,
                :message,
                :niveau
            )
        """), {
            "id": str(uuid.uuid4()),
            "fid": row.ferme_id,
            "titre": "Mortalité élevée",
            "message":
                f"Mortalité élevée détectée : {row.mortalite}",
            "niveau": "critique"
        })

        created += 1

    # STOCK FAIBLE
    stock_rows = db.execute(text("""
        SELECT *
        FROM stocks s
        JOIN fermes f
            ON f.id = s.ferme_id
        WHERE f.entreprise_id = :eid
        AND s.quantite <= s.seuil_alerte
    """), {
        "eid": current_user.entreprise_id
    }).fetchall()

    for row in stock_rows:

        db.execute(text("""
            INSERT INTO alertes (
                id,
                ferme_id,
                titre,
                message,
                niveau
            )
            VALUES (
                :id,
                :fid,
                :titre,
                :message,
                :niveau
            )
        """), {
            "id": str(uuid.uuid4()),
            "fid": row.ferme_id,
            "titre": "Stock faible",
            "message":
                f"Stock faible pour : {row.produit}",
            "niveau": "warning"
        })

        created += 1

    db.commit()

    return {
        "success": True,
        "alertes_creees": created
    }