import uuid
from typing import List

import structlog
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DocumentoCategoria
from app.infrastructure.persistence.repositories.documento_repository import DocumentoRepository
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.security.dependencies import RequiresRole, get_current_user, get_db
from app.presentation.schemas.documento_schema import DocumentoResponse
from app.services.documento_service import DocumentoService

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Documentos"],
)


def get_documento_service(db: AsyncSession = Depends(get_db)) -> DocumentoService:
    """Dependency provider for DocumentoService."""
    repo = DocumentoRepository(db)
    storage = S3StorageAdapter()
    return DocumentoService(repo, storage)


@router.post(
    "/{lead_id}/documents",
    response_model=DocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def upload_document(
    lead_id: uuid.UUID,
    categoria: DocumentoCategoria = Form(...),
    file: UploadFile = File(...),
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    """
    Uploads a travel document (PDF/Image) for a specific lead.
    Restricted to agency staff (consultants/admins).
    """
    return await service.upload_document(
        lead_id=lead_id,
        file=file,
        categoria=categoria,
        enviado_por=current_user.id
    )


@router.get(
    "/{lead_id}/documents",
    response_model=List[DocumentoResponse],
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)
async def list_documents(
    lead_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    """
    Lists all active documents for a lead.
    Includes temporary signed URLs for secure access.
    """
    return await service.list_documents(lead_id)


@router.delete(
    "/{lead_id}/documents/{documento_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)
async def delete_document(
    lead_id: uuid.UUID,
    documento_id: uuid.UUID,
    service: DocumentoService = Depends(get_documento_service),
    current_user=Depends(get_current_user),
):
    """
    Soft deletes a document. Only consultants or admins can perform this.
    """
    await service.delete_document(
        documento_id=documento_id,
        user_id=current_user.id,
        user_role=current_user.perfil
    )
