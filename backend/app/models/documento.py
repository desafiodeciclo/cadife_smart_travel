import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    String,
    func,
    Enum as SAEnum,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import DocumentoCategoria
from app.core.database import Base

if TYPE_CHECKING:
    from app.models.lead import Lead
    from app.models.user import User

# PostgreSQL native ENUM type for document categories
documento_categoria_enum = SAEnum(
    *[e.value for e in DocumentoCategoria],
    name="documento_categoria_enum",
    create_type=False,  # Should be created by Alembic
)


class Documento(Base):
    """
    ORM representation of a travel document (voucher, itinerary, etc.).
    Stored in S3 compatible object storage with metadata in PostgreSQL.
    Follows §7.2 of spec.md.
    """

    __tablename__ = "documentos"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id", ondelete="CASCADE"), index=True
    )
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    s3_key: Mapped[str] = mapped_column(String(512), nullable=False)
    categoria: Mapped[str] = mapped_column(
        documento_categoria_enum, nullable=False, default=DocumentoCategoria.outros.value
    )
    tamanho_bytes: Mapped[int] = mapped_column(BigInteger, nullable=False)
    mimetype: Mapped[str] = mapped_column(String(100), nullable=False)

    enviado_por: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        nullable=False, 
        default=lambda: datetime.now(timezone.utc)
    )
    # Soft Delete for 2-year retention policy
    deleted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )

    # Relationships
    lead: Mapped["Lead"] = relationship("Lead", back_populates="documentos")
    autor: Mapped[Optional["User"]] = relationship("User")
