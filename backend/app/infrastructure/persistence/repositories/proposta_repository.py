"""
PropostaRepository — Infrastructure/Persistence Layer
======================================================
Concrete implementation for proposal (Proposta) persistence.
Supports lifecycle transitions and filtered queries by lead and status.
"""
import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import PropostaStatus
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.proposta_model import PropostaModel


class PropostaRepository(AbstractRepository[PropostaModel]):
    """SQLAlchemy async repository for Proposta (travel proposal)."""

    model = PropostaModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_by_id(self, pk: uuid.UUID) -> Optional[PropostaModel]:  # type: ignore[override]
        return await self._session.get(PropostaModel, pk)

    async def create(
        self,
        lead_id: uuid.UUID,
        descricao: str,
        valor_estimado: Optional[Decimal] = None,
        consultor_id: Optional[uuid.UUID] = None,
    ) -> PropostaModel:
        proposta = PropostaModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            descricao=descricao,
            valor_estimado=valor_estimado,
            status=PropostaStatus.rascunho.value,
            consultor_id=consultor_id,
        )
        return await self.add(proposta)

    async def update(
        self,
        proposta_id: uuid.UUID,
        *,
        status: Optional[PropostaStatus] = None,
        descricao: Optional[str] = None,
        valor_estimado: Optional[Decimal] = None,
    ) -> PropostaModel:
        proposta = await self.get_by_id(proposta_id)
        if proposta is None:
            raise ValueError(f"Proposta {proposta_id} não encontrada")
        if status is not None:
            proposta.status = status.value
        if descricao is not None:
            proposta.descricao = descricao
        if valor_estimado is not None:
            proposta.valor_estimado = valor_estimado
        await self._session.flush()
        return proposta

    async def list_by_lead(
        self,
        lead_id: uuid.UUID,
        status: Optional[PropostaStatus] = None,
    ) -> list[PropostaModel]:
        """Return all proposals for a lead, optionally filtered by status."""
        stmt = select(PropostaModel).where(PropostaModel.lead_id == lead_id)
        if status:
            stmt = stmt.where(PropostaModel.status == status.value)
        stmt = stmt.order_by(PropostaModel.criado_em.desc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def list_by_consultor(
        self,
        consultor_id: uuid.UUID,
        status: Optional[PropostaStatus] = None,
    ) -> list[PropostaModel]:
        """Return all proposals assigned to a consultant."""
        stmt = select(PropostaModel).where(PropostaModel.consultor_id == consultor_id)
        if status:
            stmt = stmt.where(PropostaModel.status == status.value)
        stmt = stmt.order_by(PropostaModel.criado_em.desc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())
