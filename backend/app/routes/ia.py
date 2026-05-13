from typing import Optional
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, Request, Response
from pydantic import BaseModel

from app.infrastructure.security.dependencies import get_current_user
from app.models.briefing import calculate_completude
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import ai_service, rag_service
from app.services.domain_validator import BriefingValidator
from app.services.ingestion_pipeline import get_ingestion_pipeline
from app.infrastructure.security.rate_limiter import limiter
from app.core.config import get_settings

settings = get_settings()

router = APIRouter(prefix="/ia", tags=["IA"])

# Instância única do validador
_validator = BriefingValidator()


class ProcessarRequest(BaseModel):
    phone: str
    message: str
    lead_id: Optional[uuid.UUID] = None


class ProcessarResponse(BaseModel):
    response: str
    lead_id: Optional[uuid.UUID]
    briefing_updated: bool
    completude_pct: int
    validation_passed: bool
    validation_errors: list[str]


class ConversationMessage(BaseModel):
    role: str
    content: str


class ExtrairBriefingRequest(BaseModel):
    lead_id: uuid.UUID
    conversation: list[ConversationMessage]


class ExtrairBriefingResponse(BaseModel):
    briefing: dict
    completude_pct: int
    validation_passed: bool
    validation_errors: list[str]


class ReindexarRequest(BaseModel):
    force: bool = False


class IaStatusResponse(BaseModel):
    status: str
    model: str
    rag_documents: int
    vector_db: str
    domain_validator: str


class ReindexarResponse(BaseModel):
    status: str
    message: str
    force: bool


class IngestionStatusResponse(BaseModel):
    indexed_documents: int
    total_chunks: int
    documents: list[dict]


# ---------------------------------------------------------------------------
# Existing endpoints
# ---------------------------------------------------------------------------


@router.post(
    "/processar",
    response_model=ProcessarResponse,
    summary="Processar mensagem via IA",
    description=(
        "Recebe uma mensagem do cliente, extrai o briefing automaticamente e gera uma resposta contextualizada pela IA. "
        "Aplica validação de domínio e retorna métricas de completude do briefing."
    ),
    responses={
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
@limiter.limit(settings.RATE_LIMIT_IA)
async def processar_mensagem(request: Request, response: Response, body: ProcessarRequest):
    # 1. Extrair briefing
    extracted = await ai_service.extract_briefing(
        [{"role": "user", "content": body.message}]
    )
    completude = calculate_completude(extracted.model_dump())

    # 2. Validar domínio
    validation = _validator.validate(extracted)

    # 3. Gerar resposta (com ou sem erros de validação)
    if not validation.is_valid:
        response = await ai_service.process_message(
            body.phone, body.message, validation_errors=validation.errors
        )
    else:
        response = await ai_service.process_message(
            body.phone, body.message, briefing=extracted
        )

    return ProcessarResponse(
        response=response,
        lead_id=body.lead_id,
        briefing_updated=validation.is_valid and completude > 0,
        completude_pct=completude,
        validation_passed=validation.is_valid,
        validation_errors=validation.errors,
    )


@router.post(
    "/extrair-briefing",
    response_model=ExtrairBriefingResponse,
    summary="Extrair briefing de conversa",
    description="Recebe uma conversa completa e retorna os dados estruturados do briefing com validação de domínio.",
    responses={
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
@limiter.limit(settings.RATE_LIMIT_IA)
async def extrair_briefing(request: Request, response: Response, body: ExtrairBriefingRequest):
    conversation = [{"role": m.role, "content": m.content} for m in body.conversation]
    briefing = await ai_service.extract_briefing(conversation)
    completude = calculate_completude(briefing.model_dump())

    # Validar domínio
    validation = _validator.validate(briefing)

    return ExtrairBriefingResponse(
        briefing=briefing.model_dump(),
        completude_pct=completude,
        validation_passed=validation.is_valid,
        validation_errors=validation.errors,
    )


@router.get(
    "/status",
    response_model=IaStatusResponse,
    summary="Status do serviço de IA",
    description="Health check do módulo de IA retornando modelo ativo, contagem de documentos RAG e status do validador.",
)
async def ia_status() -> IaStatusResponse:
    return IaStatusResponse(
        status="ok",
        model=settings.OPENROUTER_MODEL,
        rag_documents=rag_service.get_rag_document_count(),
        vector_db="chromadb",
        domain_validator="active",
    )


# ---------------------------------------------------------------------------
# Ingestion endpoints (JWT protected)
# ---------------------------------------------------------------------------


@router.post(
    "/reindexar",
    response_model=ReindexarResponse,
    summary="Reindexar base de conhecimento",
    description=(
        "Dispara uma re-ingestão completa da base de conhecimento RAG em background. "
        "force=false: apenas documentos novos/alterados são reindexados. "
        "force=true: toda a base é apagada e reconstruída do zero. "
        "Retorna HTTP 202 imediatamente; o processamento ocorre de forma assíncrona."
    ),
    dependencies=[Depends(get_current_user)],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def reindexar_base(body: ReindexarRequest, background_tasks: BackgroundTasks) -> ReindexarResponse:
    pipeline = get_ingestion_pipeline()
    background_tasks.add_task(pipeline.ingest_all, body.force)
    return ReindexarResponse(
        status="accepted",
        message="Reindexação iniciada em background",
        force=body.force,
    )


@router.get(
    "/ingestion-status",
    response_model=IngestionStatusResponse,
    summary="Status da ingestão",
    description="Retorna o resumo do cache de ingestão atual (documentos indexados + contagem de chunks).",
    dependencies=[Depends(get_current_user)],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def ingestion_status() -> IngestionStatusResponse:
    pipeline = get_ingestion_pipeline()
    return IngestionStatusResponse(**pipeline.get_status())
