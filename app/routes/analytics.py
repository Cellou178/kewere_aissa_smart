from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
import os
import httpx
import json
from datetime import datetime, date

router = APIRouter(prefix="/analytics", tags=["Analytics"])

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")

# ── Seuils avicoles standards ──
SEUILS = {
    "mortalite_ok": 3.0,
    "mortalite_alerte": 5.0,
    "mortalite_critique": 8.0,
    "temp_min": 20.0,
    "temp_max": 33.0,
    "temp_ideal_min": 25.0,
    "temp_ideal_max": 30.0,
    "humidite_min": 50.0,
    "humidite_max": 75.0,
    "ic_excellent": 1.8,
    "ic_bon": 2.2,
    "ic_moyen": 2.6,
    "poids_j7": 180,
    "poids_j14": 420,
    "poids_j21": 800,
    "poids_j28": 1250,
    "poids_j35": 1800,
    "poids_j42": 2400,
}

def _score_mortalite(taux):
    if taux <= SEUILS["mortalite_ok"]: return 100
    if taux <= SEUILS["mortalite_alerte"]: return 75
    if taux <= SEUILS["mortalite_critique"]: return 40
    return 0

def _score_temperature(temp):
    if SEUILS["temp_ideal_min"] <= temp <= SEUILS["temp_ideal_max"]: return 100
    if SEUILS["temp_min"] <= temp <= SEUILS["temp_max"]: return 60
    return 20

def _score_humidite(hum):
    if SEUILS["humidite_min"] <= hum <= SEUILS["humidite_max"]: return 100
    if hum > SEUILS["humidite_max"]: return 30
    return 60

def _score_ic(ic):
    if ic <= SEUILS["ic_excellent"]: return 100
    if ic <= SEUILS["ic_bon"]: return 75
    if ic <= SEUILS["ic_moyen"]: return 50
    return 20

