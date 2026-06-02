from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from app.auth import hash_password
from app.email_service import envoyer_email
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
import uuid
import random
import string

router = APIRouter(
    prefix="/employes",
    tags=["Employés"]
)

# ==========================================
# SCHEMA VALIDATION
# ==========================================
class EmployeSchema(BaseModel):
    ferme_id: str

    nom: str = Field(
        min_length=2,
        max_length=100
    )

    role: str = Field(
        min_length=2,
        max_length=50
    )

    telephone: str = Field(
        min_length=8,
        max_length=20
    )

    salaire: float = Field(
        gt=0
    )

    email: Optional[EmailStr] = None
    adresse: Optional[str] = None


def _generer_mdp_temp() -> str:
    chars = string.ascii_letters + string.digits
    return ''.join(random.choices(chars, k=8))


def _envoyer_credentials(destinataire: str, nom: str, mdp_temp: str, nom_ferme: str):
    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;background:#f8fafc;padding:20px;border-radius:12px">
      <div style="background:linear-gradient(135deg,#1B3A6B,#16A34A);padding:20px;border-radius:10px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px">🐔 Kewere Aissa Smart</h1>
        <p style="color:rgba(255,255,255,0.8);margin:5px 0 0">Votre compte est prêt</p>
      </div>
      <div style="background:white;padding:24px;border-radius:10px;margin-top:12px">
        <h2 style="color:#1E293B;margin-top:0">Bienvenue, {nom} !</h2>
        <p style="color:#475569">Vous avez été ajouté(e) à la ferme <strong>{nom_ferme}</strong>.</p>
        <p style="color:#475569">Voici vos identifiants de connexion :</p>
        <div style="background:#f1f5f9;border-radius:10px;padding:16px;margin:16px 0">
          <p style="margin:4px 0;color:#475569"><strong>Email :</strong> {destinataire}</p>
          <p style="margin:4px 0;color:#475569"><strong>Mot de passe :</strong> <span style="font-size:18px;font-weight:900;color:#1B3A6B;letter-spacing:2px">{mdp_temp}</span></p>
        </div>
        <p style="color:#94a3b8;font-size:13px">Connectez-vous sur l'application et changez votre mot de passe dès que possible.</p>
      </div>
      <p style="text-align:center;color:#94a3b8;font-size:11px;margin-top:12px">© 2026 Kewere Aissa Smart • Sénégal</p>
    </div>
    """
    envoyer_email(destinataire, "🐔 Vos accès Kewere Aissa Smart", html)


# ==========================================
# LISTE EMPLOYÉS
# ==========================================
@router.get("/")
def get_employes(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):

    result = db.execute(text("""
        SELECT
            e.id,
            e.nom,
            e.role,
            e.telephone,
            e.salaire,
            e.ferme_id
        FROM employes e
        JOIN fermes f
            ON f.id = e.ferme_id
        WHERE f.entreprise_id = :eid
        ORDER BY e.nom ASC
    """), {
        "eid": current_user.entreprise_id
    })

    employes = [dict(row._mapping) for row in result]

    return {
        "total": len(employes),
        "items": employes
    }


# ==========================================
# CRÉER EMPLOYÉ
# ==========================================
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_employe(
    data: EmployeSchema,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager", "proprietaire")
    )
):

    # Vérifier accès ferme
    ferme = db.execute(text("""
        SELECT id, nom
        FROM fermes
        WHERE id = :fid
        AND entreprise_id = :eid
    """), {
        "fid": data.ferme_id,
        "eid": current_user.entreprise_id
    }).fetchone()

    if not ferme:
        raise HTTPException(
            status_code=403,
            detail="Accès interdit à cette ferme"
        )

    # Vérifier doublon téléphone
    existing_phone = db.execute(text("""
        SELECT id FROM employes WHERE telephone = :tel LIMIT 1
    """), {"tel": data.telephone}).fetchone()

    if existing_phone:
        raise HTTPException(status_code=400, detail="Téléphone déjà utilisé")

    emp_id = str(uuid.uuid4())

    db.execute(text("""
        INSERT INTO employes (id, ferme_id, nom, role, telephone, salaire)
        VALUES (:id, :fid, :nom, :role, :tel, :sal)
    """), {
        "id": emp_id,
        "fid": data.ferme_id,
        "nom": data.nom.strip(),
        "role": data.role.strip(),
        "tel": data.telephone.strip(),
        "sal": data.salaire
    })

    # Créer un compte utilisateur si email fourni
    compte_cree = False
    mdp_temp = None
    if data.email:
        existing_email = db.execute(text("""
            SELECT id FROM utilisateurs WHERE email = :email LIMIT 1
        """), {"email": data.email.lower()}).fetchone()

        if not existing_email:
            role_nom = data.role if data.role in ('manager', 'comptable') else 'employe'
            role_row = db.execute(text("""
                SELECT id FROM roles WHERE nom = :nom LIMIT 1
            """), {"nom": role_nom}).fetchone()

            if not role_row:
                role_row = db.execute(text("""
                    SELECT id FROM roles WHERE nom = 'employe' LIMIT 1
                """)).fetchone()

            if role_row:
                mdp_temp = _generer_mdp_temp()
                user_id = str(uuid.uuid4())
                db.execute(text("""
                    INSERT INTO utilisateurs (id, nom, email, mot_de_passe, role_id, entreprise_id, ferme_id, actif)
                    VALUES (:id, :nom, :email, :mdp, :role_id, :eid, :fid, true)
                """), {
                    "id": user_id,
                    "nom": data.nom.strip(),
                    "email": data.email.lower(),
                    "mdp": hash_password(mdp_temp),
                    "role_id": role_row.id,
                    "eid": current_user.entreprise_id,
                    "fid": data.ferme_id
                })
                compte_cree = True
                background_tasks.add_task(
                    _envoyer_credentials, data.email, data.nom.strip(), mdp_temp, ferme.nom
                )

    db.commit()

    return {
        "success": True,
        "message": "Employé créé avec succès",
        "id": emp_id,
        "compte_cree": compte_cree,
        "email_envoye": compte_cree and data.email is not None
    }


# ==========================================
# MODIFIER EMPLOYÉ
# ==========================================
@router.put("/{employe_id}")
def update_employe(
    employe_id: str,
    data: EmployeSchema,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "manager", "proprietaire")
    )
):

    # Vérifier accès ferme
    ferme = db.execute(text("""
        SELECT id
        FROM fermes
        WHERE id = :fid
        AND entreprise_id = :eid
    """), {
        "fid": data.ferme_id,
        "eid": current_user.entreprise_id
    }).fetchone()

    if not ferme:
        raise HTTPException(
            status_code=403,
            detail="Accès interdit à cette ferme"
        )

    result = db.execute(text("""
        UPDATE employes
        SET
            nom = :nom,
            role = :role,
            telephone = :tel,
            salaire = :sal
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "nom": data.nom.strip(),
        "role": data.role.strip(),
        "tel": data.telephone.strip(),
        "sal": data.salaire,
        "id": employe_id,
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Employé introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Employé mis à jour avec succès"
    }


# ==========================================
# SUPPRIMER EMPLOYÉ
# ==========================================
@router.delete("/{employe_id}")
def delete_employe(
    employe_id: str,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(
        require_role("admin", "proprietaire")
    )
):

    result = db.execute(text("""
        DELETE FROM employes
        WHERE id = :id
        AND ferme_id IN (
            SELECT id
            FROM fermes
            WHERE entreprise_id = :eid
        )
    """), {
        "id": employe_id,
        "eid": current_user.entreprise_id
    })

    db.commit()

    if result.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Employé introuvable ou accès interdit"
        )

    return {
        "success": True,
        "message": "Employé supprimé avec succès"
    }