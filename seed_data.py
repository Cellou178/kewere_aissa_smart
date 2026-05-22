import requests
from datetime import date, timedelta

BASE_URL = "https://kewere-aissa-smart.onrender.com"
EMAIL = "celloudiallo286@gmail.com"
PASSWORD = "Dakar2025"  # ← change ici

# 1. LOGIN
print("🔐 Connexion...")
r = requests.post(f"{BASE_URL}/auth/login",
    data={"username": EMAIL, "password": PASSWORD})
print("Réponse login:", r.status_code, r.text)
token = r.json()["access_token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
print("✅ Token obtenu !")

# 2. RÉCUPÉRER LA FERME
print("\n🏡 Récupération ferme...")
fermes = requests.get(f"{BASE_URL}/fermes/", headers=headers).json()
if fermes:
    ferme_id = fermes[0]["id"]
    print(f"✅ Ferme : {ferme_id}")
else:
    ferme = requests.post(f"{BASE_URL}/fermes/", headers=headers, json={
        "nom": "Ferme Kewere", "localisation": "Mbour", "type_elevage": "aviculture"
    }).json()
    ferme_id = ferme["id"]
    print(f"✅ Ferme créée : {ferme_id}")

# 3. CRÉER UN CYCLE
print("\n🐔 Création cycle...")
r = requests.post(f"{BASE_URL}/cycles/", headers=headers, json={
    "ferme_id": ferme_id,
    "type_cycle": "chair",
    "date_debut": "2026-04-01",
    "date_fin": None,
    "statut": "actif",
    "nom": "Cycle Cobb 500 - Mai 2026",
    "nombre_sujets": 2000,
    "batiment": "Bâtiment A",
    "souche": "Cobb 500",
})
print("Réponse cycle:", r.status_code, r.text)
cycle_id = r.json().get("id")
print(f"✅ Cycle ID : {cycle_id}")

# 4. DONNÉES JOURNALIÈRES
print("\n📊 Insertion données...")
date_debut = date(2026, 4, 1)
donnees = [
    {"mortalite": 3, "production": 0,    "temperature": 32.0, "humidite": 65.0, "jours": 1},
    {"mortalite": 2, "production": 0,    "temperature": 31.0, "humidite": 67.0, "jours": 7},
    {"mortalite": 4, "production": 0,    "temperature": 30.0, "humidite": 68.0, "jours": 14},
    {"mortalite": 3, "production": 0,    "temperature": 30.0, "humidite": 70.0, "jours": 21},
    {"mortalite": 5, "production": 0,    "temperature": 29.0, "humidite": 72.0, "jours": 28},
    {"mortalite": 4, "production": 0,    "temperature": 29.0, "humidite": 71.0, "jours": 35},
    {"mortalite": 6, "production": 2000, "temperature": 28.0, "humidite": 73.0, "jours": 42},
]
for d in donnees:
    payload = {
        "cycle_id": cycle_id,
        "date_releve": str(date_debut + timedelta(days=d["jours"])),
        "temperature": d["temperature"],
        "humidite": d["humidite"],
        "production": d["production"],
        "mortalite": d["mortalite"],
    }
    r = requests.post(f"{BASE_URL}/donnees/", headers=headers, json=payload)
    print(f"  J{d['jours']} → {'✅' if r.status_code in [200,201] else '❌ ' + r.text}")

# 5. STOCKS
print("\n📦 Stocks...")
stocks = [
    {"produit": "Aliment démarrage",  "quantite": 50, "unite": "sac",   "seuil_alerte": 10, "ferme_id": ferme_id},
    {"produit": "Aliment croissance", "quantite": 80, "unite": "sac",   "seuil_alerte": 15, "ferme_id": ferme_id},
    {"produit": "Vaccin Newcastle",   "quantite": 5,  "unite": "litre", "seuil_alerte": 2,  "ferme_id": ferme_id},
]
for s in stocks:
    r = requests.post(f"{BASE_URL}/stocks/", headers=headers, json=s)
    print(f"  {s['produit']} → {'✅' if r.status_code in [200,201] else '❌ ' + r.text}")

print("\n🎉 Terminé ! Rafraîchis l'app Flutter.")