from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/sante", tags=["Santé"])

# Maladies courantes aviculture sénégal
MALADIES_COURANTES = [
    "Newcastle", "Gumboro", "Marek", "Bronchite infectieuse",
    "Mycoplasmose", "Coccidiose", "Salmonellose", "Typhose",
    "Variole aviaire", "Autre"
]

class VaccinSchema(BaseModel):
    cycle_id: str
    vaccin: str
    maladie: str
    age_jours: int
    voie: Optional[str] = "eau"     # eau | oculaire | spray | injection
    lot: Optional[str] = None
    dose: Optional[str] = None
    notes: Optional[str] = None

class TraitementSchema(BaseModel):
    cycle_id: str
    produit: str
    motif: str
    age_jours: int
    duree_jours: int = 3
    posologie: Optional[str] = None
    notes: Optional[str] = None

class MortaliteCauseSchema(BaseModel):
    cycle_id: str
    date_releve: str
    nombre: int
    cause: str
    symptomes: Optional[str] = None
    mesures_prises: Optional[str] = None


# ── VACCINATIONS ─────────────────────────────────────────────
@router.get("/vaccinations/{cycle_id}")
def get_vaccinations(cycle_id: str, db: Session = Depends(get_db),
                     current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT v.* FROM vaccinations v
        JOIN cycles c ON c.id = v.cycle_id
        JOIN fermes f ON f.id = c.ferme_id
        WHERE v.cycle_id = :cid AND f.entreprise_id = :eid
        ORDER BY v.age_jours ASC
    """), {"cid": cycle_id, "eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/vaccinations", status_code=201)
def creer_vaccination(data: VaccinSchema, db: Session = Depends(get_db),
                       current_user: Utilisateur = Depends(get_current_user)):
    vid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO vaccinations
            (id, cycle_id, vaccin, maladie, age_jours, voie, lot, dose, notes)
        VALUES (:id, :cid, :vaccin, :maladie, :age, :voie, :lot, :dose, :notes)
    """), {"id": vid, "cid": data.cycle_id, "vaccin": data.vaccin,
           "maladie": data.maladie, "age": data.age_jours,
           "voie": data.voie, "lot": data.lot,
           "dose": data.dose, "notes": data.notes})
    db.commit()
    return {"message": "Vaccination enregistrée", "id": vid}

@router.delete("/vaccinations/{vid}")
def supprimer_vaccination(vid: str, db: Session = Depends(get_db),
                           current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("DELETE FROM vaccinations WHERE id = :id"), {"id": vid})
    db.commit()
    return {"message": "Vaccination supprimée"}


# ── TRAITEMENTS ──────────────────────────────────────────────
@router.get("/traitements/{cycle_id}")
def get_traitements(cycle_id: str, db: Session = Depends(get_db),
                    current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT t.* FROM traitements t
        JOIN cycles c ON c.id = t.cycle_id
        JOIN fermes f ON f.id = c.ferme_id
        WHERE t.cycle_id = :cid AND f.entreprise_id = :eid
        ORDER BY t.age_jours ASC
    """), {"cid": cycle_id, "eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/traitements", status_code=201)
def creer_traitement(data: TraitementSchema, db: Session = Depends(get_db),
                      current_user: Utilisateur = Depends(get_current_user)):
    tid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO traitements
            (id, cycle_id, produit, motif, age_jours, duree_jours, posologie, notes)
        VALUES (:id, :cid, :prod, :motif, :age, :dur, :pos, :notes)
    """), {"id": tid, "cid": data.cycle_id, "prod": data.produit,
           "motif": data.motif, "age": data.age_jours,
           "dur": data.duree_jours, "pos": data.posologie, "notes": data.notes})
    db.commit()
    return {"message": "Traitement enregistré", "id": tid}

@router.delete("/traitements/{tid}")
def supprimer_traitement(tid: str, db: Session = Depends(get_db),
                          current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("DELETE FROM traitements WHERE id = :id"), {"id": tid})
    db.commit()
    return {"message": "Traitement supprimé"}


# ── MORTALITÉ PAR CAUSE ──────────────────────────────────────
@router.get("/mortalite/{cycle_id}")
def get_mortalite_causes(cycle_id: str, db: Session = Depends(get_db),
                          current_user: Utilisateur = Depends(get_current_user)):
    rows = db.execute(text("""
        SELECT m.* FROM mortalite_causes m
        JOIN cycles c ON c.id = m.cycle_id
        JOIN fermes f ON f.id = c.ferme_id
        WHERE m.cycle_id = :cid AND f.entreprise_id = :eid
        ORDER BY m.date_releve DESC
    """), {"cid": cycle_id, "eid": current_user.entreprise_id}).fetchall()
    return [dict(r._mapping) for r in rows]

@router.post("/mortalite", status_code=201)
def enregistrer_mortalite_cause(data: MortaliteCauseSchema,
                                  db: Session = Depends(get_db),
                                  current_user: Utilisateur = Depends(get_current_user)):
    mid = str(uuid.uuid4())
    db.execute(text("""
        INSERT INTO mortalite_causes
            (id, cycle_id, date_releve, nombre, cause, symptomes, mesures_prises)
        VALUES (:id, :cid, :date, :nb, :cause, :symp, :mesures)
    """), {"id": mid, "cid": data.cycle_id, "date": data.date_releve,
           "nb": data.nombre, "cause": data.cause,
           "symp": data.symptomes, "mesures": data.mesures_prises})
    db.commit()
    return {"message": "Mortalité enregistrée", "id": mid}


# ── LISTE MALADIES RÉFÉRENCE ─────────────────────────────────
@router.get("/maladies")
def get_maladies(current_user: Utilisateur = Depends(get_current_user)):
    return {"maladies": MALADIES_COURANTES}
