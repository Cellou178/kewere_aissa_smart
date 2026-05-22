from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/cycles", tags=["Cycles"])

class CycleSchema(BaseModel):
    ferme_id: str
    type_cycle: str
    date_debut: str
    date_fin: Optional[str] = None
    statut: Optional[str] = "actif"
    nom: Optional[str] = None
    nombre_sujets: Optional[int] = None
    batiment: Optional[str] = None
    souche: Optional[str] = None

@router.get("/")
def get_cycles(db: Session = Depends(get_db), current_user: Utilisateur = Depends(get_current_user)):
    if current_user.role.nom == "admin":
        result = db.execute(text("SELECT c.* FROM cycles c"))
    else:
        result = db.execute(text("""
            SELECT c.* FROM cycles c
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

@router.post("/", status_code=201)
def create_cycle(data: CycleSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager", "proprietaire"))):
    cycle_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO cycles (id, ferme_id, type_cycle, date_debut, date_fin, statut, nom, nombre_sujets, batiment, souche)
        VALUES (:id, :fid, :type, :debut, :fin, :statut, :nom, :sujets, :bat, :souche)
    """), {"id": cycle_id, "fid": data.ferme_id, "type": data.type_cycle, "debut": data.date_debut, "fin": data.date_fin, "statut": data.statut, "nom": data.nom, "sujets": data.nombre_sujets, "bat": data.batiment, "souche": data.souche})
    db.commit()
    return {"message": "Cycle cree avec succes", "id": str(cycle_id)}

@router.put("/{cycle_id}")
def update_cycle(cycle_id: str, data: CycleSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager", "proprietaire"))):
    db.execute(text("""
        UPDATE cycles SET type_cycle=:type, date_debut=:debut,
        date_fin=:fin, statut=:statut, nom=:nom,
        nombre_sujets=:sujets, batiment=:bat, souche=:souche
        WHERE id=:id
    """), {"type": data.type_cycle, "debut": data.date_debut, "fin": data.date_fin, "statut": data.statut, "nom": data.nom, "sujets": data.nombre_sujets, "bat": data.batiment, "souche": data.souche, "id": cycle_id})
    db.commit()
    return {"message": "Cycle mis a jour"}

@router.delete("/{cycle_id}")
def delete_cycle(cycle_id: str, db: Session = Depends(get_db), current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("DELETE FROM cycles WHERE id = :id"), {"id": cycle_id})
    db.commit()
    return {"message": "Cycle supprime avec succes"}
@router.get("/cycles/")
def get_cycles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    cycles = db.query(Cycle).filter(
        Cycle.ferme_id == current_user.ferme_id
    ).all()

    return cycles