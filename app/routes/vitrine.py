from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/vitrine", tags=["Vitrine"])

class ProduitSchema(BaseModel):
    nom: str
    categorie: Optional[str] = 'Volaille'
    prix: float
    unite: Optional[str] = 'par tête'
    quantite: Optional[float] = 0
    description: Optional[str] = None
    disponible: Optional[bool] = True
    icon: Optional[str] = '🐔'

@router.get("/produits")
def get_produits(db: Session = Depends(get_db),
                  current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT * FROM produits_vitrine
        WHERE entreprise_id = :eid
        ORDER BY disponible DESC, categorie, nom
    """), {"eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/produits", status_code=201)
def create_produit(data: ProduitSchema,
                    db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    pid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO produits_vitrine
            (id, entreprise_id, nom, categorie, prix, unite,
             quantite, description, disponible, icon)
        VALUES (:id,:eid,:nom,:cat,:prix,:unite,:qte,:desc,:dispo,:icon)
    """), {"id": pid, "eid": current_user.entreprise_id,
           "nom": data.nom, "cat": data.categorie,
           "prix": data.prix, "unite": data.unite,
           "qte": data.quantite, "desc": data.description,
           "dispo": data.disponible, "icon": data.icon})
    db.commit()
    return {"message": "Produit créé", "id": pid}

@router.put("/produits/{pid}")
def update_produit(pid: str, data: ProduitSchema,
                    db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("""
        UPDATE produits_vitrine
        SET nom=:nom, categorie=:cat, prix=:prix, unite=:unite,
            quantite=:qte, description=:desc, disponible=:dispo, icon=:icon
        WHERE id=:id AND entreprise_id=:eid
    """), {"nom": data.nom, "cat": data.categorie, "prix": data.prix,
           "unite": data.unite, "qte": data.quantite, "desc": data.description,
           "dispo": data.disponible, "icon": data.icon,
           "id": pid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Produit mis à jour"}

@router.delete("/produits/{pid}")
def delete_produit(pid: str, db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text(
        "DELETE FROM produits_vitrine WHERE id=:id AND entreprise_id=:eid"
    ), {"id": pid, "eid": current_user.entreprise_id})
    db.commit()
    return {"message": "Produit supprimé"}

@router.get("/commandes")
def get_commandes(db: Session = Depends(get_db),
                   current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT cv.*, u.nom as vendeur_nom
        FROM commandes_vendeur cv
        LEFT JOIN utilisateurs u ON u.id = cv.vendeur_id
        WHERE cv.partenaire_id IN (
            SELECT id FROM utilisateurs WHERE entreprise_id = :eid
        )
        ORDER BY cv.created_at DESC
    """), {"eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]