@router.get("/cycle/{cycle_id}")
def analyse_cycle(cycle_id: str, current_user=Depends(get_current_user),
                  db: Session = Depends(get_db)):

    cycle = db.execute(text("""
        SELECT c.*, f.nom as ferme_nom, f.entreprise_id
        FROM cycles c JOIN fermes f ON c.ferme_id = f.id
        WHERE c.id = :id
    """), {"id": cycle_id}).fetchone()

    if not cycle:
        raise HTTPException(status_code=404, detail="Cycle introuvable")

    donnees = db.execute(text("""
        SELECT * FROM donnees_journalieres
        WHERE cycle_id = :id ORDER BY date_releve ASC
    """), {"id": cycle_id}).fetchall()

    if not donnees:
        return {"cycle_id": cycle_id, "message": "Aucune donnée disponible",
                "score_global": 0, "kpis": {}, "recommandations": [], "alertes": []}

    # ── Calculs KPIs ──
    nb_initial = cycle.nombre_sujets or 1
    mortalite_totale = sum(d.mortalite or 0 for d in donnees)
    vendus_total = sum(d.nombre_sujets_vendus or 0 for d in donnees)
    sujets_vivants = nb_initial - mortalite_totale - vendus_total
    taux_mortalite = round((mortalite_totale / nb_initial) * 100, 2)

    aliments = [d.aliment_consomme or 0 for d in donnees]
    aliment_total = sum(aliments)
    poids_moyen_actuel = float(donnees[-1].poids_moyen_global or 0)
    poids_total_kg = (poids_moyen_actuel * sujets_vivants) / 1000

    ic = round(aliment_total / (poids_total_kg * 1000), 2) if poids_total_kg > 0 else 0

    temps = [d.temperature or 0 for d in donnees if d.temperature]
    humids = [d.humidite or 0 for d in donnees if d.humidite]
    temp_moy = round(sum(temps) / len(temps), 1) if temps else 0
    hum_moy = round(sum(humids) / len(humids), 1) if humids else 0
    temp_derniere = float(donnees[-1].temperature or 0)
    hum_derniere = float(donnees[-1].humidite or 0)

    date_debut = cycle.date_debut
    age_jours = (date.today() - date_debut).days if date_debut else len(donnees)

    # Tendances (7 derniers jours)
    recentes = donnees[-7:] if len(donnees) >= 7 else donnees
    mortalite_recente = sum(d.mortalite or 0 for d in recentes)
    taux_mortalite_recent = round((mortalite_recente / nb_initial) * 100, 2)

    # Poids référence Gompertz
    A, b, k = 2200, 3.5, 0.085
    poids_theorique = round(A * (2.718 ** (-(b * (2.718 ** (-k * age_jours))))), 0)
    ecart_poids = round(((poids_moyen_actuel - poids_theorique) / poids_theorique * 100), 1) if poids_theorique > 0 else 0

    # ── Score global ──
    score_mort = _score_mortalite(taux_mortalite)
    score_temp = _score_temperature(temp_moy)
    score_hum = _score_humidite(hum_moy)
    score_ic_val = _score_ic(ic) if ic > 0 else 80
    score_global = round(score_mort * 0.4 + score_temp * 0.2 + score_hum * 0.2 + score_ic_val * 0.2)

    statut = ("Excellent" if score_global >= 80 else
              "Bon" if score_global >= 60 else
              "Moyen" if score_global >= 40 else "Critique")

    # ── Alertes temps réel ──
    alertes = []
    if taux_mortalite > SEUILS["mortalite_critique"]:
        alertes.append({"niveau": "critique", "message": f"Mortalité critique : {taux_mortalite}% — intervention urgente requise"})
    elif taux_mortalite > SEUILS["mortalite_alerte"]:
        alertes.append({"niveau": "alerte", "message": f"Mortalité élevée : {taux_mortalite}% — surveiller de près"})

    if temp_derniere > SEUILS["temp_max"]:
        alertes.append({"niveau": "alerte", "message": f"Température trop haute : {temp_derniere}°C — ventiler immédiatement"})
    elif temp_derniere < SEUILS["temp_min"]:
        alertes.append({"niveau": "alerte", "message": f"Température trop basse : {temp_derniere}°C — chauffer le bâtiment"})

    if hum_derniere > SEUILS["humidite_max"]:
        alertes.append({"niveau": "alerte", "message": f"Humidité excessive : {hum_derniere}% — risque de maladies respiratoires"})

    if ecart_poids < -10:
        alertes.append({"niveau": "info", "message": f"Poids inférieur aux normes de {abs(ecart_poids)}% — revoir la densité et l'alimentation"})

    if mortalite_recente > 0:
        alertes.append({"niveau": "info", "message": f"{mortalite_recente} morts ces 7 derniers jours — surveiller la litière et l'eau"})

    # ── Recommandations basées sur les données ──
    recommandations = []

    if taux_mortalite > SEUILS["mortalite_alerte"]:
        recommandations.append({
            "priorite": "haute",
            "categorie": "Santé",
            "action": "Effectuer une autopsie sur les derniers morts pour identifier la cause",
            "impact": "Réduction immédiate de la mortalité"
        })
        recommandations.append({
            "priorite": "haute",
            "categorie": "Santé",
            "action": "Vérifier la qualité de l'eau et désinfecter les abreuvoirs",
            "impact": "Prévention des maladies d'origine hydrique"
        })

    if temp_moy > 30:
        recommandations.append({
            "priorite": "haute",
            "categorie": "Ambiance",
            "action": f"Augmenter la ventilation — température moyenne {temp_moy}°C dépasse l'optimal",
            "impact": "Amélioration de la croissance et réduction du stress thermique"
        })

    if ic > SEUILS["ic_moyen"]:
        recommandations.append({
            "priorite": "moyenne",
            "categorie": "Alimentation",
            "action": f"Revoir la qualité de l'aliment — IC de {ic} indique une mauvaise conversion",
            "impact": "Réduction des coûts d'alimentation de 15-20%"
        })

    if ecart_poids < -5:
        recommandations.append({
            "priorite": "moyenne",
            "categorie": "Croissance",
            "action": f"Poids de {poids_moyen_actuel:.0f}g vs {poids_theorique:.0f}g attendus — vérifier la densité et la qualité de l'aliment",
            "impact": "Rattrapage du retard de croissance"
        })

    if hum_moy > 70:
        recommandations.append({
            "priorite": "moyenne",
            "categorie": "Litière",
            "action": "Retourner et assécher la litière — humidité > 70% favorise les coccidioses",
            "impact": "Prévention des maladies intestinales"
        })

    if age_jours >= 30 and taux_mortalite <= SEUILS["mortalite_alerte"]:
        recommandations.append({
            "priorite": "info",
            "categorie": "Vente",
            "action": f"Cycle à J{age_jours} — évaluer le prix de vente actuel via le simulateur marché",
            "impact": "Optimisation du revenu"
        })

    # ── Prédictions ──
    jours_restants_estime = max(0, 42 - age_jours)
    poids_fin_estime = round(A * (2.718 ** (-(b * (2.718 ** (-k * 42))))), 0)
    prix_marche = db.execute(text("""
        SELECT AVG(prix) FROM prix_marche WHERE categorie = 'poulet'
    """)).scalar() or 2800
    revenu_estime = round((poids_fin_estime / 1000) * float(prix_marche) * sujets_vivants, 0)

    return {
        "cycle_id": cycle_id,
        "cycle_nom": cycle.nom,
        "ferme_nom": cycle.ferme_nom,
        "age_jours": age_jours,
        "score_global": score_global,
        "statut": statut,
        "kpis": {
            "nb_initial": nb_initial,
            "sujets_vivants": sujets_vivants,
            "mortalite_totale": mortalite_totale,
            "taux_mortalite": taux_mortalite,
            "taux_mortalite_7j": taux_mortalite_recent,
            "poids_moyen_actuel": round(poids_moyen_actuel, 0),
            "poids_theorique": poids_theorique,
            "ecart_poids_pct": ecart_poids,
            "ic": ic,
            "aliment_total_kg": round(aliment_total, 1),
            "temp_moyenne": temp_moy,
            "temp_derniere": temp_derniere,
            "hum_moyenne": hum_moy,
            "hum_derniere": hum_derniere,
        },
        "scores": {
            "mortalite": score_mort,
            "temperature": score_temp,
            "humidite": score_hum,
            "conversion": score_ic_val,
        },
        "predictions": {
            "age_actuel": age_jours,
            "jours_restants": jours_restants_estime,
            "poids_fin_estime_g": poids_fin_estime,
            "sujets_a_vendre": sujets_vivants,
            "revenu_estime_fcfa": revenu_estime,
            "prix_marche_kg": round(float(prix_marche), 0),
        },
        "alertes": alertes,
        "recommandations": recommandations,
    }


