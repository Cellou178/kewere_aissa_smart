from fastapi import APIRouter, Depends, HTTPException, status
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

# ==========================================
# SCHEMAS
# ==========================================
class RegisterSchema(BaseModel):

    nom: str = Field(
        min_length=2,
        max_length=100
    )

    email: EmailStr

    mot_de_passe: str = Field(
        min_length=6,
        max_length=100
    )

    telephone: Optional[str] = Field(
        default=None,
        min_length=8,
        max_length=20
    )

    nom_ferme: Optional[str] = Field(
        default="Ma Ferme",
        min_length=2,
        max_length=100
    )


class TokenSchema(BaseModel):
    access_token: str
    token_type: str


# ==========================================
# REGISTER
# ==========================================
@router.post("/register", status_code=201)
def register(
    data: RegisterSchema,
    db: Session = Depends(get_db)
):

    # Vérifier email
    existing = db.query(Utilisateur).filter(
        Utilisateur.email == data.email
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Email déjà utilisé"
        )

    # Récupérer rôle propriétaire
    role = db.query(Role).filter(
        Role.nom == "proprietaire"
    ).first()

    if not role:
        raise HTTPException(
            status_code=400,
            detail="Rôle propriétaire introuvable"
        )

    # ==========================================
    # CRÉER ENTREPRISE
    # ==========================================
    entreprise_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO entreprises (
            id,
            nom
        )
        VALUES (
            :id,
            :nom
        )
    """), {
        "id": entreprise_id,
        "nom": f"Entreprise {data.nom}"
    })

    # ==========================================
    # CRÉER FERME
    # ==========================================
    ferme_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO fermes (
            id,
            nom,
            entreprise_id
        )
        VALUES (
            :id,
            :nom,
            :eid
        )
    """), {
        "id": ferme_id,
        "nom": data.nom_ferme,
        "eid": entreprise_id
    })

    # ==========================================
    # CRÉER UTILISATEUR
    # ==========================================
    user = Utilisateur(
        id=uuid.uuid4(),
        nom=data.nom.strip(),
        email=data.email.strip().lower(),
        mot_de_passe=hash_password(data.mot_de_passe),
        role_id=role.id,
        entreprise_id=uuid.UUID(entreprise_id),
        ferme_id=uuid.UUID(ferme_id),
        telephone=data.telephone.strip() if data.telephone else None
    )

    db.add(user)

    db.commit()
    db.refresh(user)

    return {
        "success": True,
        "message": "Compte créé avec succès",
        "id": str(user.id),
        "entreprise_id": entreprise_id,
        "ferme_id": ferme_id
    }


# ==========================================
# LOGIN
# ==========================================
@router.post("/login", response_model=TokenSchema)
def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):

    # Recherche email
    user = db.query(Utilisateur).filter(
        Utilisateur.email == form.username.lower()
    ).first()

    # Vérification
    if not user or not verify_password(
        form.password,
        user.mot_de_passe
    ):
        raise HTTPException(
            status_code=401,
            detail="Email ou mot de passe incorrect"
        )

    # Vérifier actif
    if not user.actif:
        raise HTTPException(
            status_code=403,
            detail="Compte désactivé"
        )

    # JWT TOKEN
    token = create_access_token({
        "sub": user.email,
        "role": user.role.nom,
        "uid": str(user.id),
        "entreprise_id": str(user.entreprise_id),
        "ferme_id": str(user.ferme_id)
    })

    return {
        "access_token": token,
        "token_type": "bearer"
    }


# ==========================================
# CURRENT USER
# ==========================================
@router.get("/me")
def me(
    current_user: Utilisateur = Depends(get_current_user)
):

    return {
        "id": str(current_user.id),
        "nom": current_user.nom,
        "email": current_user.email,
        "telephone": current_user.telephone,
        "role": current_user.role.nom,
        "entreprise_id": str(current_user.entreprise_id),
        "ferme_id": str(current_user.ferme_id),
        "actif": current_user.actif
    }