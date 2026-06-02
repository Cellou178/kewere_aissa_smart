from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/vendeur", tags=["Vendeur"])


# ── Schemas ──────────────────────────────────────────────────────────────────

class CommandeSchema(BaseModel):
    partenaire_id: Optional[str] = None
    partenaire_nom: Optional[str] = None
    produit: str
    quantite: int
    notes: Optional[str] = ""


# ── Initialisation de la table commandes_vendeur ─────────────────────────────

def _ensure_table(db: Session) -> None:
    db.execute(text("""
        CREATE TABLE IF NOT EXISTS commandes_vendeur (
            id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            vendeur_id  UUID NOT NULL,
            vendeur_nom VARCHAR(150),
            partenaire_id UUID,
            partenaire_nom VARCHAR(150),
            produit     VARCHAR(150) NOT NULL,
            quantite    INTEGER NOT NULL DEFAULT 1,
            notes       TEXT DEFAULT '',
            statut      VARCHAR(20) NOT NULL DEFAULT 'en_attente',
            created_at  TIMESTAMP DEFAULT NOW()
        )
    """))
    db.commit()


# ── GET /vendeur/partenaires ──────────────────────────────────────────────────

@router.get("/partenaires")
def get_partenaires(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retourne la liste des proprietaires de fermes disponibles
    comme partenaires pour les vendeurs.
    """
    rows = db.execute(text("""
        SELECT
            u.id,
            u.nom                AS proprietaire,
            u.email,
            u.telephone,
            e.nom                AS entreprise_nom,
            e.pays,
            f.id                 AS ferme_id,
            f.nom                AS ferme_nom,
            f.localisation
        FROM utilisateurs u
        JOIN roles r       ON u.role_id = r.id
        JOIN entreprises e ON u.entreprise_id = e.id
        LEFT JOIN fermes f ON u.ferme_id = f.id
        WHERE r.nom = 'proprietaire'
          AND u.actif = true
          AND u.id != :uid
        ORDER BY u.nom
    """), {"uid": str(current_user.id)}).fetchall()

    result = []
    emojis = ["🐔", "🥚", "🐣", "🌿", "🌱"]
    for idx, r in enumerate(rows):
        nom_affiche = r.ferme_nom or r.entreprise_nom or r.proprietaire
        localisation = r.localisation or r.pays or "Non renseigne"
        result.append({
            "id": str(r.id),
            "nom": nom_affiche,
            "proprietaire": r.proprietaire,
            "email": r.email,
            "telephone": r.telephone or "",
            "localisation": localisation,
            "ferme_id": str(r.ferme_id) if r.ferme_id else None,
            "ferme_nom": r.ferme_nom,
            "certifie": False,
            "livraison": False,
            "note": 4.5,
            "stock_disponible": 0,
            "prix_min": 2000,
            "prix_max": 4000,
            "produits": ["Poulets vivants", "Poulets abattus"],
            "emoji": emojis[idx % len(emojis)],
        })
    return result


# ── GET /vendeur/commandes ────────────────────────────────────────────────────

@router.get("/commandes")
def get_mes_commandes(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retourne les commandes passees par le vendeur connecte."""
    _ensure_table(db)

    rows = db.execute(text("""
        SELECT id, partenaire_nom, produit, quantite, notes, statut, created_at
        FROM commandes_vendeur
        WHERE vendeur_id = :uid
        ORDER BY created_at DESC
    """), {"uid": str(current_user.id)}).fetchall()

    return [
        {
            "id": str(r.id),
            "partenaire_nom": r.partenaire_nom or "",
            "produit": r.produit,
            "quantite": r.quantite,
            "notes": r.notes or "",
            "statut": r.statut,
            "date": r.created_at.isoformat() if r.created_at else None,
        }
        for r in rows
    ]


# ── POST /vendeur/commandes ───────────────────────────────────────────────────

@router.post("/commandes", status_code=201)
def passer_commande(
    data: CommandeSchema,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Le vendeur passe une commande aupres d'un partenaire eleveur.
    Seuls les vendeurs (et admin) peuvent utiliser cet endpoint.
    """
    role = current_user.role.nom.lower()
    if role not in ("vendeur", "admin"):
        raise HTTPException(
            status_code=403,
            detail="Acces reserve aux vendeurs"
        )

    _ensure_table(db)

    cmd_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO commandes_vendeur (
            id, vendeur_id, vendeur_nom,
            partenaire_id, partenaire_nom,
            produit, quantite, notes, statut
        ) VALUES (
            :id, :vendeur_id, :vendeur_nom,
            :partenaire_id, :partenaire_nom,
            :produit, :quantite, :notes, 'en_attente'
        )
    """), {
        "id": cmd_id,
        "vendeur_id": str(current_user.id),
        "vendeur_nom": current_user.nom,
        "partenaire_id": data.partenaire_id,
        "partenaire_nom": data.partenaire_nom or "",
        "produit": data.produit,
        "quantite": data.quantite,
        "notes": data.notes or "",
    })
    db.commit()

    return {
        "success": True,
        "message": "Commande envoyee avec succes",
        "id": cmd_id
    }


# ── GET /vendeur/commandes/recues ─────────────────────────────────────────────

@router.get("/commandes/recues")
def get_commandes_recues(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Pour les proprietaires : voir les commandes recues des vendeurs
    sur leur ferme.
    """
    role = current_user.role.nom.lower()
    if role not in ("proprietaire", "admin", "manager"):
        raise HTTPException(
            status_code=403,
            detail="Acces reserve aux proprietaires"
        )

    _ensure_table(db)

    rows = db.execute(text("""
        SELECT id, vendeur_nom, partenaire_nom, produit,
               quantite, notes, statut, created_at
        FROM commandes_vendeur
        WHERE partenaire_id = :uid
        ORDER BY created_at DESC
    """), {"uid": str(current_user.id)}).fetchall()

    return [
        {
            "id": str(r.id),
            "vendeur_nom": r.vendeur_nom or "",
            "produit": r.produit,
            "quantite": r.quantite,
            "notes": r.notes or "",
            "statut": r.statut,
            "date": r.created_at.isoformat() if r.created_at else None,
        }
        for r in rows
    ]


# ── PUT /vendeur/commandes/{id}/statut ───────────────────────────────────────

@router.put("/commandes/{commande_id}/statut")
def maj_statut_commande(
    commande_id: str,
    statut: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Le proprietaire met a jour le statut d'une commande recue.
    Statuts valides : en_attente | confirme | livre | annule
    """
    statuts_valides = ("en_attente", "confirme", "livre", "annule")
    if statut not in statuts_valides:
        raise HTTPException(
            status_code=400,
            detail=f"Statut invalide. Valeurs: {', '.join(statuts_valides)}"
        )

    role = current_user.role.nom.lower()
    if role not in ("proprietaire", "admin", "manager"):
        raise HTTPException(
            status_code=403,
            detail="Acces refuse"
        )

    _ensure_table(db)

    db.execute(text("""
        UPDATE commandes_vendeur
        SET statut = :statut
        WHERE id = :id AND partenaire_id = :uid
    """), {
        "statut": statut,
        "id": commande_id,
        "uid": str(current_user.id),
    })
    db.commit()

    return {"success": True, "message": f"Statut mis a jour : {statut}"}
