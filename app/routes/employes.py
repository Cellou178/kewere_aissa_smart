from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/employes", tags=["Employés"])

class EmployeSchema(BaseModel):
    ferme_id: str
    nom: str
    role: str
    telephone: str
    salaire: float

# ========== LISTE ==========
@router.get("/")
def get_employes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT e.* FROM employes e
        JOIN fermes f ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== CRÉER ==========
@router.post("/", status_code=201)
def create_employe(
    data: EmployeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    emp_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO employes (id, ferme_id, nom, role, telephone, salaire)
        VALUES (:id, :fid, :nom, :role, :tel, :sal)
    """), {
        "id": emp_id, "fid": data.ferme_id,
        "nom": data.nom, "role": data.role,
        "tel": data.telephone, "sal": data.salaire
    })
    db.commit()
    return {"message": "Employé créé avec succès", "id": str(emp_id)}

# ========== MODIFIER ==========
@router.put("/{employe_id}")
def update_employe(
    employe_id: str,
    data: EmployeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    db.execute(text("""
        UPDATE employes SET nom=:nom, role=:role, telephone=:tel, salaire=:sal
        WHERE id=:id
    """), {
        "nom": data.nom, "role": data.role,
        "tel": data.telephone, "sal": data.salaire,
        "id": employe_id
    })
    db.commit()
    return {"message": "Employé mis à jour"}

# ========== SUPPRIMER ==========
@router.delete("/{employe_id}")
def delete_employe(
    employe_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin"))
):
    db.execute(text("DELETE FROM employes WHERE id=:id"), {"id": employe_id})
    db.commit()
    return {"message": "Employé supprimé"}