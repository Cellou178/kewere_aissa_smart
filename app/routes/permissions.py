from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel

router = APIRouter(prefix="/permissions", tags=["Permissions"])

MODULES_DEFAUT = [
    {"module": "Dashboard",  "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Fermes",     "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Cycles",     "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Finance",    "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Employes",   "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Stocks",     "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Rapports",   "lecture": True,  "ecriture": True,  "suppression": True},
    {"module": "Parametres", "lecture": True,  "ecriture": True,  "suppression": True},
]

ROLES = ["admin", "proprietaire", "manager", "employe"]


def _ensure_table(db: Session):
    db.execute(text("""
        CREATE TABLE IF NOT EXISTS role_permissions (
            id SERIAL PRIMARY KEY,
            entreprise_id UUID NOT NULL,
            role VARCHAR(50) NOT NULL,
            module VARCHAR(100) NOT NULL,
            lecture BOOLEAN DEFAULT false,
            ecriture BOOLEAN DEFAULT false,
            suppression BOOLEAN DEFAULT false,
            UNIQUE(entreprise_id, role, module)
        )
    """))
    db.commit()


def _init_permissions(db: Session, entreprise_id):
    for role in ROLES:
        for m in MODULES_DEFAUT:
            db.execute(text("""
                INSERT INTO role_permissions
                    (entreprise_id, role, module, lecture, ecriture, suppression)
                VALUES
                    (:eid, :role, :module, :lecture, :ecriture, :suppression)
                ON CONFLICT (entreprise_id, role, module) DO NOTHING
            """), {
                "eid": str(entreprise_id),
                "role": role,
                "module": m["module"],
                "lecture": m["lecture"],
                "ecriture": m["ecriture"],
                "suppression": m["suppression"],
            })
    db.commit()


class PermissionUpdate(BaseModel):
    role: str
    module: str
    lecture: bool
    ecriture: bool
    suppression: bool


@router.get("/")
def get_permissions(
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    _ensure_table(db)
    _init_permissions(db, current_user.entreprise_id)

    rows = db.execute(text("""
        SELECT role, module, lecture, ecriture, suppression
        FROM role_permissions
        WHERE entreprise_id = :eid
        ORDER BY role, module
    """), {"eid": str(current_user.entreprise_id)}).fetchall()

    result = {}
    for row in rows:
        r = dict(row._mapping)
        role = r.pop("role")
        if role not in result:
            result[role] = []
        result[role].append(r)

    return result


@router.put("/")
def update_permission(
    data: PermissionUpdate,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(require_role("admin"))
):
    _ensure_table(db)

    db.execute(text("""
        INSERT INTO role_permissions
            (entreprise_id, role, module, lecture, ecriture, suppression)
        VALUES
            (:eid, :role, :module, :lecture, :ecriture, :suppression)
        ON CONFLICT (entreprise_id, role, module)
        DO UPDATE SET
            lecture = EXCLUDED.lecture,
            ecriture = EXCLUDED.ecriture,
            suppression = EXCLUDED.suppression
    """), {
        "eid": str(current_user.entreprise_id),
        "role": data.role,
        "module": data.module,
        "lecture": data.lecture,
        "ecriture": data.ecriture,
        "suppression": data.suppression,
    })
    db.commit()

    return {"success": True, "message": "Permission mise a jour"}
