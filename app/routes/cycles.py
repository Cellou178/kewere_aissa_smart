from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/cycles", tags=["cycles"])

class CycleSchema(BaseModel):
    ferme_id: str
    type_cycle: Optional[str] = "chair"
    date_debut: Optional[str] = None
    date_fin: Optional[str] = None
    statut: Optional[str] = "actif"
    nom: Optional[str] = None
    nombre_sujets: Optional[int] = 0
    batiment: Optional[str] = None
    souche: Optional[str] = None

@router.get("/")
def get_cycles(
    ferme_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    if current_user.role.nom == "superadmin":
        # superadmin voit tout
        if ferme_id:
            result = db.execute(text("SELECT * FROM cycles WHERE ferme_id = :fid"), {"fid": ferme_id})
        else:
            result = db.execute(text("SELECT * FROM cycles"))
    else:
        if ferme_id:
            result = db.execute(text("""
                SELECT c.* FROM cycles c
                JOIN fermes f ON f.id = c.ferme_id
                WHERE f.entreprise_id = :eid AND c.ferme_id = :fid
            """), {"eid": current_user.entreprise_id, "fid": ferme_id})
        else:
            result = db.execute(text("""
                SELECT c.* FROM cycles c
                JOIN fermes f ON f.id = c.ferme_id
                WHERE f.entreprise_id = :eid
            """), {"eid": current_user.entreprise_id})
    
    cycles = [dict(row._mapping) for row in result]
    return {"total": len(cycles), "items": cycles}

@router.post("/", status_code=201)
def create_cycle(
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    cycle_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO cycles (
            id, ferme_id, type_cycle, date_debut,
            date_fin, statut, nom, nombre_sujets,
            batiment, souche
        )
        VALUES (
            :id, :fid, :type, :debut,
            :fin, :statut, :nom, :sujets,
            :bat, :souche
        )
    """), {
        "id": cycle_id,
        "fid": data.ferme_id,
        "type": data.type_cycle,
        "debut": data.date_debut,
        "fin": data.date_fin,
        "statut": data.statut,
        "nom": data.nom,
        "sujets": data.nombre_sujets,
        "bat": data.batiment,
        "souche": data.souche
    })
    db.commit()
    return {"message": "Cycle créé avec succès", "id": str(cycle_id)}

@router.put("/{cycle_id}")
def update_cycle(
    cycle_id: str,
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    db.execute(text("""
        UPDATE cycles SET
            type_cycle=:type,
            date_debut=:debut,
            date_fin=:fin,
            statut=:statut,
            nom=:nom,
            nombre_sujets=:sujets,
            batiment=:bat,
            souche=:souche
        WHERE id=:id
    """), {
        "type": data.type_cycle,
        "debut": data.date_debut,
        "fin": data.date_fin,
        "statut": data.statut,
        "nom": data.nom,
        "sujets": data.nombre_sujets,
        "bat": data.batiment,
        "souche": data.souche,
        "id": cycle_id
    })
    db.commit()
    return {"message": "Cycle mis à jour"}

@router.delete("/{cycle_id}")
def delete_cycle(
    cycle_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    db.execute(text(
        "DELETE FROM cycles WHERE id = :id"
    ), {"id": cycle_id})
    db.commit()
    return {"message": "Cycle supprimé avec succès"}

@router.get("/{cycle_id}")
def get_cycle(
    cycle_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(
        text("SELECT * FROM cycles WHERE id = :id"),
        {"id": cycle_id}
    ).fetchone()
    if not result:
        raise HTTPException(status_code=404, detail="Cycle introuvable")
    return dict(result._mapping)