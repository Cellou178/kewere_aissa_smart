from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/cycles", tags=["Cycles"])

class CycleSchema(BaseModel):
    ferme_id: str
    type_cycle: str
    date_debut: str
    date_fin: Optional[str] = None
    statut: Optional[str] = "actif"
    nom: Optional[str] = None
    nombre_sujets: Optional[int] = None
    batiment: Optional[str] = None
    souche: Optional[str] = None

# ========== LISTE ==========
@router.get("/")
def get_cycles(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    result = db.execute(text("""
        SELECT c.* FROM cycles c
        JOIN fermes f ON f.id = c.ferme_id
        WHERE f.entreprise_id = :eid
    """), {"eid": current_user.entreprise_id})
    return [dict(row._mapping) for row in result]

# ========== CRÉER ==========
@router.post("/", status_code=201)
def create_cycle(
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    cycle_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO cycles (id, ferme_id, type_cycle, date_debut, date_fin, statut, nom, nombre_sujets, batiment, souche)
        VALUES (:id, :fid, :type, :debut, :fin, :statut, :nom, :sujets, :bat, :souche)
    """), {
        "id": cycle_id, "fid": data.ferme_id,
        "type": data.type_cycle, "debut": data.date_debut,
        "fin": data.date_fin, "statut": data.statut,
        "nom": data.nom, "sujets": data.nombre_sujets,
        "bat": data.batiment, "souche": data.souche
    })
    db.commit()
    return {"message": "Cycle créé avec succès", "id": str(cycle_id)}

# ========== MODIFIER ==========
@router.put("/{cycle_id}")
def update_cycle(
    cycle_id: str,
    data: CycleSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin", "manager"))
):
    db.execute(text("""
        UPDATE cycles SET type_cycle=:type, date_debut=:debut,
        date_fin=:fin, statut=:statut, nom=:nom,
        nombre_sujets=:sujets, batiment=:bat, souche=:souche
        WHERE id=:id
    """), {
        "type": data.type_cycle, "debut": data.date_debut,
        "fin": data.date_fin, "statut": data.statut,
        "nom": data.nom, "sujets": data.nombre_sujets,
        "bat": data.batiment, "souche": data.souche,
        "id": cycle_id
    })
    db.commit()
    return {"message": "Cycle mis à jour"}

# ========== SUPPRIMER ==========
@router.delete("/{cycle_id}")
def delete_cycle(
    cycle_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    db.execute(text("DELETE FROM cycles WHERE id = :id"), {"id": cycle_id})
    db.commit()
    return {"message": "Cycle supprimé avec succès"}

notepad ~/kewere_aissa_smart/app/sms_service.py
from twilio.rest import Client
import os
import random

ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID')
AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN')
TWILIO_PHONE = os.environ.get('TWILIO_PHONE')

def generer_code():
    return str(random.randint(100000, 999999))

def envoyer_sms(numero: str, code: str):
    try:
        client = Client(ACCOUNT_SID, AUTH_TOKEN)
        client.messages.create(
            body=f"🐔 Kewere Aissa Smart\nVotre code : {code}\nValide 10 minutes.",
            from_=TWILIO_PHONE,
            to=numero
        )
        return True
    except Exception as e:
        print(f"Erreur SMS: {e}")
        return False

def envoyer_whatsapp(numero: str, code: str):
    try:
        client = Client(ACCOUNT_SID, AUTH_TOKEN)
        client.messages.create(
            body=f"🐔 *Kewere Aissa Smart*\nVotre code : *{code}*\nValide 10 minutes.",
            from_=f'whatsapp:{TWILIO_PHONE}',
            to=f'whatsapp:{numero}'
        )
        return True
    except Exception as e:
        print(f"Erreur WhatsApp: {e}")
        return False
