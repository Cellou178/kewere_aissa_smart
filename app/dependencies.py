from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Utilisateur
from app.auth import decode_access_token

# ==========================================
# OAUTH2
# ==========================================
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/login"
)

# ==========================================
# CURRENT USER
# ==========================================
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Utilisateur:

    # Vérifier token
    payload = decode_access_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré"
        )

    # Vérifier email
    email = payload.get("sub")

    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Payload JWT invalide"
        )

    # Rechercher utilisateur
    user = db.query(Utilisateur).filter(
        Utilisateur.email == email
    ).first()

    # Vérifier utilisateur
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur introuvable"
        )

    # Vérifier compte actif
    if not user.actif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé"
        )

    return user


# ==========================================
# ROLE CHECKER
# ==========================================
def require_role(*roles: str):

    def checker(
        current_user: Utilisateur = Depends(get_current_user)
    ):

        user_role = current_user.role.nom.lower()

        allowed_roles = [
            role.lower()
            for role in roles
        ]

        if user_role not in allowed_roles:

            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Accès refusé. Rôle requis : {', '.join(roles)}"
            )

        return current_user

    return checker


# ==========================================
# OPTIONAL ADMIN CHECK
# ==========================================
def require_admin(
    current_user: Utilisateur = Depends(get_current_user)
):

    if current_user.role.nom.lower() != "admin":

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès administrateur requis"
        )

    return current_user


# ==========================================
# OPTIONAL MANAGER CHECK
# ==========================================
def require_manager(
    current_user: Utilisateur = Depends(get_current_user)
):

    allowed = [
        "admin",
        "manager"
    ]

    if current_user.role.nom.lower() not in allowed:

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès manager requis"
        )

    return current_user