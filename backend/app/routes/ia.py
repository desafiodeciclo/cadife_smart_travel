from typing import Optional
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends
from pydantic import BaseModel

from app.infrastructure.security.dependencies import get_current_user
from app.services import rag_service
from app.services import ai_service
from app.services.ingestion_pipeline import get_ingestion_pipeline

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


class ReindexarRequest(BaseModel):
    force: bool = False


# ---------------------------------------------------------------------------
# Existing endpoints
# ---------------------------------------------------------------------------

@router.post("/processar", response_model=ProcessarResponse)
async def processar_mensagem(body: ProcessarRequest):
    extracted = await ai_service.extract_briefing([{"role": "user", "content": body.message}])
    response = await ai_service.process_message(body.phone, body.message, briefing=extracted)
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


# ---------------------------------------------------------------------------
# Ingestion endpoints (JWT protected)
# ---------------------------------------------------------------------------

@router.post("/reindexar", dependencies=[Depends(get_current_user)])
async def reindexar_base(body: ReindexarRequest, background_tasks: BackgroundTasks):
    """
    Trigger a full knowledge-base re-ingestion in the background.

    - force=false (default): only changed/new documents are re-indexed.
    - force=true: all documents are deleted and re-embedded from scratch.

    Returns immediately with HTTP 202; actual indexing runs asynchronously.
    """
    pipeline = get_ingestion_pipeline()
    background_tasks.add_task(pipeline.ingest_all, body.force)
    return {"status": "accepted", "message": "Reindexação iniciada em background", "force": body.force}


@router.get("/ingestion-status", dependencies=[Depends(get_current_user)])
async def ingestion_status():
    """Return the current ingestion cache summary (indexed documents + chunk counts)."""
    pipeline = get_ingestion_pipeline()
    return pipeline.get_status()
