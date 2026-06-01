from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel, Field
from typing import Optional
import uuid

router = APIRouter(
    prefix="/employes",
    tags=["Employés"]
)

# ==========================================
# SCHEMA VALIDATION
# ==========================================
class EmployeSchema(BaseModel):
    ferme_id: str

    nom: str = Field(
        min_length=2,
        max_length=100
    )

    role: str = Field(
        min_length=2,
        max_length=50
    )

    telephone: str = Field(
        min_length=8,
        max_length=20
    )

    salaire: float = Field(
        gt=0
    )


# ==========================================
# LISTE EMPLOYÉS
# ==========================================
@router.get("/")
def get_employes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):

    result = db.execute(text("""
        SELECT
            e.id,
            e.nom,
            e.role,
            e.telephone,
            e.salaire,
            e.ferme_id
        FROM employes e
        JOIN fermes f
            ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY e.nom ASC
    """), {
        "eid": current_user.entreprise_id
    })

    employes = [dict(row._mapping) for row in result]

    return {
        "total": len(employes),
        "items": employes
    }


# ==========================================
# CRÉER EMPLOYÉ
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_employe(
    data: EmployeSchema,
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

    # Vérifier doublon téléphone
    existing_phone = db.execute(text("""
        SELECT id
        FROM employes
        WHERE telephone = :tel
        LIMIT 1
    """), {
        "tel": data.telephone
    }).fetchone()

    if existing_phone:
        raise HTTPException(
            status_code=400,
            detail="Téléphone déjà utilisé"
        )

    emp_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO employes (
            id,
            ferme_id,
            nom,
            role,
            telephone,
            salaire
        )
        VALUES (
            :id,
            :fid,
            :nom,
            :role,
            :tel,
            :sal
        )
    """), {
        "id": emp_id,
        "fid": data.ferme_id,
        "nom": data.nom.strip(),
        "role": data.role.strip(),
        "tel": data.telephone.strip(),
        "sal": data.salaire
    })

    db.commit()

    return {
        "success": True,
        "message": "Employé créé avec succès",
        "id": emp_id
    }


# ==========================================
# MODIFIER EMPLOYÉ
# ==========================================
@router.put("/{employe_id}")
def update_employe(
    employe_id: str,
    data: EmployeSchema,
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

    result = db.execute(text("""
        UPDATE employes
        SET
            nom = :nom,
            role = :role,
            telephone = :tel,
            salaire = :sal
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "nom": data.nom.strip(),
        "role": data.role.strip(),
        "tel": data.telephone.strip(),
        "sal": data.salaire,
        "id": employe_id,
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Employé introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Employé mis à jour avec succès"
    }


# ==========================================
# SUPPRIMER EMPLOYÉ
# ==========================================
@router.delete("/{employe_id}")
def delete_employe(
    employe_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "proprietaire")
    )
):

    result = db.execute(text("""
        DELETE FROM employes
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": employe_id,
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Employé introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Employé supprimé avec succès"
    }