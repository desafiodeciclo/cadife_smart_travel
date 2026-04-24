"""
InteracaoRepository — Infrastructure/Persistence Layer
=======================================================
Concrete implementation for WhatsApp interaction persistence.
Provides paginated conversation history retrieval optimised by
the composite index (lead_id, timestamp).
"""
import uuid
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import TipoMensagem
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.interacao_model import InteracaoModel


class InteracaoRepository(AbstractRepository[InteracaoModel]):
    """SQLAlchemy async repository for Interacao (WhatsApp message exchange)."""

    model = InteracaoModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_by_id(self, pk: uuid.UUID) -> Optional[InteracaoModel]:  # type: ignore[override]
        return await self._session.get(InteracaoModel, pk)

    async def create(
        self,
        lead_id: uuid.UUID,
        mensagem_cliente: Optional[str] = None,
        mensagem_ia: Optional[str] = None,
        tipo_mensagem: TipoMensagem = TipoMensagem.texto,
    ) -> InteracaoModel:
        interacao = InteracaoModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            mensagem_cliente=mensagem_cliente,
            mensagem_ia=mensagem_ia,
            tipo_mensagem=tipo_mensagem.value,
        )
        return await self.add(interacao)

    async def list_by_lead(
        self,
        lead_id: uuid.UUID,
        page: int = 1,
        limit: int = 50,
    ) -> tuple[list[InteracaoModel], int]:
        """Return paginated conversation history, newest first."""
        stmt = (
            select(InteracaoModel)
            .where(InteracaoModel.lead_id == lead_id)
            .order_by(InteracaoModel.timestamp.desc())
        )
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = (await self._session.execute(count_stmt)).scalar_one()

        stmt = stmt.offset((page - 1) * limit).limit(limit)
        result = await self._session.execute(stmt)
        return list(result.scalars().all()), total
