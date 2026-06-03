from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/taches", tags=["Tâches"])

class TacheSchema(BaseModel):
    titre: str
    description: Optional[str] = None
    date_echeance: Optional[str] = None
    type: Optional[str] = 'autre'
    priorite: Optional[str] = 'normale'
    statut: Optional[str] = 'en_cours'
    cycle_id: Optional[str] = None
    ferme_id: Optional[str] = None
    assignee_id: Optional[str] = None

@router.get("/")
def get_taches(db: Session = Depends(get_db),
               current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT t.*, u.nom as assignee_nom, c.nom as cycle_nom
        FROM taches t
        LEFT JOIN utilisateurs u ON u.id = t.assignee_id
        LEFT JOIN cycles c ON c.id = t.cycle_id
        WHERE t.entreprise_id = :eid
        ORDER BY t.date_echeance ASC NULLS LAST, t.created_at DESC
    """), {"eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/", status_code=201)
def create_tache(data: TacheSchema, db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    tid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO taches
            (id, entreprise_id, titre, description, date_echeance,
             type, priorite, statut, cycle_id, ferme_id, assignee_id, created_by)
        VALUES
            (:id, :eid, :titre, :desc, :date,
             :type, :prio, :statut, :cid, :fid, :aid, :uid)
    """), {
        "id": tid, "eid": current_user.entreprise_id,
        "titre": data.titre, "desc": data.description,
        "date": data.date_echeance, "type": data.type,
        "prio": data.priorite, "statut": data.statut,
        "cid": data.cycle_id, "fid": data.ferme_id,
        "aid": data.assignee_id, "uid": current_user.id,
    })
    db.commit()
    return {"message": "Tâche créée", "id": tid}

@router.put("/{tid}")
def update_tache(tid: str, data: TacheSchema,
                  db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE taches SET titre=:titre, description=:desc, date_echeance=:date,
            type=:type, priorite=:prio, statut=:statut,
            cycle_id=:cid, ferme_id=:fid, assignee_id=:aid,
            updated_at=NOW()
        WHERE id=:id AND entreprise_id=:eid
    """), {
        "titre": data.titre, "desc": data.description, "date": data.date_echeance,
        "type": data.type, "prio": data.priorite, "statut": data.statut,
        "cid": data.cycle_id, "fid": data.ferme_id, "aid": data.assignee_id,
        "id": tid, "eid": current_user.entreprise_id,
    })
    db.commit()
    return {"message": "Tâche mise à jour"}

@router.patch("/{tid}/terminer")
def terminer_tache(tid: str, db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE taches SET statut='termine', updated_at=NOW()
        WHERE id=:id AND entreprise_id=:eid
    """), {"id": tid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Tâche terminée"}

@router.delete("/{tid}")
def delete_tache(tid: str, db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("DELETE FROM taches WHERE id=:id AND entreprise_id=:eid"),
               {"id": tid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Tâche supprimée"}
