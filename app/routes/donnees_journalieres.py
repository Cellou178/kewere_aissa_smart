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
    prefix="/donnees",
    tags=["Données Journalières"]
)

class DonneeSchema(BaseModel):
    cycle_id: str
    date_releve: str
    action: Optional[str] = None
    
    # Effectif
    mortalite: int = Field(ge=0, default=0)
    nombre_sujets_vendus: int = Field(ge=0, default=0)
    production: float = Field(ge=0, default=0)
    
    # Pesées 5 groupes de 20
    poids_g1: Optional[float] = None
    poids_g2: Optional[float] = None
    poids_g3: Optional[float] = None
    poids_g4: Optional[float] = None
    poids_g5: Optional[float] = None
    poids_moyen_global: Optional[float] = None
    homogeneite: Optional[float] = None
    poids_standard: Optional[float] = None
    deviation_plus: Optional[float] = None
    deviation_moins: Optional[float] = None
    
    # Ambiance
    temperature_matin: Optional[float] = None
    temperature_soir: Optional[float] = None
    temperature_standard: Optional[str] = None
    humidite_valeur: Optional[float] = None
    humidite_standard: Optional[str] = None
    
    # Alimentation
    aliment_consomme: Optional[float] = None
    aliment_restant: Optional[float] = None
    sacs_restants: Optional[float] = None
    
    # Indicateurs
    ic_inis: Optional[float] = None
    taux_mortalite: Optional[float] = None
    commentaire: Optional[str] = None


def _calc(data: DonneeSchema):
    """Calculs automatiques communs à create et update."""
    poids_list = [p for p in [
        data.poids_g1, data.poids_g2, data.poids_g3,
        data.poids_g4, data.poids_g5
    ] if p is not None]

    poids_moyen = data.poids_moyen_global
    if poids_list and not poids_moyen:
        poids_moyen = sum(poids_list) / len(poids_list)

    homogeneite = data.homogeneite
    if len(poids_list) >= 2 and not homogeneite:
        homogeneite = max(poids_list) - min(poids_list)

    temp_moy = None
    if data.temperature_matin and data.temperature_soir:
        temp_moy = (data.temperature_matin + data.temperature_soir) / 2

    return poids_moyen, homogeneite, temp_moy


def _params(data: DonneeSchema, poids_moyen, homogeneite, temp_moy):
    """Dictionnaire de paramètres SQL commun."""
    return {
        "cid": data.cycle_id,
        "date": data.date_releve,
        "action": data.action,
        "mort": data.mortalite,
        "vendus": data.nombre_sujets_vendus,
        "prod": data.production,
        "g1": data.poids_g1,
        "g2": data.poids_g2,
        "g3": data.poids_g3,
        "g4": data.poids_g4,
        "g5": data.poids_g5,
        "poids_moyen": poids_moyen,
        "homogeneite": homogeneite,
        "poids_std": data.poids_standard,
        "dev_plus": data.deviation_plus,
        "dev_moins": data.deviation_moins,
        "temp_matin": data.temperature_matin,
        "temp_soir": data.temperature_soir,
        "temp_moy": temp_moy,
        "temp_std": data.temperature_standard,
        "hum_val": data.humidite_valeur,
        "hum_std": data.humidite_standard,
        "aliment_conso": data.aliment_consomme,
        "aliment_rest": data.aliment_restant,
        "sacs_rest": data.sacs_restants,
        "ic": data.ic_inis,
        "taux_mort": data.taux_mortalite,
        "commentaire": data.commentaire,
    }


