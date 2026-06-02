import os
import random
import string
import httpx

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY", "")
SENDGRID_FROM    = os.getenv("SENDGRID_FROM", "celloudiallo286@gmail.com")
RESEND_API_KEY   = os.getenv("RESEND_API_KEY", "")

def generer_code(longueur=6) -> str:
    return ''.join(random.choices(string.digits, k=longueur))

def envoyer_email(destinataire: str, sujet: str, corps_html: str) -> bool:
    print(f"📧 Envoi email → {destinataire} | {sujet}")

    # Priorité 1 : SendGrid (HTTP API, pas de port bloqué, expéditeur email vérifié)
    if SENDGRID_API_KEY:
        try:
            resp = httpx.post(
                "https://api.sendgrid.com/v3/mail/send",
                headers={
                    "Authorization": f"Bearer {SENDGRID_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "personalizations": [{"to": [{"email": destinataire}]}],
                    "from": {"email": SENDGRID_FROM, "name": "Kewere Aissa Smart"},
                    "subject": sujet,
                    "content": [{"type": "text/html", "value": corps_html}],
                },
                timeout=15.0,
            )
            if resp.status_code in (200, 201, 202):
                print(f"✅ Email envoyé via SendGrid à {destinataire}")
                return True
            else:
                print(f"❌ SendGrid erreur {resp.status_code}: {resp.text}")
        except Exception as e:
            print(f"❌ SendGrid exception: {type(e).__name__}: {e}")

    # Fallback : Resend (si domaine vérifié configuré)
    if RESEND_API_KEY:
        try:
            resp = httpx.post(
                "https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {RESEND_API_KEY}",
                         "Content-Type": "application/json"},
                json={"from": "Kewere Aissa Smart <onboarding@resend.dev>",
                      "to": [destinataire], "subject": sujet, "html": corps_html},
                timeout=15.0,
            )
            if resp.status_code in (200, 201):
                print(f"✅ Email envoyé via Resend à {destinataire}")
                return True
            else:
                print(f"❌ Resend erreur {resp.status_code}: {resp.text}")
        except Exception as e:
            print(f"❌ Resend exception: {type(e).__name__}: {e}")

    print("❌ Aucun service email configuré (SENDGRID_API_KEY manquant)")
    return False


def email_code_inscription(destinataire: str, nom: str, code: str) -> bool:
    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;background:#f8fafc;padding:20px;border-radius:12px">
      <div style="background:linear-gradient(135deg,#1B3A6B,#16A34A);padding:20px;border-radius:10px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px">🐔 Kewere Aissa Smart</h1>
        <p style="color:rgba(255,255,255,0.8);margin:5px 0 0">Plateforme Avicole Intelligente</p>
      </div>
      <div style="background:white;padding:24px;border-radius:10px;margin-top:12px">
        <h2 style="color:#1E293B;margin-top:0">Confirmation de votre compte</h2>
        <p style="color:#475569">Bonjour <strong>{nom}</strong>,</p>
        <p style="color:#475569">Voici votre code de confirmation :</p>
        <div style="background:#f1f5f9;border:2px dashed #2563EB;border-radius:10px;padding:20px;text-align:center;margin:20px 0">
          <span style="font-size:36px;font-weight:900;letter-spacing:8px;color:#1B3A6B">{code}</span>
        </div>
        <p style="color:#94a3b8;font-size:13px">Ce code expire dans <strong>15 minutes</strong>.<br>
        Si vous n'avez pas créé de compte, ignorez cet email.</p>
      </div>
      <p style="text-align:center;color:#94a3b8;font-size:11px;margin-top:12px">
        © 2026 Kewere Aissa Smart • Sénégal
      </p>
    </div>
    """
    return envoyer_email(destinataire, "🐔 Votre code de confirmation Kewere", html)


def email_reset_mdp(destinataire: str, nom: str, code: str) -> bool:
    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;background:#f8fafc;padding:20px;border-radius:12px">
      <div style="background:linear-gradient(135deg,#7F1D1D,#1B3A6B);padding:20px;border-radius:10px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px">🔒 Réinitialisation</h1>
        <p style="color:rgba(255,255,255,0.8);margin:5px 0 0">Kewere Aissa Smart</p>
      </div>
      <div style="background:white;padding:24px;border-radius:10px;margin-top:12px">
        <h2 style="color:#1E293B;margin-top:0">Réinitialisation du mot de passe</h2>
        <p style="color:#475569">Bonjour <strong>{nom}</strong>,</p>
        <p style="color:#475569">Voici votre code de réinitialisation :</p>
        <div style="background:#fef2f2;border:2px dashed #DC2626;border-radius:10px;padding:20px;text-align:center;margin:20px 0">
          <span style="font-size:36px;font-weight:900;letter-spacing:8px;color:#DC2626">{code}</span>
        </div>
        <p style="color:#94a3b8;font-size:13px">Ce code expire dans <strong>10 minutes</strong>.<br>
        Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      </div>
    </div>
    """
    return envoyer_email(destinataire, "🔒 Réinitialisation mot de passe Kewere", html)
