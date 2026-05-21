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
            body=f"🐔 Kewere Aissa Smart\nVotre code de vérification : {code}\nValide 10 minutes.",
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
            body=f"🐔 *Kewere Aissa Smart*\nVotre code de vérification : *{code}*\nValide 10 minutes.",
            from_=f'whatsapp:{TWILIO_PHONE}',
            to=f'whatsapp:{numero}'
        )
        return True
    except Exception as e:
        print(f"Erreur WhatsApp: {e}")
        return False
