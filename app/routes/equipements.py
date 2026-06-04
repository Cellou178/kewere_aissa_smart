from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/equipements", tags=["Équipements"])

class EquipementSchema(BaseModel):
    ferme_id: str
    batiment_nom: Optional[str] = None
    nom: str
    type: Optional[str] = 'autre'
    etat: Optional[str] = 'bon'         # bon | attention | critique
    derniere_maintenance: Optional[str] = None
    prochaine_maintenance: Optional[str] = None
    heures_utilisation: Optional[int] = 0
    notes: Optional[str] = None

@router.get("/")
def get_equipements(ferme_id: Optional[str] = None,
                    db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    q = """
        SELECT e.*, f.nom as ferme_nom
        FROM equipements e
        JOIN fermes f ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
    """
    params = {"eid": current_user.entreprise_id}
    if ferme_id:
        q += " AND e.ferme_id = :fid"
        params["fid"] = ferme_id
    q += " ORDER BY e.etat DESC, e.nom ASC"
    rows = db.execute(text(q), params).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/", status_code=201)
def create_equipement(data: EquipementSchema,
                       db: Session = Depends(get_db),
                       current_user: Utilisateur = Depends(get_current_user)):
    eid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO equipements
            (id, ferme_id, batiment_nom, nom, type, etat,
             derniere_maintenance, prochaine_maintenance, heures_utilisation, notes)
        VALUES (:id,:fid,:bat,:nom,:type,:etat,:dm,:pm,:h,:notes)
    """), {"id": eid, "fid": data.ferme_id, "bat": data.batiment_nom,
           "nom": data.nom, "type": data.type, "etat": data.etat,
           "dm": data.derniere_maintenance, "pm": data.prochaine_maintenance,
           "h": data.heures_utilisation, "notes": data.notes})
    db.commit()
    return {"message": "Équipement créé", "id": eid}

@router.put("/{eid}")
def update_equipement(eid: str, data: EquipementSchema,
                       db: Session = Depends(get_db),
                       current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE equipements SET batiment_nom=:bat, nom=:nom, type=:type,
            etat=:etat, derniere_maintenance=:dm, prochaine_maintenance=:pm,
            heures_utilisation=:h, notes=:notes
        WHERE id=:id AND ferme_id IN (SELECT id FROM fermes WHERE entreprise_id=:eid)
    """), {"bat": data.batiment_nom, "nom": data.nom, "type": data.type,
           "etat": data.etat, "dm": data.derniere_maintenance,
           "pm": data.prochaine_maintenance, "h": data.heures_utilisation,
           "notes": data.notes, "id": eid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Équipement mis à jour"}

@router.delete("/{eid}")
def delete_equipement(eid: str, db: Session = Depends(get_db),
                       current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        DELETE FROM equipements WHERE id=:id
        AND ferme_id IN (SELECT id FROM fermes WHERE entreprise_id=:eid)
    """), {"id": eid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Équipement supprimé"}
