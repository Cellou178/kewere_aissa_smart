from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/stocks", tags=["Stocks"])

class StockSchema(BaseModel):
    ferme_id: str
    produit: str
    quantite: float
    seuil_alerte: float

# ========== LISTE ==========
@router.get("/")
def get_stocks(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT s.* FROM stocks s
        JOIN fermes f ON f.id = s.ferme_id
        WHERE f.entreprise_id = :eid
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== CRÉER ==========
@router.post("/", status_code=201)
def create_stock(
    data: StockSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    stock_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO stocks (id, ferme_id, produit, quantite, seuil_alerte)
        VALUES (:id, :fid, :produit, :quantite, :seuil)
    """), {
        "id": stock_id, "fid": data.ferme_id,
        "produit": data.produit, "quantite": data.quantite,
        "seuil": data.seuil_alerte
    })
    db.commit()
    return {"message": "Stock créé avec succès", "id": str(stock_id)}

# ========== MODIFIER ==========
@router.put("/{stock_id}")
def update_stock(
    stock_id: str,
    data: StockSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    db.execute(text("""
        UPDATE stocks SET produit=:produit, quantite=:quantite, seuil_alerte=:seuil
        WHERE id=:id
    """), {
        "produit": data.produit, "quantite": data.quantite,
        "seuil": data.seuil_alerte, "id": stock_id
    })
    db.commit()
    return {"message": "Stock mis à jour"}

# ========== SUPPRIMER ==========
@router.delete("/{stock_id}")
def delete_stock(
    stock_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin"))
):
    db.execute(text("DELETE FROM stocks WHERE id=:id"), {"id": stock_id})
    db.commit()
    return {"message": "Stock supprimé"}