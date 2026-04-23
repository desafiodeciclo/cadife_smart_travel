"""
LeadRepository — Infrastructure/Persistence Layer
==================================================
Concrete implementation of ILeadRepository using SQLAlchemy async.
The Application layer never imports this class directly — it receives
the interface ILeadRepository via dependency injection.

Data Mapper: ORM model (LeadModel) ↔ Domain-compatible dict/object.
Since Lead domain entity is currently represented by the ORM model
(transitional phase), _to_entity returns the model directly. When
pure domain entities are introduced, only _to_entity needs updating.
"""
import uuid
from typing import Optional

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadScore, LeadStatus
from app.domain.interfaces.repositories import ILeadRepository
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.lead_model import LeadModel


class LeadRepository(AbstractRepository[LeadModel], ILeadRepository):
    """
    SQLAlchemy async implementation of ILeadRepository.
    Inherits generic CRUD from AbstractRepository and implements
    domain-specific query methods from ILeadRepository.
    """

    model = LeadModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    # ── ILeadRepository implementation ──────────────────────────────────────

    async def get_by_id(self, lead_id: uuid.UUID) -> Optional[LeadModel]:  # type: ignore[override]
        return await self._session.get(LeadModel, lead_id)

    async def get_by_phone(self, phone: str) -> Optional[LeadModel]:
        stmt = select(LeadModel).where(LeadModel.telefone == phone)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        telefone: str,
        nome: Optional[str] = None,
        origem: str = "whatsapp",
    ) -> LeadModel:
        lead = LeadModel(
            id=uuid.uuid4(),
            telefone=telefone,
            nome=nome,
            origem=origem,
            status=LeadStatus.novo.value,
        )
        return await self.add(lead)

    async def update_status(self, lead_id: uuid.UUID, status: LeadStatus) -> LeadModel:
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.status = status.value
        await self._session.flush()
        return lead

    async def update_score(self, lead_id: uuid.UUID, score: LeadScore) -> LeadModel:
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.score = score.value
        await self._session.flush()
        return lead

    async def list_all(
        self,
        status: Optional[str] = None,
        score: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        limit: int = 20,
    ) -> tuple[list[LeadModel], int]:
        """
        Paginated lead list with optional filters.
        Returns (items, total_count).
        """
        stmt = select(LeadModel).where(LeadModel.is_archived.is_(False))

        if status:
            stmt = stmt.where(LeadModel.status == status)
        if score:
            stmt = stmt.where(LeadModel.score == score)
        if search:
            pattern = f"%{search}%"
            stmt = stmt.where(
                or_(
                    LeadModel.nome.ilike(pattern),
                    LeadModel.telefone.ilike(pattern),
                )
            )

        # Count query
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_result = await self._session.execute(count_stmt)
        total: int = total_result.scalar_one()

        # Pagination
        offset = (page - 1) * limit
        stmt = stmt.order_by(LeadModel.criado_em.desc()).offset(offset).limit(limit)
        result = await self._session.execute(stmt)
        items = list(result.scalars().all())

        return items, total

    async def soft_delete(self, lead_id: uuid.UUID) -> None:
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.is_archived = True
        await self._session.flush()
