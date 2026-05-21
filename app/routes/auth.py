from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.models import Utilisateur, Role
from app.auth import hash_password, verify_password, create_access_token
from app.dependencies import get_current_user
from pydantic import BaseModel, EmailStr
import uuid

router = APIRouter(prefix="/auth", tags=["Authentification"])

# ========== SCHEMAS ==========
class RegisterSchema(BaseModel):
    nom: str
    email: EmailStr
    mot_de_passe: str
    role: str
    entreprise_id: str

class TokenSchema(BaseModel):
    access_token: str
    token_type: str

# ========== REGISTER ==========
@router.post("/register", status_code=201)
def register(data: RegisterSchema, db: Session = Depends(get_db)):
    existing = db.query(Utilisateur).filter(Utilisateur.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    role = db.query(Role).filter(Role.nom == data.role).first()
    if not role:
        raise HTTPException(status_code=400, detail="Rôle invalide")

    user = Utilisateur(
        id=uuid.uuid4(),
        nom=data.nom,
        email=data.email,
        mot_de_passe=hash_password(data.mot_de_passe),
        role_id=role.id,
        entreprise_id=uuid.UUID(data.entreprise_id)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"message": "Compte créé avec succès", "id": str(user.id)}

# ========== LOGIN ==========
@router.post("/login", response_model=TokenSchema)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(Utilisateur).filter(Utilisateur.email == form.username).first()
    if not user or not verify_password(form.password, user.mot_de_passe):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    token = create_access_token({"sub": user.email, "role": user.role.nom})
    return {"access_token": token, "token_type": "bearer"}

# ========== ME ==========
@router.get("/me")
def me(current_user: Utilisateur = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "nom": current_user.nom,
        "email": current_user.email,
        "role": current_user.role.nom,
        "actif": current_user.actif
    }