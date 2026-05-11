"""
SuitcaseRepository — Infrastructure/Persistence Layer
=====================================================
SQLAlchemy async implementation of ISuitcaseRepository.
"""

import uuid
from typing import Optional

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.interfaces.repositories import ISuitcaseRepository
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.suitcase_model import (
    SuitcaseItemModel,
    SuitcaseSuggestionModel,
)


class SuitcaseRepository(AbstractRepository[SuitcaseItemModel], ISuitcaseRepository):
    """
    SQLAlchemy implementation for suitcase persistence.
    """

    model = SuitcaseItemModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_items_by_lead(self, lead_id: uuid.UUID) -> list[SuitcaseItemModel]:
        stmt = select(SuitcaseItemModel).where(SuitcaseItemModel.lead_id == lead_id)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_item_by_id(self, item_id: uuid.UUID) -> Optional[SuitcaseItemModel]:
        return await self._session.get(SuitcaseItemModel, item_id)

    async def create_item(
        self,
        lead_id: uuid.UUID,
        user_id: uuid.UUID,
        nome: str,
        categoria: str,
        quantidade: int = 1,
    ) -> SuitcaseItemModel:
        item = SuitcaseItemModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            user_id=user_id,
            nome=nome,
            categoria=categoria,
            quantidade=quantidade,
            empacotado=False,
        )
        return await self.add(item)

    async def update_item(
        self,
        item_id: uuid.UUID,
        *,
        nome: Optional[str] = None,
        empacotado: Optional[bool] = None,
        quantidade: Optional[int] = None,
        categoria: Optional[str] = None,
    ) -> SuitcaseItemModel:
        item = await self.get_item_by_id(item_id)
        if not item:
            raise ValueError(f"Item {item_id} não encontrado na mala")
        
        if nome is not None:
            item.nome = nome
        if empacotado is not None:
            item.empacotado = empacotado
        if quantidade is not None:
            item.quantidade = quantidade
        if categoria is not None:
            item.categoria = categoria
            
        await self._session.flush()
        return item

    async def delete_item(self, item_id: uuid.UUID) -> None:
        stmt = delete(SuitcaseItemModel).where(SuitcaseItemModel.id == item_id)
        await self._session.execute(stmt)
        await self._session.flush()

    async def get_suggestions_by_destination(
        self, destination_type: str
    ) -> list[SuitcaseSuggestionModel]:
        stmt = select(SuitcaseSuggestionModel).where(
            SuitcaseSuggestionModel.tipo_destino == destination_type
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())
