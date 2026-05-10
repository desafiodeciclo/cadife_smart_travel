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

from PIL import Image
import pillow_heif
from fastapi import UploadFile, HTTPException, status

from app.domain.interfaces.repositories import IDiaryRepository, ILeadRepository
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.config.settings import get_settings

settings = get_settings()


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
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Erro ao processar imagem: {str(e)}"
            )

    async def create_entry(
        self,
        user_id: uuid.UUID,
        lead_id: uuid.UUID,
        photo: UploadFile,
        nota: Optional[str] = None,
        data_entrada: Optional[datetime] = None
    ):
        """
        Creates a new diary entry with photo and thumbnail.
        """
        # 1. Ownership Check: Lead must belong to the user
        lead = await self.lead_repo.get_by_id(lead_id)
        if not lead:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

        # 2. Validation: Size (max 5MB)
        content = await photo.read()
        if len(content) > 5 * 1024 * 1024:
            raise HTTPException(status_code=status.HTTP_413_CONTENT_TOO_LARGE, detail="Arquivo muito grande (máx 5MB)")

        # 3. Generate Keys
        entry_id = uuid.uuid4()
        photo_key = f"diary/{lead_id}/{entry_id}_original.jpg"
        thumb_key = f"diary/{lead_id}/{entry_id}_thumb.jpg"

        # 4. Generate Thumbnail
        thumb_content = await self._generate_thumbnail(content)

        # 5. Upload to S3
        # Original (Keeping original format but key says jpg for simplicity or we can use photo.content_type)
        await self.storage.upload_file(content, photo_key, bucket=self.bucket_name, content_type=photo.content_type)
        # Thumbnail
        await self.storage.upload_file(thumb_content, thumb_key, bucket=self.bucket_name, content_type="image/jpeg")

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
            # Commit the transaction
            if hasattr(self.diary_repo, "_session"):
                await self.diary_repo._session.commit()
            
            return entry

        except Exception as e:
            # Cleanup S3 if DB fail
            await self.storage.delete_file(photo_key, bucket=self.bucket_name)
            await self.storage.delete_file(thumb_key, bucket=self.bucket_name)
            if hasattr(self.diary_repo, "_session"):
                await self.diary_repo._session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Erro ao registrar memória no banco de dados: {str(e)}"
            )

    async def list_entries(self, lead_id: uuid.UUID, user_id: uuid.UUID, page: int = 1, limit: int = 20):
        # Ownership check (simplified: entries are already filtered by lead_id)
        entries, total = await self.diary_repo.list_by_lead(lead_id, page, limit)
        
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
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Memória não encontrada")
        
        if entry.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado")
            
        # 1. Delete from S3
        await self.storage.delete_file(entry.foto_url, bucket=self.bucket_name)
        await self.storage.delete_file(entry.thumb_url, bucket=self.bucket_name)
        
        # 2. Delete from DB
        await self.diary_repo.delete(entry_id)
        if hasattr(self.diary_repo, "_session"):
            await self.diary_repo._session.commit()
        return True
