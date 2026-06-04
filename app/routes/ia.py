from fastapi import APIRouter, Depends, HTTPException
from app.dependencies import get_current_user
from pydantic import BaseModel, Field
from typing import Optional
import os, httpx

router = APIRouter(prefix="/ia", tags=["IA"])

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
MODEL = "claude-sonnet-4-5"
MAX_TOKENS = 600

class AnalyseRequest(BaseModel):
    prompt: str = Field(min_length=10, max_length=8000)
    contexte: Optional[str] = Field(default="", max_length=2000)
    max_tokens: Optional[int] = Field(default=MAX_TOKENS, ge=50, le=2000)

@router.post("/analyser")
async def analyser(
    req: AnalyseRequest,
    current_user=Depends(get_current_user)
):
    if not ANTHROPIC_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="Service IA non configuré. Contactez l'administrateur."
        )

    system = (
        "Tu es Kewere IA, l'assistant avicole de Kewere Aissa Smart. "
        "Tu es expert en aviculture au Sénégal et en Afrique de l'Ouest. "
        "Réponds toujours en français, sois concis, précis et actionnable. "
        "Utilise des emojis pour structurer. " + (req.contexte or "")
    ).strip()

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            ANTHROPIC_URL,
            headers={
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": MODEL,
                "max_tokens": req.max_tokens,
                "system": system,
                "messages": [{"role": "user", "content": req.prompt}],
            },
        )

    if resp.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail="Service IA temporairement indisponible"
        )

    data = resp.json()
    texte = data.get("content", [{}])[0].get("text", "")
    if not texte:
        raise HTTPException(status_code=502, detail="Réponse IA vide")

    return {"reponse": texte}
