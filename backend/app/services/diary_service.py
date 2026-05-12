"""
Diary Service — Application Layer
=================================
Business logic for the Travel Diary feature.
Handles S3 uploads, image processing (thumbnails), and ownership validation.
"""

import uuid
from datetime import datetime
from io import BytesIO
from typing import Optional

import structlog
from PIL import Image
import pillow_heif
from fastapi import UploadFile, HTTPException, status

from app.domain.interfaces.repositories import IDiaryRepository, ILeadRepository
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.config.settings import get_settings

settings = get_settings()
logger = structlog.get_logger()


class DiaryService:
    """
    Application service for the travel diary.
    Ensures images are processed and stored securely.
    """

    def __init__(
        self,
        diary_repo: IDiaryRepository,
        lead_repo: ILeadRepository,
        storage: S3StorageAdapter
    ):
        self.diary_repo = diary_repo
        self.lead_repo = lead_repo
        self.storage = storage
        self.bucket_name = settings.DIARY_BUCKET_NAME

    async def _generate_thumbnail(self, image_data: bytes, size=(300, 300)) -> bytes:
        """Generates a 300x300 thumbnail for the image."""
        try:
            # pillow_heif registers itself automatically when imported
            img = Image.open(BytesIO(image_data))
            
            # Convert to RGB if necessary (e.g. for HEIC/RGBA)
            if img.mode in ("RGBA", "P") or img.format == "HEIF":
                img = img.convert("RGB")
                
            img.thumbnail(size)
            
            thumb_io = BytesIO()
            img.save(thumb_io, format="JPEG", quality=85)
            return thumb_io.getvalue()
        except Exception as e:
            logger.error("thumbnail_generation_failed", error=str(e))
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Erro ao processar imagem: {str(e)}"
            )

    async def create_entry(
        self,
        user_id: uuid.UUID,
        user_phone: str,
        lead_id: uuid.UUID,
        photo: UploadFile,
        nota: Optional[str] = None,
        data_entrada: Optional[datetime] = None
    ):
        """
        Creates a new diary entry with photo and thumbnail.
        """
        # 1. Lead existence check
        lead = await self.lead_repo.get_by_id(lead_id)
        if not lead:
            logger.warning("diary_create_lead_not_found", lead_id=str(lead_id))
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lead não encontrado"
            )

        # 1.1 Ownership validation (§1.3 of updated claude_local.md)
        from app.infrastructure.security.pii_encryption import hmac_hash
        if lead.telefone_hash != hmac_hash(user_phone):
            logger.warning(
                "diary_create_ownership_violation",
                lead_id=str(lead_id),
                user_id=str(user_id),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: esta viagem não pertence a você."
            )

        # 2. Validation: Size (max 5MB)
        content = await photo.read()
        if len(content) > settings.DIARY_MAX_SIZE_MB * 1024 * 1024:
            logger.warning(
                "diary_create_file_too_large",
                lead_id=str(lead_id),
                size_bytes=len(content),
            )
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail=f"Arquivo muito grande (máx {settings.DIARY_MAX_SIZE_MB}MB)"
            )

        # 3. Generate Keys
        entry_id = uuid.uuid4()
        photo_key = f"diary/{lead_id}/{entry_id}_original.jpg"
        thumb_key = f"diary/{lead_id}/{entry_id}_thumb.jpg"

        # 4. Generate Thumbnail
        thumb_content = await self._generate_thumbnail(content)

        # 5. Upload to S3
        original_uploaded = await self.storage.upload_file(
            content, photo_key, bucket=self.bucket_name, content_type=photo.content_type or "image/jpeg"
        )
        thumb_uploaded = await self.storage.upload_file(
            thumb_content, thumb_key, bucket=self.bucket_name, content_type="image/jpeg"
        )
        if not original_uploaded or not thumb_uploaded:
            logger.error(
                "diary_s3_upload_failed",
                lead_id=str(lead_id),
                entry_id=str(entry_id),
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao persistir imagem no storage."
            )

        # 6. Persist to Database
        try:
            entry = await self.diary_repo.create(
                lead_id=lead_id,
                user_id=user_id,
                foto_url=photo_key,
                thumb_url=thumb_key,
                nota=nota,
                data_entrada=data_entrada
            )
            
            # 7. Commit transaction
            await self.diary_repo.commit()

            # 8. Hydrate presigned URLs for immediate use
            entry.foto_url = await self.storage.generate_presigned_url(
                entry.foto_url, bucket=self.bucket_name
            )
            entry.thumb_url = await self.storage.generate_presigned_url(
                entry.thumb_url, bucket=self.bucket_name
            )

            logger.info(
                "diary_entry_created",
                entry_id=str(entry.id),
                lead_id=str(lead_id),
                user_id=str(user_id),
            )
            return entry

        except Exception as e:
            # Cleanup S3 if DB fail
            logger.error(
                "diary_db_persist_failed",
                lead_id=str(lead_id),
                entry_id=str(entry_id),
                error=str(e),
            )
            await self.storage.delete_file(photo_key, bucket=self.bucket_name)
            await self.storage.delete_file(thumb_key, bucket=self.bucket_name)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail="Erro ao registrar memória no banco de dados."
            )

    async def list_entries(self, lead_id: uuid.UUID, user_id: uuid.UUID, page: int = 1, limit: int = 20):
        # Ownership check: only entries belonging to the user for this lead
        entries, total = await self.diary_repo.list_by_lead(lead_id, user_id, page, limit)
        
        # Hydrate URLs
        for entry in entries:
            entry.foto_url = await self.storage.generate_presigned_url(entry.foto_url, bucket=self.bucket_name)
            entry.thumb_url = await self.storage.generate_presigned_url(entry.thumb_url, bucket=self.bucket_name)
            
        return entries, total

    async def list_user_timeline(self, user_id: uuid.UUID, page: int = 1, limit: int = 20):
        entries, total = await self.diary_repo.list_by_user(user_id, page, limit)
        
        # Hydrate URLs
        for entry in entries:
            entry.foto_url = await self.storage.generate_presigned_url(entry.foto_url, bucket=self.bucket_name)
            entry.thumb_url = await self.storage.generate_presigned_url(entry.thumb_url, bucket=self.bucket_name)
            
        return entries, total

    async def delete_entry(self, entry_id: uuid.UUID, user_id: uuid.UUID):
        entry = await self.diary_repo.get_by_id(entry_id)
        if not entry:
            logger.warning("diary_delete_entry_not_found", entry_id=str(entry_id))
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Memória não encontrada")
        
        if entry.user_id != user_id:
            logger.warning(
                "diary_delete_ownership_violation",
                entry_id=str(entry_id),
                owner_id=str(entry.user_id),
                requester_id=str(user_id),
            )
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado")
            
        # 1. Delete from DB first (source of truth)
        await self.diary_repo.delete(entry_id)
        await self.diary_repo.commit()
        
        # 2. Delete from S3 (best effort cleanup)
        try:
            await self.storage.delete_file(entry.foto_url, bucket=self.bucket_name)
            await self.storage.delete_file(entry.thumb_url, bucket=self.bucket_name)
        except Exception as e:
            logger.error(
                "diary_s3_cleanup_failed_after_db_delete",
                entry_id=str(entry_id),
                error=str(e),
            )
        
        logger.info("diary_entry_deleted", entry_id=str(entry_id), user_id=str(user_id))
        return True
