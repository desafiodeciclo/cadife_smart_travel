import uuid
from typing import List, Optional
from datetime import datetime, timezone

import structlog
from fastapi import UploadFile, HTTPException, status

from app.domain.entities.enums import DocumentoCategoria
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.persistence.repositories.documento_repository import DocumentoRepository
from app.models.documento import Documento
from app.infrastructure.config.settings import get_settings
from app.services.fcm_service import send_push_notification

logger = structlog.get_logger()
settings = get_settings()


class DocumentoService:
    """
    Application service for managing travel documents.
    Orchestrates persistence, storage and notifications.
    """

    def __init__(
        self,
        repository: DocumentoRepository,
        storage_adapter: S3StorageAdapter
    ):
        self.repository = repository
        self.storage_adapter = storage_adapter

    async def upload_document(
        self,
        lead_id: uuid.UUID,
        file: UploadFile,
        categoria: DocumentoCategoria,
        enviado_por: uuid.UUID
    ) -> Documento:
        """
        Uploads a document to S3 and records metadata in DB.
        Includes validations for file type and size (§1.2 of claude_local.md).
        """
        # 1. Validation: Size (max 10MB)
        # We read the content to get the actual size, but we could also check Content-Length header first
        content = await file.read()
        size = len(content)
        if size > settings.DOCUMENTS_MAX_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Arquivo muito grande. Limite: {settings.DOCUMENTS_MAX_SIZE_MB}MB"
            )

        # 2. Validation: Type (PDF or Image)
        allowed_types = ["application/pdf", "image/jpeg", "image/png", "image/webp"]
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tipo de arquivo não permitido. Use PDF ou imagens (JPEG, PNG, WebP)."
            )

        # 3. Generate S3 Key
        # Pattern: documents/{lead_id}/{uuid}_{filename}
        doc_id = uuid.uuid4()
        # Clean filename to avoid S3 issues (basic)
        safe_filename = file.filename.replace(" ", "_")
        s3_key = f"documents/{lead_id}/{doc_id}_{safe_filename}"

        # 4. Upload to S3
        success = await self.storage_adapter.upload_file(
            file_content=content,
            object_key=s3_key,
            content_type=file.content_type
        )
        if not success:
            logger.error("s3_upload_failed", lead_id=str(lead_id), filename=file.filename)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail="Erro ao persistir arquivo no storage de objetos."
            )

        # 5. Persist metadata in DB
        try:
            documento = await self.repository.create(
                lead_id=lead_id,
                nome=file.filename,
                s3_key=s3_key,
                categoria=categoria.value,
                tamanho_bytes=size,
                mimetype=file.content_type,
                enviado_por=enviado_por
            )
            
            # 6. Send Push Notification (Best effort)
            # Note: We need the lead's owner/client FCM token. 
            # This logic should be expanded to fetch the target user's token.
            # For now, we log the attempt.
            await send_push_notification(
                fcm_token="TARGET_TOKEN_PLACEHOLDER", # TODO: Get actual client token
                title="Novo documento disponível",
                body=f"Um novo documento ({categoria.value}) foi adicionado à sua viagem.",
                data={"type": "document_upload", "lead_id": str(lead_id)}
            )

            logger.info("document_uploaded", lead_id=str(lead_id), doc_id=str(documento.id))
            return documento

        except Exception as e:
            # Cleanup S3 if DB fail (Atomic Upload Rule §22.5)
            await self.storage_adapter.delete_file(s3_key)
            logger.error("db_persist_failed_cleanup_s3", error=str(e), exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao registrar metadados do documento."
            )

    async def list_documents(self, lead_id: uuid.UUID) -> List[Documento]:
        """
        Lists documents with freshly generated signed URLs (1h expiration).
        """
        documentos = await self.repository.list_by_lead(lead_id)
        
        # Hydrate with signed URLs
        for doc in documentos:
            # Presigned URL generation is fast and doesn't require S3 check if key exists
            doc.url_signed = await self.storage_adapter.generate_presigned_url(doc.s3_key)
        
        return documentos

    async def delete_document(self, documento_id: uuid.UUID, user_id: uuid.UUID, user_role: str):
        """
        Soft deletes a document if RBAC rules are met.
        """
        # RBAC Check (§12.2 of updated claude_local.md)
        if user_role not in ["consultor", "admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Apenas consultores ou administradores podem deletar documentos."
            )

        documento = await self.repository.get_by_id(documento_id)
        if not documento:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="Documento não encontrado."
            )

        await self.repository.soft_delete(documento_id)
        logger.info("document_soft_deleted", documento_id=str(documento_id), user_id=str(user_id))
