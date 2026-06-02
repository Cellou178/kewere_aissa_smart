from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.models import Utilisateur, Role
from app.auth import hash_password, verify_password, create_access_token
from app.dependencies import get_current_user
from app.email_service import generer_code, email_code_inscription, email_reset_mdp
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, timedelta
import uuid

router = APIRouter(
    prefix="/auth",
    tags=["Authentification"]
)

class RegisterSchema(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    email: EmailStr
    mot_de_passe: str = Field(min_length=6, max_length=100)
    telephone: Optional[str] = Field(
        default=None, min_length=8, max_length=20)
    nom_ferme: Optional[str] = Field(
        default="Ma Ferme", min_length=2, max_length=100)
    role: Optional[str] = Field(
        default="proprietaire", max_length=50)

class TokenSchema(BaseModel):
    access_token: str
    token_type: str

@router.post("/register", status_code=201)
def register(data: RegisterSchema, db: Session = Depends(get_db)):
    existing = db.execute(text("""
        SELECT id FROM utilisateurs WHERE email = :email LIMIT 1
    """), {"email": data.email}).fetchone()

    if existing:
        raise HTTPException(status_code=400,
            detail="Email déjà utilisé")

    # Rôles autorisés à l'auto-inscription
    role_demande = (data.role or "proprietaire").lower()
    if role_demande not in ("proprietaire", "vendeur", "manager", "employe"):
        role_demande = "proprietaire"

    # S'assurer que le rôle existe (créer si absent)
    role = db.execute(text("""
        SELECT id FROM roles WHERE nom = :nom LIMIT 1
    """), {"nom": role_demande}).fetchone()

    if not role:
        # Insérer le rôle manquant
        db.execute(text("""
            INSERT INTO roles (nom) VALUES (:nom)
        """), {"nom": role_demande})
        db.commit()
        role = db.execute(text("""
            SELECT id FROM roles WHERE nom = :nom LIMIT 1
        """), {"nom": role_demande}).fetchone()

    if not role:
        raise HTTPException(status_code=400,
            detail="Impossible de créer le rôle")

    entreprise_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO entreprises (id, nom, email)
        VALUES (:id, :nom, :email)
    """), {
        "id": entreprise_id,
        "nom": f"Entreprise {data.nom}",
        "email": data.email
    })

    # Les vendeurs n'ont pas de ferme
    ferme_id = None
    if role_demande != "vendeur":
        ferme_id = str(uuid.uuid4())
        db.execute(text("""
            INSERT INTO fermes (id, nom, entreprise_id, localisation, superficie)
            VALUES (:id, :nom, :eid, '', 0)
        """), {
            "id": ferme_id,
            "nom": data.nom_ferme or "Ma Ferme",
            "eid": entreprise_id
        })

    user_id = str(uuid.uuid4())
    if ferme_id:
        db.execute(text("""
            INSERT INTO utilisateurs (
                id, nom, email, mot_de_passe,
                role_id, entreprise_id, ferme_id, actif, telephone
            )
            VALUES (
                :id, :nom, :email, :mdp,
                :role_id, :eid, :fid, true, :tel
            )
        """), {
            "id": user_id,
            "nom": data.nom.strip(),
            "email": data.email.strip().lower(),
            "mdp": hash_password(data.mot_de_passe),
            "role_id": role.id,
            "eid": entreprise_id,
            "fid": ferme_id,
            "tel": data.telephone or "",
        })
    else:
        db.execute(text("""
            INSERT INTO utilisateurs (
                id, nom, email, mot_de_passe,
                role_id, entreprise_id, actif, telephone
            )
            VALUES (
                :id, :nom, :email, :mdp,
                :role_id, :eid, true, :tel
            )
        """), {
            "id": user_id,
            "nom": data.nom.strip(),
            "email": data.email.strip().lower(),
            "mdp": hash_password(data.mot_de_passe),
            "role_id": role.id,
            "eid": entreprise_id,
            "tel": data.telephone or "",
        })

    db.execute(text("""
        INSERT INTO abonnements (entreprise_id, plan, statut, prix)
        VALUES (:eid, 'gratuit', 'actif', 0)
    """), {"eid": entreprise_id})

    db.commit()

    return {
        "success": True,
        "message": "Compte créé avec succès",
        "id": user_id,
        "entreprise_id": entreprise_id,
        "ferme_id": ferme_id or ""
    }

@router.post("/login")
def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    result = db.execute(text("""
        SELECT u.id, u.nom, u.email, u.mot_de_passe, u.actif,
               r.nom as role_nom,
               u.entreprise_id, u.ferme_id
        FROM utilisateurs u
        JOIN roles r ON r.id = u.role_id
        WHERE u.email = :email
        LIMIT 1
    """), {"email": form.username.lower()}).fetchone()

    if not result or not verify_password(
            form.password, result.mot_de_passe):
        raise HTTPException(status_code=401,
            detail="Email ou mot de passe incorrect")

    if not result.actif:
        raise HTTPException(status_code=403,
            detail="Compte désactivé")

    token = create_access_token({
        "sub": result.email,
        "role": result.role_nom,
        "uid": str(result.id),
        "entreprise_id": str(result.entreprise_id),
        "ferme_id": str(result.ferme_id)
    })

    return {
        "access_token": token,
        "token_type": "bearer",
        "role": result.role_nom,
        "nom": result.nom,
        "email": result.email,
        "entreprise_id": str(result.entreprise_id) if result.entreprise_id else "",
        "ferme_id": str(result.ferme_id) if result.ferme_id else "",
    }

@router.get("/activer/{email}")
def activer_compte(email: str, db: Session = Depends(get_db)):
    db.execute(text("""
        UPDATE utilisateurs SET actif = true WHERE email = :email
    """), {"email": email.lower()})
    db.commit()
    return {"success": True, "message": f"Compte {email} activé"}

class EnvoyerCodeSchema(BaseModel):
    email: EmailStr
    type: str = "inscription"

class VerifierCodeSchema(BaseModel):
    email: EmailStr
    code: str
    type: str = "inscription"

class ResetMdpSchema(BaseModel):
    email: EmailStr
    code: str
    nouveau_mdp: str = Field(min_length=6, max_length=100)

def _sauvegarder_code(email: str, type_code: str, db: Session) -> str:
    code = generer_code()
    duree = 15 if type_code == "inscription" else 10
    expire = datetime.now() + timedelta(minutes=duree)
    db.execute(text("""
        UPDATE codes_verification SET utilise = true
        WHERE email = :email AND type = :type AND utilise = false
    """), {"email": email, "type": type_code})
    db.execute(text("""
        INSERT INTO codes_verification (email, code, type, expire_le)
        VALUES (:email, :code, :type, :expire)
    """), {"email": email, "code": code, "type": type_code, "expire": expire})
    db.commit()
    return code

def _verifier_code_db(email: str, code: str, type_code: str, db: Session) -> bool:
    result = db.execute(text("""
        SELECT id FROM codes_verification
        WHERE email = :email AND code = :code AND type = :type
          AND utilise = false AND expire_le > NOW()
        LIMIT 1
    """), {"email": email, "code": code, "type": type_code}).fetchone()
    if result:
        db.execute(text("""
            UPDATE codes_verification SET utilise = true WHERE id = :id
        """), {"id": result.id})
        db.commit()
        return True
    return False

@router.post("/envoyer-code")
def envoyer_code(data: EnvoyerCodeSchema, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    if data.type == "reset_mdp":
        user = db.execute(text("""
            SELECT nom FROM utilisateurs WHERE email = :email LIMIT 1
        """), {"email": data.email.lower()}).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Email introuvable")
        code = _sauvegarder_code(data.email.lower(), "reset_mdp", db)
        background_tasks.add_task(email_reset_mdp, data.email, user.nom, code)
    else:
        code = _sauvegarder_code(data.email.lower(), "inscription", db)
        background_tasks.add_task(email_code_inscription, data.email, "Utilisateur", code)
    return {"success": True, "message": f"Code envoyé à {data.email}"}

@router.post("/verifier-code")
def verifier_code(data: VerifierCodeSchema, db: Session = Depends(get_db)):
    ok = _verifier_code_db(data.email.lower(), data.code, data.type, db)
    if not ok:
        raise HTTPException(status_code=400, detail="Code invalide ou expiré")
    return {"success": True, "message": "Code vérifié"}

@router.post("/reset-mdp")
def reset_mdp(data: ResetMdpSchema, db: Session = Depends(get_db)):
    ok = _verifier_code_db(data.email.lower(), data.code, "reset_mdp", db)
    if not ok:
        raise HTTPException(status_code=400, detail="Code invalide ou expiré")
    db.execute(text("""
        UPDATE utilisateurs SET mot_de_passe = :mdp WHERE email = :email
    """), {"mdp": hash_password(data.nouveau_mdp), "email": data.email.lower()})
    db.commit()
    return {"success": True, "message": "Mot de passe modifié avec succès"}

@router.get("/me")
def me(current_user = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "nom": current_user.nom,
        "email": current_user.email,
        "telephone": getattr(current_user, 'telephone', ''),
        "role": current_user.role.nom,
        "entreprise_id": str(current_user.entreprise_id),
        "ferme_id": str(current_user.ferme_id),
        "actif": current_user.actif
    }