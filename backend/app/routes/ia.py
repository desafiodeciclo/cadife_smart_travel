from typing import Optional
import uuid

from fastapi import APIRouter
from pydantic import BaseModel

from app.models.briefing import calculate_completude
from app.services import ai_service, rag_service
from app.services.domain_validator import BriefingValidator, ValidationResult

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


@router.post("/processar", response_model=ProcessarResponse)
async def processar_mensagem(body: ProcessarRequest):
    # 1. Extrair briefing
    extracted = await ai_service.extract_briefing([{"role": "user", "content": body.message}])
    completude = calculate_completude(extracted.model_dump())

    # 2. Validar domínio
    validation = _validator.validate(extracted)

    # 3. Gerar resposta (com ou sem erros de validação)
    if not validation.is_valid:
        response = await ai_service.process_message(
            body.phone, body.message, validation_errors=validation.errors
        )
    else:
        response = await ai_service.process_message(body.phone, body.message)

    return ProcessarResponse(
        response=response,
        lead_id=body.lead_id,
        briefing_updated=validation.is_valid and completude > 0,
        completude_pct=completude,
        validation_passed=validation.is_valid,
        validation_errors=validation.errors,
    )


@router.post("/extrair-briefing", response_model=ExtrairBriefingResponse)
async def extrair_briefing(body: ExtrairBriefingRequest):
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


@router.get("/status")
async def ia_status():
    return {
        "status": "ok",
        "model": "gpt-4o-mini",
        "rag_documents": rag_service.get_rag_document_count(),
        "vector_db": "chromadb",
        "domain_validator": "active",
    }