@router.get("/entreprise")
def analyse_entreprise(current_user=Depends(get_current_user),
                       db: Session = Depends(get_db)):
    eid = str(current_user.entreprise_id)

    cycles_actifs = db.execute(text("""
        SELECT c.id, c.nom, c.nombre_sujets, c.date_debut, f.nom as ferme_nom
        FROM cycles c JOIN fermes f ON c.ferme_id = f.id
        WHERE f.entreprise_id = :eid AND c.statut = 'actif'
    """), {"eid": eid}).fetchall()

    stats = db.execute(text("""
        SELECT
            COUNT(DISTINCT c.id) FILTER (WHERE c.statut='actif') as cycles_actifs,
            COUNT(DISTINCT c.id) as cycles_total,
            COALESCE(SUM(dj.mortalite), 0) as mortalite_totale,
            COALESCE(SUM(c.nombre_sujets), 0) as sujets_total,
            COALESCE(AVG(dj.temperature), 0) as temp_moy,
            COALESCE(AVG(dj.humidite), 0) as hum_moy,
            COALESCE(AVG(dj.poids_moyen_global), 0) as poids_moy,
            COALESCE(SUM(dj.aliment_consomme), 0) as aliment_total
        FROM fermes f
        JOIN cycles c ON c.ferme_id = f.id
        LEFT JOIN donnees_journalieres dj ON dj.cycle_id = c.id
        WHERE f.entreprise_id = :eid
    """), {"eid": eid}).fetchone()

    sujets = int(stats.sujets_total or 0)
    morts = int(stats.mortalite_totale or 0)
    taux_mort = round((morts / sujets * 100), 2) if sujets > 0 else 0
    score = _score_mortalite(taux_mort)

    return {
        "nb_cycles_actifs": len(cycles_actifs),
        "cycles_actifs": [{"id": str(c.id), "nom": c.nom,
                           "ferme": c.ferme_nom,
                           "nb_sujets": c.nombre_sujets} for c in cycles_actifs],
        "stats_globales": {
            "cycles_total": int(stats.cycles_total or 0),
            "sujets_total": sujets,
            "mortalite_totale": morts,
            "taux_mortalite_global": taux_mort,
            "temp_moyenne": round(float(stats.temp_moy or 0), 1),
            "hum_moyenne": round(float(stats.hum_moy or 0), 1),
            "poids_moyen": round(float(stats.poids_moy or 0), 0),
            "aliment_total_kg": round(float(stats.aliment_total or 0), 1),
        },
        "score_global": score,
    }


