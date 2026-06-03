from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Utilisateur
from pydantic import BaseModel
from typing import List, Optional
import os, httpx

router = APIRouter(prefix="/chat", tags=["Chat IA"])

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")

class MessageItem(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[MessageItem]] = []
    contexte: Optional[str] = ""

@router.post("/")
async def chat_ia(
    req: ChatRequest,
    db: Session = Depends(get_db),
    current_user: Utilisateur = Depends(get_current_user)
):
    if not ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="Clé API IA non configurée")

    system_prompt = f"""Tu es Kewere IA, l'assistant avicole intelligent de Kewere Aissa Smart.
Tu es un expert en aviculture au Sénégal et en Afrique de l'Ouest.
Réponds toujours en français, sois précis et actionnable.
Utilise des emojis pour rendre la réponse lisible. Sois concis (max 200 mots sauf si demande détaillée).

{req.contexte}"""

    messages = [{"role": m.role, "content": m.content} for m in (req.history or [])]
    messages.append({"role": "user", "content": req.message})

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": "claude-haiku-4-5-20251001",
                "max_tokens": 1000,
                "system": system_prompt,
                "messages": messages,
            },
        )

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Erreur IA")

    data = resp.json()
    reply = data["content"][0]["text"]
    return {"reply": reply}
