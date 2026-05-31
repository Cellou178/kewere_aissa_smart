from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth import router as auth_router
from app.routes.fermes import router as fermes_router
from app.routes.employes import router as employes_router
from app.routes.cycles import router as cycles_router
from app.routes.stocks import router as stocks_router
from app.routes.donnees_journalieres import router as donnees_router
from app.routes.dashboard import router as dashboard_router
from app.routes.permissions import router as permissions_router
import traceback
import asyncio
import httpx
from contextlib import asynccontextmanager

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
app.include_router(fermes_router)
app.include_router(employes_router)
app.include_router(cycles_router)
app.include_router(stocks_router)
app.include_router(donnees_router)
app.include_router(dashboard_router)
app.include_router(permissions_router)

@app.get("/")
def root():
    return {"message": "Bienvenue sur Kewere Aissa Smart API 🐔"}

@app.get("/health")
@app.head("/health")
def health():
    return {"status": "ok"}