from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/finances", tags=["Finances"])

class TransactionSchema(BaseModel):
    libelle: str
    montant: float
    type: str
    categorie: str
    note: Optional[str] = None
    cycle_id: Optional[str] = None
    ferme_id: Optional[str] = None

@router.get("/")
def get_transactions(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    rows = db.execute(text("""
        SELECT t.* FROM transactions t
        WHERE t.entreprise_id = :eid
        ORDER BY t.created_at DESC
    """), {"eid": current_user.entreprise_id}).fetchall()
    return {"total": len(rows), "items": [dict(r._mapping) for r in rows]}

@router.post("/", status_code=201)
def create_transaction(
    data: TransactionSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    tid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO transactions
            (id, entreprise_id, ferme_id, cycle_id, libelle, montant, type, categorie, note)
        VALUES
            (:id, :eid, :fid, :cid, :lib, :montant, :type, :cat, :note)
    """), {
        "id": tid, "eid": current_user.entreprise_id,
        "fid": data.ferme_id, "cid": data.cycle_id,
        "lib": data.libelle, "montant": data.montant,
        "type": data.type, "cat": data.categorie, "note": data.note,
    })
    db.commit()
    return {"message": "Transaction créée", "id": tid}

@router.put("/{tid}")
def update_transaction(
    tid: str,
    data: TransactionSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        UPDATE transactions
        SET libelle=:lib, montant=:montant, type=:type,
            categorie=:cat, note=:note, cycle_id=:cid
        WHERE id=:id AND entreprise_id=:eid
    """), {
        "lib": data.libelle, "montant": data.montant, "type": data.type,
        "cat": data.categorie, "note": data.note, "cid": data.cycle_id,
        "id": tid, "eid": current_user.entreprise_id,
    })
    db.commit()
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Transaction introuvable")
    return {"message": "Transaction mise à jour"}

@router.delete("/{tid}")
def delete_transaction(
    tid: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    db.execute(text(
        "DELETE FROM transactions WHERE id=:id AND entreprise_id=:eid"
    ), {"id": tid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Transaction supprimée"}
