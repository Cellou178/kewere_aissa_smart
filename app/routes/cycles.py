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

# ========== LISTE ==========
@router.get("/")
def get_cycles(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT c.* FROM cycles c
        JOIN fermes f ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== CRÉER ==========
@router.post("/", status_code=201)
def create_cycle(
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    cycle_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO cycles (id, ferme_id, type_cycle, date_debut, date_fin, statut)
        VALUES (:id, :fid, :type, :debut, :fin, :statut)
    """), {
        "id": cycle_id, "fid": data.ferme_id,
        "type": data.type_cycle, "debut": data.date_debut,
        "fin": data.date_fin, "statut": data.statut
    })
    db.commit()
    return {"message": "Cycle créé avec succès", "id": str(cycle_id)}

# ========== MODIFIER ==========
@router.put("/{cycle_id}")
def update_cycle(
    cycle_id: str,
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    db.execute(text("""
        UPDATE cycles SET type_cycle=:type, date_debut=:debut,
        date_fin=:fin, statut=:statut WHERE id=:id
    """), {
        "type": data.type_cycle, "debut": data.date_debut,
        "fin": data.date_fin, "statut": data.statut, "id": cycle_id
    })
    db.commit()
    return {"message": "Cycle mis à jour"}
@router.delete("/{cycle_id}")
async def delete_cycle(cycle_id: str, db: Session = Depends(get_db), current_user = Depends(get_current_user)):
    cycle = db.query(Cycle).filter(Cycle.id == cycle_id).first()
    if not cycle:
        raise HTTPException(status_code=404, detail="Cycle non trouvé")
    db.delete(cycle)
    db.commit()
    return {"message": "Cycle supprimé avec succès"}