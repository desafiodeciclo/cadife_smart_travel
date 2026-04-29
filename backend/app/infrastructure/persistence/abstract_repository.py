"""
AbstractRepository — Infrastructure/Persistence Layer
=======================================================
Generic async repository base that abstracts SQLAlchemy from business logic.
All concrete repositories inherit this class, satisfying domain interfaces
without exposing ORM details to Application or Presentation layers.

Pattern: Repository + Data Mapper
  - Domain entities are pure Python objects (dataclasses / pydantic)
  - ORM models live only in infrastructure
  - Conversion happens in _to_entity / _from_entity on each repository
"""
from abc import abstractmethod
from typing import Any, Generic, Optional, TypeVar
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.database import Base

ModelT = TypeVar("ModelT", bound=Base)


class AbstractRepository(Generic[ModelT]):
    """
    Generic async repository providing CRUD primitives.

    Subclasses must define:
        model: type[ModelT]   — the SQLAlchemy ORM class

    They may override any method for domain-specific behavior.
    """

    model: type[ModelT]

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    # ── Primitives ──────────────────────────────────────────────────────────

    async def get_by_id(self, pk: UUID) -> Optional[ModelT]:
        """Return ORM instance by primary key or None."""
        return await self._session.get(self.model, pk)

    async def list(
        self,
        *,
        limit: int = 20,
        offset: int = 0,
        **filter_kwargs: Any,
    ) -> list[ModelT]:
        """Return list of ORM instances filtered by kwargs."""
        stmt = select(self.model)
        for attr, value in filter_kwargs.items():
            stmt = stmt.where(getattr(self.model, attr) == value)
        stmt = stmt.offset(offset).limit(limit)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def add(self, instance: ModelT) -> ModelT:
        """Persist a new ORM instance, flushing without committing (unit-of-work)."""
        self._session.add(instance)
        await self._session.flush()
        await self._session.refresh(instance)
        return instance

    async def delete(self, instance: ModelT) -> None:
        """Remove an ORM instance from the session."""
        await self._session.delete(instance)
        await self._session.flush()

    # ── Hook — subclasses must implement ────────────────────────────────────

    @abstractmethod
    async def get_by_id(self, pk: UUID) -> Optional[ModelT]:  # type: ignore[override]
        """Typed version ensures subclasses return the right domain type."""
        ...
