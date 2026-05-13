"""
ConversationSummaryRepository — Infrastructure/Persistence Layer
================================================================
Async repository for conversation_summaries CRUD operations.
"""

import uuid
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.conversation_summary_model import (
    ConversationSummaryModel,
)


class ConversationSummaryRepository(AbstractRepository[ConversationSummaryModel]):
    model = ConversationSummaryModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_latest_by_lead(
        self, lead_id: uuid.UUID
    ) -> Optional[ConversationSummaryModel]:
        """Return the most recently generated summary for a lead."""
        stmt = (
            select(ConversationSummaryModel)
            .where(ConversationSummaryModel.lead_id == lead_id)
            .order_by(ConversationSummaryModel.gerado_em.desc())
            .limit(1)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_lead(
        self,
        lead_id: uuid.UUID,
        page: int = 1,
        limit: int = 20,
    ) -> tuple[list[ConversationSummaryModel], int]:
        """Return paginated summaries for a lead, newest first."""
        stmt = (
            select(ConversationSummaryModel)
            .where(ConversationSummaryModel.lead_id == lead_id)
            .order_by(ConversationSummaryModel.gerado_em.desc())
        )
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = (await self._session.execute(count_stmt)).scalar_one()

        stmt = stmt.offset((page - 1) * limit).limit(limit)
        result = await self._session.execute(stmt)
        return list(result.scalars().all()), total

    async def get_pending(
        self, limit: int = 50
    ) -> list[ConversationSummaryModel]:
        """Return rows with resumo_pendente=True for the retry cron job."""
        stmt = (
            select(ConversationSummaryModel)
            .where(ConversationSummaryModel.resumo_pendente.is_(True))
            .order_by(ConversationSummaryModel.gerado_em.asc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_sessao(
        self, lead_id: uuid.UUID, sessao_id: str
    ) -> Optional[ConversationSummaryModel]:
        """Return a summary by its session key (for idempotent upserts)."""
        stmt = select(ConversationSummaryModel).where(
            ConversationSummaryModel.lead_id == lead_id,
            ConversationSummaryModel.sessao_id == sessao_id,
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def create_pending(
        self, lead_id: uuid.UUID, sessao_id: str
    ) -> ConversationSummaryModel:
        """Persist a placeholder row with resumo_pendente=True as fallback."""
        row = ConversationSummaryModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            sessao_id=sessao_id,
            resumo_json=None,
            resumo_pendente=True,
            tokens_utilizados=None,
        )
        return await self.add(row)
