import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import ENUM as PgEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import TravelCheckpoint

if TYPE_CHECKING:
    from app.models.lead import Lead


class TravelCheckpointRecord(Base):
    __tablename__ = "travel_checkpoints"
    __table_args__ = (
        UniqueConstraint("lead_id", "checkpoint", name="uq_travel_checkpoints_lead_checkpoint"),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id", ondelete="CASCADE"), nullable=False, index=True
    )
    checkpoint: Mapped[TravelCheckpoint] = mapped_column(
        PgEnum(
            TravelCheckpoint,
            name="travel_checkpoint_enum",
            create_type=False,
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=False,
    )
    ativado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    # UUID string of the consultor user or the literal "sistema"
    ativado_por: Mapped[str] = mapped_column(String(64), nullable=False)

    lead: Mapped["Lead"] = relationship("Lead", back_populates="checkpoints")
