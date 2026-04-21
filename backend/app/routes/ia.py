from typing import Optional
import uuid

from fastapi import APIRouter
from pydantic import BaseModel

from app.services import ai_service, rag_service

router = APIRouter(prefix="/ia", tags=["IA"])


class ProcessarRequest(BaseModel):
    phone: str
    message: str
    lead_id: Optional[uuid.UUID] = None


class ProcessarResponse(BaseModel):
    response: str
    lead_id: Optional[uuid.UUID]
    briefing_updated: bool
    completude_pct: int


class ConversationMessage(BaseModel):
    role: str
    content: str


class ExtrairBriefingRequest(BaseModel):
    lead_id: uuid.UUID
    conversation: list[ConversationMessage]


@router.post("/processar", response_model=ProcessarResponse)
async def processar_mensagem(body: ProcessarRequest):
    response = await ai_service.process_message(body.phone, body.message)
    extracted = await ai_service.extract_briefing([{"role": "user", "content": body.message}])
    return ProcessarResponse(
        response=response,
        lead_id=body.lead_id,
        briefing_updated=extracted.completude_pct > 0,
        completude_pct=extracted.completude_pct,
    )


@router.post("/extrair-briefing")
async def extrair_briefing(body: ExtrairBriefingRequest):
    conversation = [{"role": m.role, "content": m.content} for m in body.conversation]
    briefing = await ai_service.extract_briefing(conversation)
    return briefing.model_dump()


@router.get("/status")
async def ia_status():
    return {
        "status": "ok",
        "model": "gpt-4o-mini",
        "rag_documents": rag_service.get_rag_document_count(),
        "vector_db": "chromadb",
    }
