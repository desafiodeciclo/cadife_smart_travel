"""
LeadRepository — Infrastructure/Persistence Layer
==================================================
Concrete implementation of ILeadRepository using SQLAlchemy async.
The Application layer never imports this class directly — it receives
the interface ILeadRepository via dependency injection.

Data Mapper: ORM model (Lead) ↔ Domain-compatible dict/object.
Since Lead domain entity is currently represented by the ORM model
(transitional phase), _to_entity returns the model directly. When
pure domain entities are introduced, only _to_entity needs updating.
"""

import uuid
from datetime import date
from typing import Optional

from sqlalchemy import func, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities.enums import LeadScore, LeadStatus
from app.domain.interfaces.repositories import ILeadRepository
from app.infrastructure.cache import invalidate_pattern
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.models.lead import Lead as LeadModel


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
        result = await self.add(lead)
        await invalidate_pattern("cached:*list*")
        return result

    async def update_status(self, lead_id: uuid.UUID, status: LeadStatus) -> LeadModel:
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.status = status.value
        await self._session.flush()
        await invalidate_pattern(f"cached:*{lead_id}*")
        await invalidate_pattern("cached:*list*")
        return lead

    async def update_score(self, lead_id: uuid.UUID, score: LeadScore) -> LeadModel:
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.score = score.value
        await self._session.flush()
        await invalidate_pattern(f"cached:*{lead_id}*")
        await invalidate_pattern("cached:*list*")
        return lead

    async def list_all(
        self,
        status: Optional[LeadStatus] = None,
        score: Optional[LeadScore] = None,
        destino: Optional[str] = None,
        data_inicio: Optional[date] = None,
        data_fim: Optional[date] = None,
        q: Optional[str] = None,
        page: int = 1,
        limit: int = 20,
        consultor_id: Optional[uuid.UUID] = None,
    ) -> tuple[list[LeadModel], int]:
        """
        Paginated lead list with advanced filters.
        Keeps all SQLAlchemy query logic in the Repository layer.
        """
        # Filter base: not archived and not logically deleted
        stmt = (
            select(LeadModel)
            .options(selectinload(LeadModel.briefing))
            .where(
                LeadModel.deleted_at.is_(None),
                LeadModel.is_archived.is_(False),
            )
        )

        if status:
            stmt = stmt.where(
                text(f"leads.status = '{status.value}'")
            )
        if score:
            stmt = stmt.where(
                text(f"leads.score = '{score.value}'")
            )
        if consultor_id:
            stmt = stmt.where(LeadModel.consultor_id == consultor_id)

        if destino:
            # Join with briefing to filter by destination
            from app.models.briefing import Briefing as BriefingModel
            stmt = stmt.join(LeadModel.briefing).where(
                BriefingModel.destino.ilike(f"%{destino}%")
            )

        if data_inicio:
            stmt = stmt.where(LeadModel.criado_em >= data_inicio)
        if data_fim:
            stmt = stmt.where(LeadModel.criado_em <= data_fim)

        if q:
            # PII fields (nome, telefone) are encrypted at-rest via EncryptedString.
            # ilike on ciphertext is not supported by PostgreSQL.
            # We search telefone_hash by HMAC exact match (telefone_hash is not encrypted).
            from app.infrastructure.security.pii_encryption import hmac_hash
            stmt = stmt.where(LeadModel.telefone_hash == hmac_hash(q))

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
        from datetime import datetime, timezone
        lead = await self.get_by_id(lead_id)
        if lead is None:
            raise ValueError(f"Lead {lead_id} não encontrado")
        lead.is_archived = True
        lead.deleted_at = datetime.now(timezone.utc)
        await self._session.flush()
        await invalidate_pattern(f"cached:*{lead_id}*")
        await invalidate_pattern("cached:*list*")
