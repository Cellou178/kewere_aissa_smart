from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.routes.auth import router as auth_router
from app.routes.fermes import router as fermes_router
from app.routes.employes import router as employes_router
from app.routes.cycles import router as cycles_router
from app.routes.stocks import router as stocks_router
from app.routes.donnees_journalieres import router as donnees_router
from app.routes.dashboard import router as dashboard_router
import traceback

app = FastAPI(
    title="Kewere Aissa Smart API",
    description="API de gestion de fermes avicoles",
    version="1.0.0"
)

@app.middleware("http")
async def catch_exceptions(request: Request, call_next):
    try:
        return await call_next(request)
    except Exception as e:
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"detail": str(e)})

app.include_router(auth_router)
app.include_router(fermes_router)
app.include_router(employes_router)
app.include_router(cycles_router)
app.include_router(stocks_router)
app.include_router(donnees_router)
app.include_router(dashboard_router)

@app.get("/")
def root():
    return {"message": "Bienvenue sur Kewere Aissa Smart API 🐔"}