"""
Documents — Legacy EN routes (DEPRECATED)
==========================================
Kept for backwards compatibility with consumers that still call the
English paths `/leads/{lead_id}/documents`. Canonical paths are now in
`routes/documentos.py` (PT).

All endpoints in this router are marked `deprecated=True` in OpenAPI and
emit a `deprecated_path` log entry on every request so we can track usage
and decide when to remove the router safely (gap §3.11 / §4.1).
"""

import uuid
from typing import List

import structlog
from fastapi import APIRouter, Depends, File, Form, Request, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DocumentoCategoria
from app.infrastructure.persistence.repositories.documento_repository import (
    DocumentoRepository,
)
from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_db,
)
from app.presentation.schemas.documento_schema import DocumentoResponse
from app.services.documento_service import DocumentoService

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Documentos (deprecated EN)"],
)


def get_documento_service(db: AsyncSession = Depends(get_db)) -> DocumentoService:
    """Dependency provider for DocumentoService."""
    repo = DocumentoRepository(db)
    lead_repo = LeadRepository(db)
    storage = S3StorageAdapter()
    return DocumentoService(repo, lead_repo, storage)


def _log_deprecated(request: Request) -> None:
    """Single point to log usage of deprecated EN paths."""
    logger.warning(
        "deprecated_path",
        path=str(request.url.path),
        method=request.method,
        replacement=str(request.url.path).replace("/documents", "/documentos"),
        sprint_to_remove="next",
    )


@router.post(
    "/{lead_id}/documents",
    response_model=DocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    deprecated=True,
    summary="DEPRECATED — use POST /leads/{lead_id}/documentos",
    description="Path EN mantido por compatibilidade. Migre para `/leads/{lead_id}/documentos`.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)
async def upload_document(
    request: Request,
    lead_id: uuid.UUID,
    categoria: DocumentoCategoria = Form(...),
    file: UploadFile = File(...),
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    _log_deprecated(request)
    return await service.upload_document(
        lead_id=lead_id,
        file=file,
        categoria=categoria,
        enviado_por=current_user.id,
        user_role=current_user.perfil,
        user_phone=current_user.telefone,
    )


@router.get(
    "/{lead_id}/documents",
    response_model=List[DocumentoResponse],
    deprecated=True,
    summary="DEPRECATED — use GET /leads/{lead_id}/documentos",
    description="Path EN mantido por compatibilidade. Migre para `/leads/{lead_id}/documentos`.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)
async def list_documents(
    request: Request,
    lead_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    _log_deprecated(request)
    return await service.list_documents(
        lead_id=lead_id,
        user_id=current_user.id,
        user_role=current_user.perfil,
        user_phone=current_user.telefone,
    )


@router.delete(
    "/{lead_id}/documents/{documento_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    deprecated=True,
    summary="DEPRECATED — use DELETE /leads/{lead_id}/documentos/{documento_id}",
    description="Path EN mantido por compatibilidade. Migre para o path PT.",
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)
async def delete_document(
    request: Request,
    lead_id: uuid.UUID,
    documento_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    _log_deprecated(request)
    await service.delete_document(
        documento_id=documento_id,
        user_id=current_user.id,
        user_role=current_user.perfil,
    )
