from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/conges", tags=["Congés"])

class CongeSchema(BaseModel):
    employe_id: str
    type: Optional[str] = 'conge'      # conge | absence | maladie | formation
    date_debut: str
    date_fin: str
    motif: Optional[str] = None
    statut: Optional[str] = 'approuve'

@router.get("/")
def get_conges(employe_id: Optional[str] = None,
               db: Session = Depends(get_db),
               current_user: Utilisateur = Depends(get_current_user)):
    q = """
        SELECT c.*, e.nom as employe_nom, e.role as employe_role,
            (c.date_fin - c.date_debut + 1) as nb_jours
        FROM conges c
        JOIN employes e ON e.id = c.employe_id
        WHERE c.entreprise_id = :eid
    """
    params = {"eid": current_user.entreprise_id}
    if employe_id:
        q += " AND c.employe_id = :eid_emp"
        params["eid_emp"] = employe_id
    q += " ORDER BY c.date_debut DESC"
    rows = db.execute(text(q), params).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/", status_code=201)
def create_conge(data: CongeSchema,
                  db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    # Vérifier que l'employé appartient à l'entreprise
    emp = db.execute(text(
        "SELECT id FROM employes WHERE id=:id AND entreprise_id=:eid"
    ), {"id": data.employe_id, "eid": current_user.entreprise_id}).fetchone()
    if not emp:
        raise HTTPException(status_code=403, detail="Employé introuvable")

    cid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO conges
            (id, employe_id, entreprise_id, type, date_debut, date_fin, motif, statut, approuve_par)
        VALUES (:id, :eid_emp, :eid, :type, :debut, :fin, :motif, :statut, :uid)
    """), {
        "id": cid, "eid_emp": data.employe_id,
        "eid": current_user.entreprise_id, "type": data.type,
        "debut": data.date_debut, "fin": data.date_fin,
        "motif": data.motif, "statut": data.statut,
        "uid": current_user.id,
    })
    db.commit()
    return {"message": "Congé enregistré", "id": cid}

@router.patch("/{cid}/approuver")
def approuver_conge(cid: str, db: Session = Depends(get_db),
                     current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE conges SET statut='approuve', approuve_par=:uid
        WHERE id=:id AND entreprise_id=:eid
    """), {"uid": current_user.id, "id": cid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Congé approuvé"}

@router.patch("/{cid}/refuser")
def refuser_conge(cid: str, db: Session = Depends(get_db),
                   current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE conges SET statut='refuse'
        WHERE id=:id AND entreprise_id=:eid
    """), {"id": cid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Congé refusé"}

@router.delete("/{cid}")
def delete_conge(cid: str, db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text(
        "DELETE FROM conges WHERE id=:id AND entreprise_id=:eid"
    ), {"id": cid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Congé supprimé"}
