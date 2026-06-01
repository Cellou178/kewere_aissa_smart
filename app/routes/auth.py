from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.models import Utilisateur, Role
from app.auth import hash_password, verify_password, create_access_token
from app.dependencies import get_current_user
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
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

    role = db.execute(text("""
        SELECT id FROM roles WHERE nom = 'proprietaire' LIMIT 1
    """)).fetchone()

    if not role:
        raise HTTPException(status_code=400,
            detail="Rôle propriétaire introuvable")

    entreprise_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO entreprises (id, nom, email)
        VALUES (:id, :nom, :email)
    """), {
        "id": entreprise_id,
        "nom": f"Entreprise {data.nom}",
        "email": data.email
    })

    ferme_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO fermes (id, nom, entreprise_id)
        VALUES (:id, :nom, :eid)
    """), {
        "id": ferme_id,
        "nom": data.nom_ferme,
        "eid": entreprise_id
    })

    user_id = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO utilisateurs (
            id, nom, email, mot_de_passe,
            role_id, entreprise_id, ferme_id, actif
        )
        VALUES (
            :id, :nom, :email, :mdp,
            :role_id, :eid, :fid, true
        )
    """), {
        "id": user_id,
        "nom": data.nom.strip(),
        "email": data.email.strip().lower(),
        "mdp": hash_password(data.mot_de_passe),
        "role_id": role.id,
        "eid": entreprise_id,
        "fid": ferme_id,
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
        "ferme_id": ferme_id
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
        "entreprise_id": str(result.entreprise_id),
        "ferme_id": str(result.ferme_id),
    }

@router.get("/activer/{email}")
def activer_compte(email: str, db: Session = Depends(get_db)):
    db.execute(text("""
        UPDATE utilisateurs SET actif = true WHERE email = :email
    """), {"email": email.lower()})
    db.commit()
    return {"success": True, "message": f"Compte {email} activé"}

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