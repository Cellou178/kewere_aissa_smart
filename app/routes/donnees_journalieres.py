from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
import uuid

router = APIRouter(
    prefix="/donnees",
    tags=["Données Journalières"]
)

# ==========================================
# SCHEMA VALIDATION
# ==========================================
class DonneeSchema(BaseModel):

    cycle_id: str

    date_releve: str

    temperature: float = Field(
        ge=-10,
        le=60
    )

    humidite: float = Field(
        ge=0,
        le=100
    )

    production: float = Field(
        ge=0
    )

    mortalite: int = Field(
        ge=0
    )


# ==========================================
# LISTE DONNÉES
# ==========================================
@router.get("/")
def get_donnees(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT dj.*
        FROM donnees_journalieres dj
        JOIN cycles c
            ON c.id = dj.cycle_id
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY dj.date_releve DESC
    """), {
        "eid": current_user.entreprise_id
    })

    donnees = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(donnees),
        "items": donnees
    }


# ==========================================
# CRÉER DONNÉE
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_donnee(
    data: DonneeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    # Vérifier cycle appartient entreprise
    cycle = db.execute(text("""
        SELECT c.id
        FROM cycles c
        JOIN fermes f
            ON f.id = c.ferme_id
        WHERE c.id = :cid
        AND f.entreprise_id = :eid
    """), {
        "cid": data.cycle_id,
        "eid": current_user.entreprise_id
    }).fetchone()

    if not cycle:

        raise HTTPException(
            status_code=403,
            detail="Cycle interdit"
        )

    donnee_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO donnees_journalieres (
            id,
            cycle_id,
            date_releve,
            temperature,
            humidite,
            production,
            mortalite
        )
        VALUES (
            :id,
            :cid,
            :date,
            :temp,
            :hum,
            :prod,
            :mort
        )
    """), {
        "id": donnee_id,
        "cid": data.cycle_id,
        "date": data.date_releve,
        "temp": data.temperature,
        "hum": data.humidite,
        "prod": data.production,
        "mort": data.mortalite
    })

    db.commit()

    return {
        "success": True,
        "message": "Données enregistrées avec succès",
        "id": donnee_id
    }


# ==========================================
# MODIFIER DONNÉE
# ==========================================
@router.put("/{donnee_id}")
def update_donnee(
    donnee_id: UUID,
    data: DonneeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    result = db.execute(text("""
        UPDATE donnees_journalieres
        SET
            date_releve = :date,
            temperature = :temp,
            humidite = :hum,
            production = :prod,
            mortalite = :mort
        WHERE id = :id
        AND cycle_id IN (
            SELECT c.id
            FROM cycles c
            JOIN fermes f
                ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        )
    """), {
        "date": data.date_releve,
        "temp": data.temperature,
        "hum": data.humidite,
        "prod": data.production,
        "mort": data.mortalite,
        "id": str(donnee_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Donnée introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Données mises à jour avec succès"
    }


# ==========================================
# SUPPRIMER DONNÉE
# ==========================================
@router.delete("/{donnee_id}")
def delete_donnee(
    donnee_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin")
    )
):

    result = db.execute(text("""
        DELETE FROM donnees_journalieres
        WHERE id = :id
        AND cycle_id IN (
            SELECT c.id
            FROM cycles c
            JOIN fermes f
                ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        )
    """), {
        "id": str(donnee_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Donnée introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Données supprimées avec succès"
    }