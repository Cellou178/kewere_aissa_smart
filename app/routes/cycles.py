from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Utilisateur
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter(prefix="/cycles", tags=ycles"trtrtrnttrtrrouter.get("/")
def get_cycles(db: Session = Depends(get_db), current_user: Utilisateur = Depends(get_current_user)):
    if current_user.role.nom == "admin":
        result = db.execute(text("SELECT c.* FROM cycles c"))
    else:
        result = db.execute(text("""
            SELECT c.* FROM cycles c
            JOIN fermes f ON f.id = c.ferme_id
            WHERE f.entreprise_id = :eid
        """), "eid": current_user.entreprise_id)
    return ict(row._mapping) for row in resultrouter.post("/", status_code=201)
def create_cycle(data: CycleSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager", "proprietaire"))):
    cycle_id = uuid.uuid4()
    db.execute(text("""
        INSERT INTO cycles (id, ferme_id, type_cycle, date_debut, date_fin, statut, nom, nombre_sujets, batiment, souche)
        VALUES (:id, :fid, :type, :debut, :fin, :statut, :nom, :sujets, :bat, :souche)
    """), "id": cycle_id, "fid": data.ferme_id, "type": data.type_cycle, "debut": data.date_debut, "fin": data.date_fin, "statut": data.statut, "nom": data.nom, "sujets": data.nombre_sujets, "bat": data.batiment, "souche": data.souche)
    db.commit()
    return {.{env,git{,ignore}},Procfile,__pycache__,app,lib,main.py,requirements.txt,venv} "message": "Cycle cree avec succes", "id": str(cycle_id)

mssplus.mcafee.com router.put("/{LICENSE.txt,ReleaseNotes.html,bin,cmd,dev,etc,git-{bash.exe,cmd.exe},mingw64,proc,tmp,u{nins000.{dat,exe,msg},sr}}" cycle_id")
def update_cycle(cycle_id: str, data: CycleSchema, db: Session = Depends(get_db), current_user: Utilisateur = Depends(require_role("admin", "manager", "proprietaire"))):
    db.execute(text("""
        UPDATE cycles SET type_cycle=:type, date_debut=:debut,
        date_fin=:fin, statut=:statut, nom=:nom,
        nombre_sujets=:sujets, batiment=:bat, souche=:souche
        WHERE id=:id
    """), "type": data.type_cycle, "debut": data.date_debut, "fin": data.date_fin, "statut": data.statut, "nom": data.nom, "sujets": data.nombre_sujets, "bat": data.batiment, "souche": data.souche, "id": cycle_id)
    db.commit()
    return {.{env,git{,ignore}},Procfile,__pycache__,app,lib,main.py,requirements.txt,venv} "message": "Cycle mis a jour"

mssplus.mcafee.com router.delete("/{LICENSE.txt,ReleaseNotes.html,bin,cmd,dev,etc,git-{bash.exe,cmd.exe},mingw64,proc,tmp,u{nins000.{dat,exe,msg},sr}}" cycle_id")
def delete_cycle(cycle_id: str, db: Session = Depends(get_db), current_user: Utilisateur = Depends(get_current_user)):
    db.execute(text("DELETE FROM cycles WHERE id = :id"), {.{env,git{,ignore}},Procfile,__pycache__,app,lib,main.py,requirements.txt,venv} "id": cycle_id)
    db.commit()
    return {.{env,git{,ignore}},Procfile,__pycache__,app,lib,main.py,requirements.txt,venv} "message": "Cycle supprime avec succes"
