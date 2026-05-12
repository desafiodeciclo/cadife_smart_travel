import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.interfaces.repositories import IDocumentoRepository
from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.models.documento import Documento


class DocumentoRepository(AbstractRepository[Documento], IDocumentoRepository):
    """
    SQLAlchemy async implementation of IDocumentoRepository.
    Handles persistence of travel documents metadata.
    """

    model = Documento

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def create(
        self,
        lead_id: uuid.UUID,
        nome: str,
        s3_key: str,
        categoria: str,
        tamanho_bytes: int,
        mimetype: str,
        enviado_por: Optional[uuid.UUID] = None,
    ) -> Documento:
        """Creates a new document record in the database."""
        documento = Documento(
            id=uuid.uuid4(),
            lead_id=lead_id,
            nome=nome,
            s3_key=s3_key,
            categoria=categoria,
            tamanho_bytes=tamanho_bytes,
            mimetype=mimetype,
            enviado_por=enviado_por,
        )
        return await self.add(documento)

    async def get_by_id(self, documento_id: uuid.UUID) -> Optional[Documento]:
        """Retrieves a document by its ID."""
        return await self._session.get(Documento, documento_id)

    async def list_by_lead(
        self, lead_id: uuid.UUID, include_deleted: bool = False
    ) -> list[Documento]:
        """Lists all documents associated with a lead."""
        stmt = select(Documento).where(Documento.lead_id == lead_id)
        if not include_deleted:
            stmt = stmt.where(Documento.deleted_at.is_(None))

        stmt = stmt.order_by(Documento.criado_em.desc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def list_by_travel(
        self, travel_id: uuid.UUID, include_deleted: bool = False
    ) -> list[Documento]:
        """Lists all documents associated with a travel."""
        stmt = select(Documento).where(Documento.travel_id == travel_id)
        if not include_deleted:
            stmt = stmt.where(Documento.deleted_at.is_(None))

        stmt = stmt.order_by(Documento.criado_em.desc())
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def soft_delete(self, documento_id: uuid.UUID) -> None:
        """Marks a document as deleted for retention purposes (spec.md §1.2)."""
        documento = await self.get_by_id(documento_id)
        if documento:
            documento.deleted_at = datetime.now(timezone.utc)
            await self._session.flush()
