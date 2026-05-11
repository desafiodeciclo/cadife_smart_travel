import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as PgEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.infrastructure.persistence.types import StringArray

if TYPE_CHECKING:
    from app.models.user import User


class Offer(Base):
    """Travel offer / showcase entity (vitrine digital da Cadife Tour)."""

    __tablename__ = "offers"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    titulo: Mapped[str] = mapped_column(String(255), nullable=False)
    destino: Mapped[str] = mapped_column(String(255), nullable=False)
    descricao: Mapped[Optional[str]] = mapped_column(Text)
    categoria: Mapped[OfferCategoria] = mapped_column(
        PgEnum(OfferCategoria, name="offer_categoria_enum", create_type=False),
        nullable=False,
        default=OfferCategoria.outros,
    )
    preco_base: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    servicos_inclusos: Mapped[Optional[list[str]]] = mapped_column(
        StringArray(), nullable=True, default=list
    )
    imagens: Mapped[Optional[list[str]]] = mapped_column(
        StringArray(), nullable=True, default=list
    )
    data_saida_sugerida: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[OfferStatus] = mapped_column(
        PgEnum(OfferStatus, name="offer_status_enum", create_type=False),
        nullable=False,
        default=OfferStatus.rascunho,
    )
    criado_por: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
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
        default=False, nullable=False, server_default="false"
    )

    creator: Mapped["User"] = relationship("User", foreign_keys=[criado_por])
