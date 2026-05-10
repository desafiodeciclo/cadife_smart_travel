"""
Diary Repository — Infrastructure/Persistence Layer
==================================================
SQLAlchemy implementation of the IDiaryRepository.
"""

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.interfaces.repositories import IDiaryRepository
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel


class DiaryRepository(AbstractRepository[TravelDiaryEntryModel], IDiaryRepository):
    """
    SQLAlchemy implementation for travel diary persistence.
    """

    model = TravelDiaryEntryModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def create(
        self,
        lead_id: uuid.UUID,
        user_id: uuid.UUID,
        foto_url: str,
        thumb_url: str,
        nota: Optional[str] = None,
        data_entrada: Optional[datetime] = None,
    ) -> TravelDiaryEntryModel:
        """
        Creates a new diary entry.
        Uses AbstractRepository.add for basic persistence.
        """
        entry = TravelDiaryEntryModel(
            lead_id=lead_id,
            user_id=user_id,
            foto_url=foto_url,
            thumb_url=thumb_url,
            nota=nota,
            data_entrada=data_entrada or datetime.now()
        )
        return await self.add(entry)

    async def get_by_id(self, entry_id: uuid.UUID) -> Optional[TravelDiaryEntryModel]:
        """
        Retrieves an entry by ID.
        """
        return await self._session.get(self.model, entry_id)

    async def list_by_lead(
        self, lead_id: uuid.UUID, user_id: uuid.UUID, page: int = 1, limit: int = 20
    ) -> tuple[list[TravelDiaryEntryModel], int]:
        """
        Lists entries for a specific lead (trip) and user with pagination.
        """
        # Count query
        count_query = select(func.count()).select_from(self.model).where(
            self.model.lead_id == lead_id,
            self.model.user_id == user_id,
        )
        total_result = await self._session.execute(count_query)
        total = total_result.scalar() or 0

        # Data query
        query = (
            select(self.model)
            .where(self.model.lead_id == lead_id, self.model.user_id == user_id)
            .order_by(desc(self.model.data_entrada))
            .offset((page - 1) * limit)
            .limit(limit)
        )
        result = await self._session.execute(query)
        entries = list(result.scalars().all())
        return entries, total

    async def list_by_user(
        self, user_id: uuid.UUID, page: int = 1, limit: int = 20
    ) -> tuple[list[TravelDiaryEntryModel], int]:
        """
        Lists all entries for a user across all trips.
        Used for the global timeline.
        """
        # Count query
        count_query = select(func.count()).select_from(self.model).where(
            self.model.user_id == user_id
        )
        total_result = await self._session.execute(count_query)
        total = total_result.scalar() or 0

        # Data query
        query = (
            select(self.model)
            .where(self.model.user_id == user_id)
            .order_by(desc(self.model.data_entrada))
            .offset((page - 1) * limit)
            .limit(limit)
        )
        result = await self._session.execute(query)
        entries = list(result.scalars().all())
        return entries, total

    async def delete(self, entry_id: uuid.UUID) -> None:
        """
        Deletes an entry from the database.
        Note: File deletion in S3 should be handled by the Service.
        """
        entry = await self.get_by_id(entry_id)
        if entry:
            await super().delete(entry)
