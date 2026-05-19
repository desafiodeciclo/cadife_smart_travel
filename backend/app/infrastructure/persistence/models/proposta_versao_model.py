"""
PropostaVersao ORM — Infrastructure/Persistence Layer
======================================================
Append-only snapshot table for propostas (gap §3.4.4).

Each mutation that changes business-relevant state of a proposta inserts
a row here with the full snapshot at that moment + the reason (motivo).

Constraints:
  - UNIQUE (proposta_id, numero_versao)
  - CHECK motivo IN allowed list
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    JSON,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


class PropostaVersaoModel(Base):
    __tablename__ = "proposta_versoes"
    __table_args__ = (
        UniqueConstraint("proposta_id", "numero_versao", name="uq_proposta_versao"),
        CheckConstraint(
            "motivo IN ('criacao','edicao','envio','aprovacao','recusa','cancelamento')",
            name="ck_proposta_versao_motivo",
        ),
        Index(
            "idx_proposta_versoes_lookup",
            "proposta_id",
            "numero_versao",
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    proposta_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("propostas.id", ondelete="CASCADE"),
        nullable=False,
    )
    numero_versao: Mapped[int] = mapped_column(Integer, nullable=False)
    snapshot_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    motivo: Mapped[str] = mapped_column(String(50), nullable=False)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
