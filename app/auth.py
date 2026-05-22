from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv
from fastapi import HTTPException, status
import os

# ==========================================
# LOAD ENV
# ==========================================
load_dotenv()

# ==========================================
# CONFIG JWT
# ==========================================
SECRET_KEY = os.getenv(
    "SECRET_KEY",
    "CHANGE_THIS_SECRET_KEY_IN_PRODUCTION_2026"
)

ALGORITHM = os.getenv(
    "ALGORITHM",
    "HS256"
)

ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
)

# ==========================================
# PASSWORD HASH CONFIG
# ==========================================
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

# ==========================================
# HASH PASSWORD
# ==========================================
def hash_password(password: str) -> str:

    if len(password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Mot de passe trop court"
        )

    return pwd_context.hash(password[:72])


# ==========================================
# VERIFY PASSWORD
# ==========================================
def verify_password(
    plain_password: str,
    hashed_password: str
) -> bool:

    try:
        return pwd_context.verify(
            plain_password[:72],
            hashed_password
        )

    except Exception:
        return False


# ==========================================
# CREATE JWT TOKEN
# ==========================================
def create_access_token(data: dict) -> str:

    to_encode = data.copy()

    expire = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access_token"
    })

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return encoded_jwt


# ==========================================
# DECODE JWT TOKEN
# ==========================================
def decode_access_token(token: str):

    try:

        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        # Vérifier expiration
        exp = payload.get("exp")

        if exp is None:
            return None

        return payload

    except JWTError:
        return None

    except Exception:
        return None


# ==========================================
# VERIFY TOKEN HELPER
# ==========================================
def verify_token(token: str):

    payload = decode_access_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré"
        )

    return payload