from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/marche", tags=["Marché"])

@router.get("/prix")
def get_prix(categorie: Optional[str] = None,
             current_user=Depends(get_current_user),
             db: Session = Depends(get_db)):
    q = "SELECT * FROM prix_marche"
    params = {}
    if categorie:
        q += " WHERE categorie = :cat"
        params["cat"] = categorie
    q += " ORDER BY categorie, produit"
    rows = db.execute(text(q), params).fetchall()
    return [{"id": r.id, "categorie": r.categorie, "produit": r.produit,
             "unite": r.unite, "prix": float(r.prix), "pays": r.pays,
             "ville": r.ville, "tendance": r.tendance,
             "variation": float(r.variation),
             "derniere_maj": r.derniere_maj.isoformat() if r.derniere_maj else None}
            for r in rows]

class UpdatePrixSchema(BaseModel):
    prix: float
    tendance: Optional[str] = None
    variation: Optional[float] = None

@router.put("/prix/{prix_id}")
def update_prix(prix_id: int, data: UpdatePrixSchema,
                current_user=Depends(get_current_user),
                db: Session = Depends(get_db)):
    if current_user.role.nom.lower() not in ['admin', 'proprietaire']:
        raise HTTPException(status_code=403, detail="Accès refusé")
    db.execute(text("""
        UPDATE prix_marche
        SET prix = :prix,
            tendance = COALESCE(:tendance, tendance),
            variation = COALESCE(:variation, variation),
            derniere_maj = NOW()
        WHERE id = :id
    """), {"prix": data.prix, "tendance": data.tendance,
           "variation": data.variation, "id": prix_id})
    db.commit()
    return {"success": True}

@router.get("/simulateur/{cycle_id}")
def simulateur(cycle_id: str,
               nb_a_vendre: Optional[int] = None,
               prix_kg: Optional[float] = None,
               current_user=Depends(get_current_user),
               db: Session = Depends(get_db)):

    cycle = db.execute(text("""
        SELECT c.id, c.nom, c.nombre_sujets, c.date_debut, c.type_cycle,
               f.entreprise_id
        FROM cycles c JOIN fermes f ON c.ferme_id = f.id
        WHERE c.id = :id
    """), {"id": cycle_id}).fetchone()

    if not cycle:
        raise HTTPException(status_code=404, detail="Cycle introuvable")

    if cycle.entreprise_id != current_user.entreprise_id:
        raise HTTPException(status_code=403, detail="Accès interdit")

    # Dernière donnée journalière
    derniere = db.execute(text("""
        SELECT date_releve, poids_moyen_global, mortalite, aliment_consomme,
               nombre_sujets_vendus,
               (date_releve - :debut::date) AS age_jours
        FROM donnees_journalieres
        WHERE cycle_id = :id
        ORDER BY date_releve DESC LIMIT 1
    """), {"id": cycle_id, "debut": cycle.date_debut}).fetchone()

    # Totaux
    totaux = db.execute(text("""
        SELECT COALESCE(SUM(mortalite), 0) as mortalite_totale,
               COALESCE(SUM(aliment_consomme), 0) as aliment_total,
               COALESCE(SUM(nombre_sujets_vendus), 0) as vendus_total
        FROM donnees_journalieres WHERE cycle_id = :id
    """), {"id": cycle_id}).fetchone()

    nb_initial = cycle.nombre_sujets or 0
    mortalite_totale = int(totaux.mortalite_totale or 0)
    vendus_total = int(totaux.vendus_total or 0)
    sujets_restants = nb_initial - mortalite_totale - vendus_total
    poids_moyen = float(derniere.poids_moyen_global or 0) if derniere else 0
    age_jours = int(derniere.age_jours or 0) if derniere else 0
    aliment_total_kg = float(totaux.aliment_total or 0)

    # Prix marché poulet (moyen Dakar)
    prix_marche_row = db.execute(text("""
        SELECT AVG(prix) as prix_moyen FROM prix_marche
        WHERE categorie = 'poulet'
    """)).fetchone()
    prix_marche_kg = float(prix_marche_row.prix_moyen or 2800) if prix_marche_row else 2800

    # Prix poussin du marché
    poussin_row = db.execute(text("""
        SELECT prix FROM prix_marche
        WHERE produit ILIKE '%poussin%' LIMIT 1
    """)).fetchone()
    prix_poussin_unitaire = float(poussin_row.prix or 650) if poussin_row else 650

    # Prix aliment moyen
    aliment_row = db.execute(text("""
        SELECT AVG(prix/50.0) as prix_kg FROM prix_marche
        WHERE categorie = 'aliment' AND produit ILIKE '%sac%'
    """)).fetchone()
    prix_aliment_kg = float(aliment_row.prix_kg or 340) if aliment_row else 340

    # Paramètres de simulation
    px_kg = prix_kg if prix_kg else prix_marche_kg
    nb_vendre = nb_a_vendre if nb_a_vendre else sujets_restants

    # Calculs
    prix_par_poussin = round(poids_moyen * px_kg, 0)
    revenu_total = round(prix_par_poussin * nb_vendre, 0)

    # Coûts estimés
    cout_poussins = nb_initial * prix_poussin_unitaire
    cout_aliment = aliment_total_kg * prix_aliment_kg
    cout_total_estime = cout_poussins + cout_aliment

    # Coût par poussin restant
    sujets_produits = max(sujets_restants, 1)
    cout_par_poussin = round(cout_total_estime / sujets_produits, 0)
    profit_par_poussin = round(prix_par_poussin - cout_par_poussin, 0)
    profit_total = round(profit_par_poussin * nb_vendre, 0)
    rentable = profit_par_poussin > 0

    # Prix minimum pour être rentable
    prix_min_rentable = round(cout_par_poussin / max(poids_moyen, 0.1), 0) if poids_moyen > 0 else 0

    return {
        "cycle_nom": cycle.nom,
        "age_jours": age_jours,
        "nb_initial": nb_initial,
        "sujets_restants": sujets_restants,
        "mortalite_totale": mortalite_totale,
        "poids_moyen_kg": poids_moyen,
        "aliment_total_kg": aliment_total_kg,
        "prix_marche_kg": prix_marche_kg,
        "simulation": {
            "nb_a_vendre": nb_vendre,
            "prix_kg_utilise": px_kg,
            "prix_par_poussin": prix_par_poussin,
            "revenu_total": revenu_total,
            "cout_par_poussin": cout_par_poussin,
            "cout_total_estime": cout_total_estime,
            "profit_par_poussin": profit_par_poussin,
            "profit_total": profit_total,
            "rentable": rentable,
            "prix_min_rentable_kg": prix_min_rentable,
        }
    }
