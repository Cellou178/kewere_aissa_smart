from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from app.routes.auth import router as auth_router
from app.routes.fermes import router as fermes_router
from app.routes.employes import router as employes_router
from app.routes.cycles import router as cycles_router
from app.routes.stocks import router as stocks_router
from app.routes.donnees_journalieres import router as donnees_router
from app.routes.dashboard import router as dashboard_router
from app.routes.permissions import router as permissions_router
from app.routes.abonnements import router as abonnements_router
from app.routes.marche import router as marche_router
from app.routes.admin import router as admin_router
from app.routes.analytics import router as analytics_router
from app.routes.postes import router as postes_router
import traceback
import asyncio
import httpx
from contextlib import asynccontextmanager
from datetime import datetime
from sqlalchemy import text

async def keep_alive():
    await asyncio.sleep(60)
    while True:
        try:
            async with httpx.AsyncClient() as client:
                await client.get(
                    "https://kewere-aissa-smart.onrender.com/health",
                    timeout=10
                )
        except:
            pass
        await asyncio.sleep(600)

@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(keep_alive())
    yield

app = FastAPI(
    title="Kewere Aissa Smart API",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

@app.middleware("http")
async def catch_exceptions(request: Request, call_next):
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
        "Access-Control-Allow-Headers": "Authorization, Content-Type, Accept, Origin, X-Requested-With",
        "Access-Control-Max-Age": "3600",
    }
    if request.method == "OPTIONS":
        return JSONResponse(status_code=200, headers=cors_headers)
    try:
        response = await call_next(request)
        for key, value in cors_headers.items():
            response.headers[key] = value
        return response
    except Exception as e:
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"detail": str(e)}, headers=cors_headers)

app.include_router(auth_router)
app.include_router(abonnements_router)
app.include_router(marche_router)
app.include_router(admin_router)
app.include_router(analytics_router)
app.include_router(fermes_router)
app.include_router(employes_router)
app.include_router(cycles_router)
app.include_router(stocks_router)
app.include_router(donnees_router)
app.include_router(dashboard_router)
app.include_router(permissions_router)
app.include_router(postes_router)

@app.middleware("http")
async def abonnement_check(request: Request, call_next):
    path = request.url.path
    skip = ['/auth/', '/health', '/abonnement', '/docs', '/openapi', '/redoc']
    last_seg = path.split('/')[-1]
    if (request.method == 'OPTIONS'
            or any(path.startswith(s) for s in skip)
            or ('.' in last_seg and not last_seg.endswith('.json'))):
        return await call_next(request)

    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return await call_next(request)

    from app.auth import decode_access_token
    from app.database import SessionLocal
    payload = decode_access_token(auth_header[7:])
    if not payload:
        return await call_next(request)

    eid = payload.get('entreprise_id')
    if not eid:
        return await call_next(request)

    db = SessionLocal()
    cors = {"Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Authorization, Content-Type, Accept"}
    try:
        # Vérifier statut entreprise (suspension / résiliation)
        ent = db.execute(text("""
            SELECT statut, motif_sanction FROM entreprises WHERE id = :eid
        """), {"eid": eid}).fetchone()

        if ent and ent.statut in ('suspendu', 'resilie'):
            cle_titre = "msg_suspension_titre" if ent.statut == 'suspendu' else "msg_resiliation_titre"
            cle_corps = "msg_suspension_corps" if ent.statut == 'suspendu' else "msg_resiliation_corps"
            titre_row = db.execute(text("SELECT valeur FROM parametres WHERE cle = :c"), {"c": cle_titre}).fetchone()
            corps_row = db.execute(text("SELECT valeur FROM parametres WHERE cle = :c"), {"c": cle_corps}).fetchone()
            return JSONResponse(status_code=403, headers=cors, content={
                "detail": "ENTREPRISE_SANCTIONNEE",
                "statut": ent.statut,
                "titre": titre_row.valeur if titre_row else "Accès refusé",
                "message": corps_row.valeur if corps_row else "Votre compte est suspendu.",
                "motif": ent.motif_sanction or ""
            })

        # Vérifier abonnement expiré
        db.execute(text("""
            UPDATE abonnements SET statut = 'expire'
            WHERE entreprise_id = :eid
              AND date_fin IS NOT NULL AND date_fin < NOW()
              AND statut = 'actif'
        """), {"eid": eid})
        db.commit()
        row = db.execute(text("""
            SELECT statut FROM abonnements
            WHERE entreprise_id = :eid
            ORDER BY created_at DESC LIMIT 1
        """), {"eid": eid}).fetchone()
        if row and row.statut == 'expire':
            return JSONResponse(status_code=402,
                content={"detail": "ABONNEMENT_EXPIRE"}, headers=cors)
    except Exception:
        pass
    finally:
        db.close()
    return await call_next(request)

@app.get("/health")
@app.head("/health")
def health():
    return {"status": "ok"}

# Servir l'app Flutter web
WEB_DIR = os.path.join(os.path.dirname(__file__), "web")
if os.path.exists(WEB_DIR):
    app.mount("/", StaticFiles(directory=WEB_DIR, html=True), name="web")