"""
BriefingRepository — Infrastructure/Persistence Layer
======================================================
Concrete implementation of IBriefingRepository using SQLAlchemy async.
Supports upsert pattern (create-or-update in a single call) since a lead
always has at most one briefing.
"""
import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.interfaces.repositories import IBriefingRepository
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.briefing_model import (
    BriefingModel,
    calculate_completude,
)


class BriefingRepository(AbstractRepository[BriefingModel], IBriefingRepository):
    """SQLAlchemy async implementation of IBriefingRepository."""

    model = BriefingModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_by_id(self, pk: uuid.UUID) -> Optional[BriefingModel]:  # type: ignore[override]
        return await self._session.get(BriefingModel, pk)

    async def get_by_lead(self, lead_id: uuid.UUID) -> Optional[BriefingModel]:
        stmt = select(BriefingModel).where(BriefingModel.lead_id == lead_id)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def upsert(self, lead_id: uuid.UUID, data: dict) -> BriefingModel:
        """
        Create or update a briefing for the given lead.
        Calculates completude_pct automatically before saving.
        """
        data["completude_pct"] = calculate_completude(data)
        existing = await self.get_by_lead(lead_id)

        if existing:
            for key, value in data.items():
                if hasattr(existing, key) and value is not None:
                    setattr(existing, key, value)
            # Recalculate completude after merge
            merged = {
                f: getattr(existing, f)
                for f in ["destino", "data_ida", "data_volta", "qtd_pessoas",
                          "perfil", "tipo_viagem", "preferencias", "orcamento", "tem_passaporte"]
            }
            existing.completude_pct = calculate_completude(merged)
            await self._session.flush()
            return existing

        briefing = BriefingModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            **{k: v for k, v in data.items() if hasattr(BriefingModel, k)},
        )
        return await self.add(briefing)
