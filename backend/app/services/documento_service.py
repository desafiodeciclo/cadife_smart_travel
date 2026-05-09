import os
import re
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

# ── Magic-byte signatures for supported file types ──────────────────────────
_MAGIC_BYTES = {
    "application/pdf": (b"%PDF",),
    "image/jpeg": (b"\xff\xd8\xff",),
    "image/png": (b"\x89PNG\r\n\x1a\n",),
    "image/webp": (b"RIFF", b"WEBP"),  # RIFF at 0, WEBP at 8
}

_ALLOWED_CONTENT_TYPES = list(_MAGIC_BYTES.keys())


def _validate_magic_bytes(content: bytes, declared_type: str) -> bool:
    """Verify that the file content starts with the expected magic bytes."""
    signatures = _MAGIC_BYTES.get(declared_type)
    if not signatures:
        return False

    if declared_type == "image/webp":
        # WebP: RIFF....WEBP (12 bytes header)
        return content.startswith(b"RIFF") and content[8:12] == b"WEBP"

    return content.startswith(signatures)


def _sanitize_filename(name: str) -> str:
    """
    Sanitize a filename for safe S3 storage.
    Removes path traversal, control chars, and dangerous symbols.
    """
    # Strip path components
    base = os.path.basename(name)
    # Replace control chars and anything outside safe whitelist
    safe = re.sub(r"[^\w.\-]", "_", base)
    # Avoid hidden files and empty names
    safe = safe.lstrip(".")
    if not safe:
        safe = "document"
    return safe


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
        Includes validations for file type, magic bytes and size (§1.2).
        """
        # 1. Validation: Size (max 10MB)
        content = await file.read()
        size = len(content)
        if size > settings.DOCUMENTS_MAX_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail=f"Arquivo muito grande. Limite: {settings.DOCUMENTS_MAX_SIZE_MB}MB"
            )

        # 2. Validation: Declared Content-Type
        if file.content_type not in _ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tipo de arquivo não permitido. Use PDF ou imagens (JPEG, PNG, WebP)."
            )

        # 3. Validation: Magic bytes (anti-spoofing)
        if not _validate_magic_bytes(content, file.content_type):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Conteúdo do arquivo não corresponde ao tipo declarado."
            )

        # 4. Generate S3 Key
        doc_id = uuid.uuid4()
        safe_filename = _sanitize_filename(file.filename)
        s3_key = f"documents/{lead_id}/{doc_id}_{safe_filename}"

        # 5. Upload to S3
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

        # 6. Persist metadata in DB
        try:
            documento = await self.repository.create(
                lead_id=lead_id,
                nome=safe_filename,
                s3_key=s3_key,
                categoria=categoria.value,
                tamanho_bytes=size,
                mimetype=file.content_type,
                enviado_por=enviado_por
            )

            # 7. Send Push Notification (Best effort)
            await send_push_notification(
                fcm_token="TARGET_TOKEN_PLACEHOLDER",  # TODO: Get actual client token
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
