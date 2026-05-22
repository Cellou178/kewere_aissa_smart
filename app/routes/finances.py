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
    prefix="/finances",
    tags=["Finances"]
)

# ==========================================
# SCHEMA
# ==========================================
class FinanceSchema(BaseModel):

    ferme_id: str

    type_operation: str = Field(
        min_length=2,
        max_length=50
    )
    # depense / revenu

    description: str = Field(
        min_length=2,
        max_length=255
    )

    montant: float = Field(
        gt=0
    )

    date_operation: str


# ==========================================
# LISTE FINANCES
# ==========================================
@router.get("/")
def get_finances(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT fi.*
        FROM finances fi
        JOIN fermes f
            ON f.id = fi.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY fi.date_operation DESC
    """), {
        "eid": current_user.entreprise_id
    })

    finances = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(finances),
        "items": finances
    }


# ==========================================
# CRÉER OPÉRATION
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_finance(
    data: FinanceSchema,
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

    finance_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO finances (
            id,
            ferme_id,
            type_operation,
            description,
            montant,
            date_operation
        )
        VALUES (
            :id,
            :fid,
            :type,
            :desc,
            :montant,
            :date
        )
    """), {
        "id": finance_id,
        "fid": data.ferme_id,
        "type": data.type_operation.strip(),
        "desc": data.description.strip(),
        "montant": data.montant,
        "date": data.date_operation
    })

    db.commit()

    return {
        "success": True,
        "message": "Opération enregistrée",
        "id": finance_id
    }


# ==========================================
# MODIFIER OPÉRATION
# ==========================================
@router.put("/{finance_id}")
def update_finance(
    finance_id: UUID,
    data: FinanceSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    result = db.execute(text("""
        UPDATE finances
        SET
            type_operation = :type,
            description = :desc,
            montant = :montant,
            date_operation = :date
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "type": data.type_operation.strip(),
        "desc": data.description.strip(),
        "montant": data.montant,
        "date": data.date_operation,
        "id": str(finance_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Opération introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Opération mise à jour"
    }


# ==========================================
# SUPPRIMER OPÉRATION
# ==========================================
@router.delete("/{finance_id}")
def delete_finance(
    finance_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin")
    )
):

    result = db.execute(text("""
        DELETE FROM finances
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": str(finance_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Opération introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Opération supprimée"
    }