from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/donnees", tags=["Données Journalières"])

class DonneeSchema(BaseModel):
    cycle_id: str
    date_releve: str
    temperature: float
    humidite: float
    production: float
    mortalite: int

@router.get("/")
def get_donnees(db: Session = Depends(get_db), current_user: Utilisateur = Depends(get_current_user)):
    result = db.execute(text("""
        SELECT dj.* FROM donnees_journalieres dj
        JOIN cycles c ON c.id = dj.cycle_id
        JOIN fermes f ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY dj.date_releve DESC
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

@router.post("/", status_code=201)
def create_donnee(data: DonneeSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager"))):
    donnee_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO donnees_journalieres
        (id, cycle_id, date_releve, temperature, humidite, production, mortalite)
        VALUES (:id, :cid, :date, :temp, :hum, :prod, :mort)
    """), {
        "id": donnee_id, "cid": data.cycle_id,
        "date": data.date_releve, "temp": data.temperature,
        "hum": data.humidite, "prod": data.production,
        "mort": data.mortalite
    })
    db.commit()
    return {"message": "Données enregistrées avec succès", "id": str(donnee_id)}

@router.put("/{donnee_id}")
def update_donnee(donnee_id: str, data: DonneeSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager"))):
    db.execute(text("""
        UPDATE donnees_journalieres
        SET date_releve=:date, temperature=:temp, humidite=:hum,
        production=:prod, mortalite=:mort
        WHERE id=:id
    """), {
        "date": data.date_releve, "temp": data.temperature,
        "hum": data.humidite, "prod": data.production,
        "mort": data.mortalite, "id": donnee_id
    })
    db.commit()
    return {"message": "Données mises à jour"}

@router.delete("/{donnee_id}")
def delete_donnee(donnee_id: str, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin"))):
    db.execute(text("DELETE FROM donnees_journalieres WHERE id=:id"), {"id": donnee_id})
    db.commit()
    return {"message": "Données supprimées"}