from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
from sqlalchemy import text
import uuid

router = APIRouter(prefix="/fermes", tags=["Fermes"])

class FermeSchema(BaseModel):
    nom: str
    localisation: str
    superficie: float

# ========== LISTE DES FERMES ==========
@router.get("/")
def get_fermes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text(
        "SELECT * FROM fermes WHERE entreprise_id = :eid"
    ), {"eid": current_user.entreprise_id})
    fermes = [dict(row._mapping) for row in result]
    return fermes

# ========== CRÉER UNE FERME ==========
@router.post("/", status_code=201)
def create_ferme(
    data: FermeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    ferme_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO fermes (id, entreprise_id, nom, localisation, superficie)
        VALUES (:id, :eid, :nom, :loc, :sup)
    """), {
        "id": ferme_id,
        "eid": current_user.entreprise_id,
        "nom": data.nom,
        "loc": data.localisation,
        "sup": data.superficie
    })
    db.commit()
    return {"message": "Ferme créée avec succès", "id": str(ferme_id)}

# ========== MODIFIER UNE FERME ==========
@router.put("/{ferme_id}")
def update_ferme(
    ferme_id: str,
    data: FermeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    db.execute(text("""
        UPDATE fermes SET nom=:nom, localisation=:loc, superficie=:sup
        WHERE id=:id AND entreprise_id=:eid
    """), {
        "nom": data.nom, "loc": data.localisation,
        "sup": data.superficie, "id": ferme_id,
        "eid": current_user.entreprise_id
    })
    db.commit()
    return {"message": "Ferme mise à jour"}

# ========== SUPPRIMER UNE FERME ==========
@router.delete("/{ferme_id}")
def delete_ferme(
    ferme_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin"))
):
    db.execute(text(
        "DELETE FROM fermes WHERE id=:id AND entreprise_id=:eid"
    ), {"id": ferme_id, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Ferme supprimée"}