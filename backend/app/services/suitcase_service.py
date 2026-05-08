"""
SuitcaseService — Application Layer
===================================
Business logic for managing suitcase items and deterministic suggestions.
"""

import uuid
from typing import Dict, List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.entities.enums import SuitcaseCategory, DestinationType
from app.infrastructure.persistence.repositories.suitcase_repository import SuitcaseRepository
from app.infrastructure.persistence.models.suitcase_model import SuitcaseItemModel, SuitcaseSuggestionModel


async def get_grouped_suitcase(db: AsyncSession, lead_id: uuid.UUID) -> Dict:
    """
    Returns items grouped by category and summary metrics.
    """
    repo = SuitcaseRepository(db)
    items = await repo.get_items_by_lead(lead_id)
    
    grouped: Dict[str, List[SuitcaseItemModel]] = {cat.value: [] for cat in SuitcaseCategory}
    total_packed = 0
    
    for item in items:
        # categoria is a string in the Model (mapped from Enum)
        cat_val = item.categoria
        if cat_val in grouped:
            grouped[cat_val].append(item)
        else:
            if "outros" not in grouped:
                grouped["outros"] = []
            grouped["outros"].append(item)
            
        if item.empacotado:
            total_packed += 1
            
    return {
        "items_by_category": grouped,
        "total_items": len(items),
        "total_packed": total_packed
    }


async def add_item(
    db: AsyncSession, 
    lead_id: uuid.UUID, 
    user_id: uuid.UUID, 
    nome: str, 
    categoria: SuitcaseCategory, 
    quantidade: int = 1
) -> SuitcaseItemModel:
    repo = SuitcaseRepository(db)
    item = await repo.create_item(
        lead_id=lead_id,
        user_id=user_id,
        nome=nome,
        categoria=categoria.value,
        quantidade=quantidade
    )
    await db.commit()
    await db.refresh(item)
    return item


async def update_item(
    db: AsyncSession,
    item_id: uuid.UUID,
    **kwargs
) -> SuitcaseItemModel:
    repo = SuitcaseRepository(db)
    # Convert Enum to value if present
    if "categoria" in kwargs and kwargs["categoria"]:
        kwargs["categoria"] = kwargs["categoria"].value
        
    item = await repo.update_item(item_id, **kwargs)
    await db.commit()
    await db.refresh(item)
    return item


async def delete_item(db: AsyncSession, item_id: uuid.UUID) -> None:
    repo = SuitcaseRepository(db)
    await repo.delete_item(item_id)
    await db.commit()


async def get_suggestions(db: AsyncSession, destination_type: str) -> List[SuitcaseSuggestionModel]:
    repo = SuitcaseRepository(db)
    return await repo.get_suggestions_by_destination(destination_type)


async def get_item_by_id(db: AsyncSession, item_id: uuid.UUID) -> Optional[SuitcaseItemModel]:
    repo = SuitcaseRepository(db)
    return await repo.get_item_by_id(item_id)
