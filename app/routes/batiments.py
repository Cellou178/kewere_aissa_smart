from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/batiments", tags=["Bâtiments"])

class BatimentSchema(BaseModel):
    ferme_id: str
    nom: str
    capacite: Optional[int] = 0
    type: Optional[str] = 'poulailler'
    statut: Optional[str] = 'actif'
    surface_m2: Optional[float] = None
    date_construction: Optional[str] = None
    dernier_nettoyage: Optional[str] = None
    notes: Optional[str] = None

@router.get("/")
def get_batiments(ferme_id: Optional[str] = None,
                   db: Session = Depends(get_db),
                   current_user: Utilisateur = Depends(get_current_user)):
    q = """
        SELECT b.*, f.nom as ferme_nom,
            (SELECT COUNT(*) FROM cycles c WHERE c.batiment = b.nom
             AND c.statut IN ('actif','en_cours')) as cycles_actifs,
            (SELECT COALESCE(SUM(c.nombre_sujets),0) FROM cycles c
             WHERE c.batiment = b.nom AND c.statut IN ('actif','en_cours')) as occupants
        FROM batiments b
        JOIN fermes f ON f.id = b.ferme_id
        WHERE f.entreprise_id = :eid
    """
    params = {"eid": current_user.entreprise_id}
    if ferme_id:
        q += " AND b.ferme_id = :fid"
        params["fid"] = ferme_id
    q += " ORDER BY b.nom ASC"
    rows = db.execute(text(q), params).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/", status_code=201)
def create_batiment(data: BatimentSchema,
                     db: Session = Depends(get_db),
                     current_user: Utilisateur = Depends(get_current_user)):
    bid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO batiments
            (id, ferme_id, nom, capacite, type, statut,
             surface_m2, date_construction, dernier_nettoyage, notes)
        VALUES (:id,:fid,:nom,:cap,:type,:statut,:surf,:dc,:dn,:notes)
    """), {
        "id": bid, "fid": data.ferme_id, "nom": data.nom,
        "cap": data.capacite, "type": data.type, "statut": data.statut,
        "surf": data.surface_m2, "dc": data.date_construction,
        "dn": data.dernier_nettoyage, "notes": data.notes,
    })
    db.commit()
    return {"message": "Bâtiment créé", "id": bid}

@router.put("/{bid}")
def update_batiment(bid: str, data: BatimentSchema,
                     db: Session = Depends(get_db),
                     current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE batiments SET nom=:nom, capacite=:cap, type=:type, statut=:statut,
            surface_m2=:surf, dernier_nettoyage=:dn, notes=:notes
        WHERE id=:id AND ferme_id IN (SELECT id FROM fermes WHERE entreprise_id=:eid)
    """), {
        "nom": data.nom, "cap": data.capacite, "type": data.type,
        "statut": data.statut, "surf": data.surface_m2,
        "dn": data.dernier_nettoyage, "notes": data.notes,
        "id": bid, "eid": current_user.entreprise_id,
    })
    db.commit()
    return {"message": "Bâtiment mis à jour"}

@router.delete("/{bid}")
def delete_batiment(bid: str, db: Session = Depends(get_db),
                     current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        DELETE FROM batiments WHERE id=:id
        AND ferme_id IN (SELECT id FROM fermes WHERE entreprise_id=:eid)
    """), {"id": bid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Bâtiment supprimé"}