@router.post("/ia/{cycle_id}")
async def analyse_ia(cycle_id: str, current_user=Depends(get_current_user),
                     db: Session = Depends(get_db)):
    if not ANTHROPIC_API_KEY:
        raise HTTPException(status_code=500, detail="Clé API Claude non configurée")

    # Récupérer les données du cycle
    cycle = db.execute(text("""
        SELECT c.*, f.nom as ferme_nom
        FROM cycles c JOIN fermes f ON c.ferme_id = f.id
        WHERE c.id = :id
    """), {"id": cycle_id}).fetchone()

    if not cycle:
        raise HTTPException(status_code=404, detail="Cycle introuvable")

    donnees = db.execute(text("""
        SELECT date_releve, poids_moyen_global, mortalite, temperature,
               humidite, aliment_consomme, taux_mortalite, ic_inis
        FROM donnees_journalieres
        WHERE cycle_id = :id ORDER BY date_releve DESC LIMIT 14
    """), {"id": cycle_id}).fetchall()

    age_jours = (date.today() - cycle.date_debut).days if cycle.date_debut else 0

    donnees_resume = []
    for d in donnees:
        donnees_resume.append({
            "date": str(d.date_releve),
            "poids_g": float(d.poids_moyen_global or 0),
            "mortalite": int(d.mortalite or 0),
            "temp": float(d.temperature or 0),
            "humidite": float(d.humidite or 0),
            "aliment_kg": float(d.aliment_consomme or 0),
        })

    mortalite_totale = db.execute(text("""
        SELECT COALESCE(SUM(mortalite), 0), COALESCE(SUM(aliment_consomme), 0)
        FROM donnees_journalieres WHERE cycle_id = :id
    """), {"id": cycle_id}).fetchone()

    sujets = cycle.nombre_sujets or 1
    morts = int(mortalite_totale[0] or 0)
    aliment_total = float(mortalite_totale[1] or 0)
    poids_actuel = float(donnees[0].poids_moyen_global or 0) if donnees else 0
    taux_mort = round((morts / sujets) * 100, 2)
    poids_total_kg = (poids_actuel * (sujets - morts)) / 1000
    ic = round(aliment_total / (poids_total_kg * 1000), 2) if poids_total_kg > 0 else 0

    prompt = f"""Tu es un expert zootechnicien spécialisé en aviculture en Afrique de l'Ouest.
Analyse ce cycle d'élevage et fournis une analyse précise et des recommandations concrètes.

INFORMATIONS DU CYCLE:
- Nom: {cycle.nom}
- Ferme: {cycle.ferme_nom}
- Type: {cycle.type_cycle or 'Poulet de chair'}
- Age actuel: {age_jours} jours
- Sujets initiaux: {sujets}
- Sujets vivants: {sujets - morts}
- Mortalité totale: {morts} ({taux_mort}%)
- Poids moyen actuel: {poids_actuel:.0f}g
- Indice de consommation (IC): {ic}
- Aliment total consommé: {aliment_total:.1f}kg

DONNÉES 14 DERNIERS JOURS:
{json.dumps(donnees_resume, ensure_ascii=False, indent=2)}

NORMES DE RÉFÉRENCE:
- Mortalité acceptable: <3% (alerte >5%, critique >8%)
- IC excellent: <1.8, bon: <2.2
- Poids J{age_jours} référence Gompertz: {round(2200 * (2.718 ** (-(3.5 * (2.718 ** (-0.085 * age_jours))))), 0):.0f}g
- Température idéale: 25-30°C
- Humidité idéale: 50-70%

Réponds en JSON strict avec cette structure:
{{
  "analyse_globale": "texte d'analyse en 3-4 phrases",
  "points_positifs": ["point1", "point2"],
  "points_negatifs": ["point1", "point2"],
  "actions_immediates": [
    {{"action": "...", "delai": "...", "impact": "..."}}
  ],
  "recommandations_7j": [
    {{"action": "...", "categorie": "...", "priorite": "haute/moyenne/faible"}}
  ],
  "prediction_fin_cycle": {{
    "poids_estime_g": 0,
    "date_vente_optimale": "...",
    "revenu_estime_fcfa": 0,
    "risque_principal": "..."
  }},
  "score_sante": 0
}}"""

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": "claude-haiku-4-5-20251001",
                "max_tokens": 1500,
                "messages": [{"role": "user", "content": prompt}]
            },
            timeout=30.0
        )

    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Erreur Claude API")

    data = response.json()
    texte = data["content"][0]["text"]

    try:
        debut = texte.find("{")
        fin = texte.rfind("}") + 1
        resultat = json.loads(texte[debut:fin])
    except Exception:
        resultat = {"analyse_globale": texte, "score_sante": 50}

    return {"cycle_id": cycle_id, "age_jours": age_jours, "analyse_ia": resultat}
