import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.infrastructure.persistence.database import Base
from app.infrastructure.persistence.types import StringArray


offer_status_enum = SAEnum(
    *[e.value for e in OfferStatus],
    name="offer_status_enum",
    create_type=True,
)
offer_categoria_enum = SAEnum(
    *[e.value for e in OfferCategoria],
    name="offer_categoria_enum",
    create_type=True,
)


class OfferModel(Base):
    """ORM representation of a travel offer (infrastructure layer)."""

    __tablename__ = "offers"

    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    titulo: Mapped[str] = mapped_column(String(255), nullable=False)
    destino: Mapped[str] = mapped_column(String(255), nullable=False)
    descricao: Mapped[Optional[str]] = mapped_column(Text)
    categoria: Mapped[str] = mapped_column(
        offer_categoria_enum, nullable=False, default=OfferCategoria.outros.value
    )
    preco_base: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    servicos_inclusos: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    imagens: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    data_saida_sugerida: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(
        offer_status_enum, nullable=False, default=OfferStatus.rascunho.value
    )
    criado_por: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    is_deleted: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="false"
    )

    creator = relationship("UserModel", foreign_keys=[criado_por])
