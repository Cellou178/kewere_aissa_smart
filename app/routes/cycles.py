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
    prefix="/cycles",
    tags=["Cycles"]
)

# ==========================================
# SCHEMA VALIDATION
# ==========================================
class CycleSchema(BaseModel):

    ferme_id: str

    type_cycle: str = Field(
        min_length=2,
        max_length=50
    )

    date_debut: str

    date_fin: Optional[str] = None

    statut: Optional[str] = "actif"

    nom: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=100
    )

    nombre_sujets: Optional[int] = Field(
        default=0,
        ge=0
    )

    batiment: Optional[str] = Field(
        default=None,
        max_length=100
    )

    souche: Optional[str] = Field(
        default=None,
        max_length=100
    )


# ==========================================
# LISTE CYCLES
# ==========================================
@router.get("/")
def get_cycles(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):

    # ADMIN = voit tout
    if current_user.role.nom == "admin":

        result = db.execute(text("""
            SELECT *
            FROM cycles
            ORDER BY date_debut DESC
        """))

    # AUTRES = seulement entreprise
    else:

        result = db.execute(text("""
            SELECT c.*
            FROM cycles c
            JOIN fermes f
                ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
            ORDER BY c.date_debut DESC
        """), {
            "eid": current_user.entreprise_id
        })

    cycles = [dict(row._mapping) for row in result]

    return {
        "total": len(cycles),
        "items": cycles
    }


# ==========================================
# CRÉER CYCLE
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_cycle(
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager", "proprietaire")
    )
):

    # Vérifier accès ferme
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

    cycle_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO cycles (
            id,
            ferme_id,
            type_cycle,
            date_debut,
            date_fin,
            statut,
            nom,
            nombre_sujets,
            batiment,
            souche
        )
        VALUES (
            :id,
            :fid,
            :type,
            :debut,
            :fin,
            :statut,
            :nom,
            :sujets,
            :bat,
            :souche
        )
    """), {
        "id": cycle_id,
        "fid": data.ferme_id,
        "type": data.type_cycle.strip(),
        "debut": data.date_debut,
        "fin": data.date_fin,
        "statut": data.statut,
        "nom": data.nom.strip() if data.nom else None,
        "sujets": data.nombre_sujets,
        "bat": data.batiment.strip() if data.batiment else None,
        "souche": data.souche.strip() if data.souche else None
    })

    db.commit()

    return {
        "success": True,
        "message": "Cycle créé avec succès",
        "id": cycle_id
    }


# ==========================================
# MODIFIER CYCLE
# ==========================================
@router.put("/{cycle_id}")
def update_cycle(
    cycle_id: UUID,
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager", "proprietaire")
    )
):

    result = db.execute(text("""
        UPDATE cycles
        SET
            type_cycle = :type,
            date_debut = :debut,
            date_fin = :fin,
            statut = :statut,
            nom = :nom,
            nombre_sujets = :sujets,
            batiment = :bat,
            souche = :souche
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "type": data.type_cycle.strip(),
        "debut": data.date_debut,
        "fin": data.date_fin,
        "statut": data.statut,
        "nom": data.nom.strip() if data.nom else None,
        "sujets": data.nombre_sujets,
        "bat": data.batiment.strip() if data.batiment else None,
        "souche": data.souche.strip() if data.souche else None,
        "id": str(cycle_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Cycle introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Cycle mis à jour avec succès"
    }


# ==========================================
# SUPPRIMER CYCLE
# ==========================================
@router.delete("/{cycle_id}")
def delete_cycle(
    cycle_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    result = db.execute(text("""
        DELETE FROM cycles
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": str(cycle_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Cycle introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Cycle supprimé avec succès"
    }