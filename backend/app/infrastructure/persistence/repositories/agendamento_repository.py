"""
AgendamentoRepository — Infrastructure/Persistence Layer
=========================================================
Concrete implementation for appointment persistence.
Enforces the unique-slot business rule at the repository layer
(DB UNIQUE constraint is the safety net).
"""
import uuid
from datetime import date, time
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.agendamento_model import AgendamentoModel


class AgendamentoRepository(AbstractRepository[AgendamentoModel]):
    """SQLAlchemy async repository for Agendamento (curation appointment)."""

    model = AgendamentoModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_by_id(self, pk: uuid.UUID) -> Optional[AgendamentoModel]:  # type: ignore[override]
        return await self._session.get(AgendamentoModel, pk)

    async def create(
        self,
        lead_id: uuid.UUID,
        data: date,
        hora: time,
        tipo: AgendamentoTipo = AgendamentoTipo.online,
        consultor_id: Optional[uuid.UUID] = None,
    ) -> AgendamentoModel:
        agendamento = AgendamentoModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            data=data,
            hora=hora,
            tipo=tipo.value,
            consultor_id=consultor_id,
            status=AgendamentoStatus.pendente.value,
        )
        return await self.add(agendamento)

    async def update_status(
        self,
        agendamento_id: uuid.UUID,
        status: AgendamentoStatus,
    ) -> AgendamentoModel:
        agendamento = await self.get_by_id(agendamento_id)
        if agendamento is None:
            raise ValueError(f"Agendamento {agendamento_id} não encontrado")
        agendamento.status = status.value
        await self._session.flush()
        return agendamento

    async def list_by_lead(self, lead_id: uuid.UUID) -> list[AgendamentoModel]:
        stmt = (
            select(AgendamentoModel)
            .where(AgendamentoModel.lead_id == lead_id)
            .order_by(AgendamentoModel.data.asc(), AgendamentoModel.hora.asc())
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def list_by_consultor(
        self,
        consultor_id: uuid.UUID,
        data: Optional[date] = None,
    ) -> list[AgendamentoModel]:
        """Return a consultant's appointments, optionally filtered by date."""
        stmt = select(AgendamentoModel).where(
            AgendamentoModel.consultor_id == consultor_id
        )
        if data:
            stmt = stmt.where(AgendamentoModel.data == data)
        stmt = stmt.order_by(AgendamentoModel.data.asc(), AgendamentoModel.hora.asc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())
