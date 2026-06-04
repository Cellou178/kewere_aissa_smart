from fastapi import APIRouter, Depends, HTTPException
from app.dependencies import get_current_user
import os, httpx

router = APIRouter(prefix="/meteo", tags=["Météo"])

WEATHER_KEY = os.getenv("WEATHER_KEY")
if not WEATHER_KEY:
    raise RuntimeError("Variable WEATHER_KEY manquante dans les variables d'environnement Render.")

@router.get("/")
async def get_meteo(lat: float, lon: float, current_user=Depends(get_current_user)):
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://api.openweathermap.org/data/2.5/weather",
            params={"lat": lat, "lon": lon, "appid": WEATHER_KEY,
                    "units": "metric", "lang": "fr"}
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Service météo indisponible")
    return resp.json()

@router.get("/forecast")
async def get_forecast(lat: float, lon: float, current_user=Depends(get_current_user)):
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://api.openweathermap.org/data/2.5/forecast",
            params={"lat": lat, "lon": lon, "appid": WEATHER_KEY,
                    "units": "metric", "lang": "fr", "cnt": 40}
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Service météo indisponible")
    return resp.json()
