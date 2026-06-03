from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel, Field
from typing import Optional
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
    produit: str = Field(min_length=2, max_length=100)
    quantite: float = Field(ge=0)
    seuil_alerte: float = Field(ge=0)
    prix_unitaire: Optional[float] = Field(default=0, ge=0)
    unite: Optional[str] = 'kg'
    categorie: Optional[str] = 'aliment'
    description: Optional[str] = None


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
        require_role("admin", "manager", "proprietaire")
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
            id, ferme_id, produit, quantite, seuil_alerte,
            prix_unitaire, unite, categorie, description
        )
        VALUES (
            :id, :fid, :produit, :quantite, :seuil,
            :prix, :unite, :categorie, :description
        )
    """), {
        "id": stock_id,
        "fid": data.ferme_id,
        "produit": data.produit.strip(),
        "quantite": data.quantite,
        "seuil": data.seuil_alerte,
        "prix": data.prix_unitaire or 0,
        "unite": data.unite or 'kg',
        "categorie": data.categorie or 'aliment',
        "description": data.description,
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
        require_role("admin", "manager", "proprietaire")
    )
):

    result = db.execute(text("""
        UPDATE stocks
        SET produit=:produit, quantite=:quantite, seuil_alerte=:seuil,
            prix_unitaire=:prix, unite=:unite, categorie=:categorie,
            description=:description
        WHERE id=:id
        AND ferme_id IN (SELECT id FROM fermes WHERE entreprise_id=:eid)
    """), {
        "produit": data.produit.strip(),
        "quantite": data.quantite,
        "seuil": data.seuil_alerte,
        "prix": data.prix_unitaire or 0,
        "unite": data.unite or 'kg',
        "categorie": data.categorie or 'aliment',
        "description": data.description,
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
        require_role("admin", "proprietaire")
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


# ==========================================
# ENREGISTRER UN MOUVEMENT (ENTRÉE / SORTIE)
# ==========================================
class MouvementSchema(BaseModel):
    type: str                          # 'entree' | 'sortie'
    quantite: float = Field(gt=0)
    cycle_id: Optional[str] = None
    motif: Optional[str] = None

@router.post("/{stock_id}/mouvement", status_code=201)
def ajouter_mouvement(
    stock_id: UUID,
    data: MouvementSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    stock = db.execute(text("""
        SELECT s.id, s.quantite, s.produit, f.entreprise_id
        FROM stocks s JOIN fermes f ON f.id = s.ferme_id
        WHERE s.id = :id
    """), {"id": str(stock_id)}).fetchone()

    if not stock or stock.entreprise_id != current_user.entreprise_id:
        raise HTTPException(status_code=404, detail="Stock introuvable")

    nouvelle_qte = stock.quantite + data.quantite if data.type == 'entree' \
                   else stock.quantite - data.quantite

    if nouvelle_qte < 0:
        raise HTTPException(status_code=400,
            detail=f"Stock insuffisant (disponible: {stock.quantite})")

    mid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO stock_mouvements
            (id, stock_id, type, quantite, quantite_avant, quantite_apres,
             cycle_id, motif, utilisateur_id)
        VALUES (:id, :sid, :type, :qte, :avant, :apres, :cid, :motif, :uid)
    """), {
        "id": mid, "sid": str(stock_id),
        "type": data.type, "qte": data.quantite,
        "avant": stock.quantite, "apres": nouvelle_qte,
        "cid": data.cycle_id, "motif": data.motif,
        "uid": current_user.id,
    })
    db.execute(text("UPDATE stocks SET quantite=:q WHERE id=:id"),
               {"q": nouvelle_qte, "id": str(stock_id)})
    db.commit()
    return {"message": "Mouvement enregistré", "nouvelle_quantite": nouvelle_qte}


# ==========================================
# HISTORIQUE DES MOUVEMENTS
# ==========================================
@router.get("/{stock_id}/mouvements")
def get_mouvements(
    stock_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    rows = db.execute(text("""
        SELECT m.*, u.nom as utilisateur_nom, c.nom as cycle_nom
        FROM stock_mouvements m
        LEFT JOIN utilisateurs u ON u.id = m.utilisateur_id
        LEFT JOIN cycles c ON c.id = m.cycle_id
        JOIN stocks s ON s.id = m.stock_id
        JOIN fermes f ON f.id = s.ferme_id
        WHERE m.stock_id = :sid AND f.entreprise_id = :eid
        ORDER BY m.created_at DESC
        LIMIT 100
    """), {"sid": str(stock_id), "eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]