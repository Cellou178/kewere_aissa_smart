from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from pydantic import BaseModel, Field
import uuid

router = APIRouter(prefix="/postes", tags=["Postes"])

POSTES_DEFAUT = [
    {"id": "employe",     "nom": "Employé",      "est_defaut": True},
    {"id": "manager",     "nom": "Manager",       "est_defaut": True},
    {"id": "veterinaire", "nom": "Vétérinaire",   "est_defaut": True},
    {"id": "chauffeur",   "nom": "Chauffeur",     "est_defaut": True},
    {"id": "gardien",     "nom": "Gardien",       "est_defaut": True},
    {"id": "comptable",   "nom": "Comptable",     "est_defaut": True},
]

class PosteSchema(BaseModel):
    nom: str = Field(min_length=2, max_length=50)

@router.get("/")
def liste_postes(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT id, nom FROM postes_personnalises
        WHERE entreprise_id = :eid ORDER BY nom
    """), {"eid": current_user.entreprise_id}).fetchall()

    custom = [{"id": str(r.id), "nom": r.nom, "est_defaut": False} for r in rows]
    return POSTES_DEFAUT + custom

@router.post("/", status_code=201)
def creer_poste(data: PosteSchema, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    # Vérifier doublon
    existing = db.execute(text("""
        SELECT id FROM postes_personnalises
        WHERE entreprise_id = :eid AND LOWER(nom) = LOWER(:nom) LIMIT 1
    """), {"eid": current_user.entreprise_id, "nom": data.nom}).fetchone()

    if existing:
        raise HTTPException(status_code=400, detail="Ce poste existe déjà")

    poste_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO postes_personnalises (id, entreprise_id, nom)
        VALUES (:id, :eid, :nom)
    """), {"id": poste_id, "eid": current_user.entreprise_id, "nom": data.nom.strip()})
    db.commit()

    return {"success": True, "id": poste_id, "nom": data.nom.strip(), "est_defaut": False}

@router.delete("/{poste_id}")
def supprimer_poste(poste_id: str, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    result = db.execute(text("""
        DELETE FROM postes_personnalises
        WHERE id = :id AND entreprise_id = :eid
    """), {"id": poste_id, "eid": current_user.entreprise_id})
    db.commit()

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Poste introuvable ou accès refusé")

    return {"success": True, "message": "Poste supprimé"}