@router.get("/")
def get_donnees(
    cycle_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    if cycle_id:
        result = db.execute(text("""
            SELECT dj.*
            FROM donnees_journalieres dj
            JOIN cycles c ON c.id = dj.cycle_id
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
            AND dj.cycle_id = :cid
            ORDER BY dj.date_releve DESC
        """), {"eid": current_user.entreprise_id, "cid": cycle_id})
    else:
        result = db.execute(text("""
            SELECT dj.*
            FROM donnees_journalieres dj
            JOIN cycles c ON c.id = dj.cycle_id
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
            ORDER BY dj.date_releve DESC
        """), {"eid": current_user.entreprise_id})

    donnees = [dict(row._mapping) for row in result]
    return {"total": len(donnees), "items": donnees}


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_donnee(
    data: DonneeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    cycle = db.execute(text("""
        SELECT c.id FROM cycles c
        JOIN fermes f ON f.id = c.ferme_id
        WHERE c.id = :cid AND f.entreprise_id = :eid
    """), {"cid": data.cycle_id, "eid": current_user.entreprise_id}).fetchone()

    if not cycle:
        raise HTTPException(status_code=403, detail="Cycle interdit")

    poids_moyen, homogeneite, temp_moy = _calc(data)
    donnee_id = str(uuid.uuid4())
    params = _params(data, poids_moyen, homogeneite, temp_moy)
    params["id"] = donnee_id

    db.execute(text("""
        INSERT INTO donnees_journalieres (
            id, cycle_id, date_releve, action,
            mortalite, nombre_sujets_vendus, production,
            poids_g1, poids_g2, poids_g3, poids_g4, poids_g5,
            poids_moyen_global, homogeneite, poids_standard,
            deviation_plus, deviation_moins,
            temperature_matin, temperature_soir, temperature_standard,
            humidite_valeur, humidite_standard,
            aliment_consomme, aliment_restant, sacs_restants,
            ic_inis, taux_mortalite, commentaire
        ) VALUES (
            :id, :cid, :date, :action,
            :mort, :vendus, :prod,
            :g1, :g2, :g3, :g4, :g5,
            :poids_moyen, :homogeneite, :poids_std,
            :dev_plus, :dev_moins,
            :temp_matin, :temp_soir, :temp_std,
            :hum_val, :hum_std,
            :aliment_conso, :aliment_rest, :sacs_rest,
            :ic, :taux_mort, :commentaire
        )
    """), params)

    db.commit()
    return {
        "success": True,
        "message": "Données enregistrées avec succès",
        "id": donnee_id
    }


@router.put("/{donnee_id}")
def update_donnee(
    donnee_id: UUID,
    data: DonneeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    poids_moyen, homogeneite, temp_moy = _calc(data)
    params = _params(data, poids_moyen, homogeneite, temp_moy)
    params["id"] = str(donnee_id)
    params["eid"] = current_user.entreprise_id

    result = db.execute(text("""
        UPDATE donnees_journalieres SET
            date_releve=:date, action=:action,
            mortalite=:mort, nombre_sujets_vendus=:vendus, production=:prod,
            poids_g1=:g1, poids_g2=:g2, poids_g3=:g3, poids_g4=:g4, poids_g5=:g5,
            poids_moyen_global=:poids_moyen, homogeneite=:homogeneite,
            poids_standard=:poids_std, deviation_plus=:dev_plus,
            deviation_moins=:dev_moins,
            temperature_matin=:temp_matin, temperature_soir=:temp_soir,
            temperature_standard=:temp_std,
            humidite_valeur=:hum_val, humidite_standard=:hum_std,
            aliment_consomme=:aliment_conso, aliment_restant=:aliment_rest,
            sacs_restants=:sacs_rest, ic_inis=:ic,
            taux_mortalite=:taux_mort, commentaire=:commentaire
        WHERE id=:id
        AND cycle_id IN (
            SELECT c.id FROM cycles c
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        )
    """), params)

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Donnée introuvable ou accès interdit"
        )

    return {"success": True, "message": "Données mises à jour"}


@router.delete("/{donnee_id}")
def delete_donnee(
    donnee_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        DELETE FROM donnees_journalieres
        WHERE id = :id
        AND cycle_id IN (
            SELECT c.id FROM cycles c
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        )
    """), {"id": str(donnee_id), "eid": current_user.entreprise_id})

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Donnée introuvable ou accès interdit"
        )

    return {"success": True, "message": "Données supprimées"}


@router.get("/{donnee_id}")
def get_donnee(
    donnee_id: UUID,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT dj.* FROM donnees_journalieres dj
        JOIN cycles c ON c.id = dj.cycle_id
        JOIN fermes f ON f.id = c.ferme_id
        WHERE dj.id = :id AND f.entreprise_id = :eid
    """), {"id": str(donnee_id), "eid": current_user.entreprise_id}).fetchone()

    if not result:
        raise HTTPException(status_code=404, detail="Donnée introuvable")

    return dict(result._mapping)