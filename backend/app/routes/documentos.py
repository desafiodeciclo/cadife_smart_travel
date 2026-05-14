"""
Documentos — Canonical PT routes (parity gap §3.11)
====================================================
Canonical Portuguese paths for the documents resource. Mirrors the legacy
EN router (`routes/documents.py`) but uses /leads/{lead_id}/documentos
to align with `specs/spec.md` §5.6 and the rest of the domain (
`/leads`, `/propostas`, `/agenda`).

Both routers register against the same `DocumentoService`, so the EN paths
and the PT paths are functionally identical. The EN router is marked as
deprecated in OpenAPI; this PT router is the canonical one going forward.

Drop plan: when telemetry shows the EN paths receive zero traffic for 7
consecutive days (tracked via the `deprecated_path` log key), the EN router
can be removed.
"""

import uuid
from typing import List

import structlog
from fastapi import APIRouter, Depends, File, Form, UploadFile, status
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
    tags=["Documentos"],
)


def get_documento_service(db: AsyncSession = Depends(get_db)) -> DocumentoService:
    """Dependency provider — same wiring as the legacy EN router."""
    repo = DocumentoRepository(db)
    lead_repo = LeadRepository(db)
    storage = S3StorageAdapter()
    return DocumentoService(repo, lead_repo, storage)


@router.post(
    "/{lead_id}/documentos",
    response_model=DocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload de documento (canônico PT)",
    description=(
        "Upload de um documento (PDF/imagem) para um lead. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/documents`."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)
async def upload_documento(
    lead_id: uuid.UUID,
    categoria: DocumentoCategoria = Form(...),
    file: UploadFile = File(...),
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    return await service.upload_document(
        lead_id=lead_id,
        file=file,
        categoria=categoria,
        enviado_por=current_user.id,
        user_role=current_user.perfil,
        user_phone=current_user.telefone,
    )


@router.get(
    "/{lead_id}/documentos",
    response_model=List[DocumentoResponse],
    summary="Listar documentos do lead (canônico PT)",
    description=(
        "Lista todos os documentos ativos de um lead com URLs assinadas para download. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/documents`."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)
async def list_documentos(
    lead_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    return await service.list_documents(
        lead_id=lead_id,
        user_id=current_user.id,
        user_role=current_user.perfil,
        user_phone=current_user.telefone,
    )


@router.delete(
    "/{lead_id}/documentos/{documento_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-delete de documento (canônico PT)",
    description=(
        "Marca documento como deletado. Apenas consultores ou admins. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/documents/{documento_id}`."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)
async def delete_documento(
    lead_id: uuid.UUID,
    documento_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    await service.delete_document(
        documento_id=documento_id,
        user_id=current_user.id,
        user_role=current_user.perfil,
    )
