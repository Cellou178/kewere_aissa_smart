from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel, Field
from uuid import UUID
import uuid

router = APIRouter(
    prefix="/stocks",
    tags=["Stocks"]
)

# ==========================================
# SCHEMA VALIDATION
# ==========================================
class StockSchema(BaseModel):

    ferme_id: str

    produit: str = Field(
        min_length=2,
        max_length=100
    )

    quantite: float = Field(
        ge=0
    )

    seuil_alerte: float = Field(
        ge=0
    )


# ==========================================
# LISTE STOCKS
# ==========================================
@router.get("/")
def get_stocks(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        get_current_user
    )
):

    result = db.execute(text("""
        SELECT s.*
        FROM stocks s
        JOIN fermes f
            ON f.id = s.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY s.produit ASC
    """), {
        "eid": current_user.entreprise_id
    })

    stocks = [
        dict(row._mapping)
        for row in result
    ]

    return {
        "total": len(stocks),
        "items": stocks
    }


# ==========================================
# CRÉER STOCK
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_stock(
    data: StockSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    # Vérifier ferme entreprise
    ferme = db.execute(text("""
        SELECT id
        FROM fermes
        WHERE id = :fid
        AND entreprise_id = :eid
    """), {
        "fid": data.ferme_id,
        "eid": current_user.entreprise_id
    }).fetchone()

    if not ferme:

        raise HTTPException(
            status_code=403,
            detail="Accès interdit à cette ferme"
        )

    stock_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO stocks (
            id,
            ferme_id,
            produit,
            quantite,
            seuil_alerte
        )
        VALUES (
            :id,
            :fid,
            :produit,
            :quantite,
            :seuil
        )
    """), {
        "id": stock_id,
        "fid": data.ferme_id,
        "produit": data.produit.strip(),
        "quantite": data.quantite,
        "seuil": data.seuil_alerte
    })

    db.commit()

    return {
        "success": True,
        "message": "Stock créé avec succès",
        "id": stock_id
    }


# ==========================================
# MODIFIER STOCK
# ==========================================
@router.put("/{stock_id}")
def update_stock(
    stock_id: UUID,
    data: StockSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager")
    )
):

    result = db.execute(text("""
        UPDATE stocks
        SET
            produit = :produit,
            quantite = :quantite,
            seuil_alerte = :seuil
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "produit": data.produit.strip(),
        "quantite": data.quantite,
        "seuil": data.seuil_alerte,
        "id": str(stock_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Stock introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Stock mis à jour avec succès"
    }


# ==========================================
# SUPPRIMER STOCK
# ==========================================
@router.delete("/{stock_id}")
def delete_stock(
    stock_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin")
    )
):

    result = db.execute(text("""
        DELETE FROM stocks
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": str(stock_id),
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:

        raise HTTPException(
            status_code=404,
            detail="Stock introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Stock supprimé avec succès"
    }