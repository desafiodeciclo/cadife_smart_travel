"""propostas_extension — versoes + enviado_em + notificacao_enviada_em + soft-delete

Revision ID: n7o8p9q0r1s2
Revises: m6n7o8p9q0r1
Create Date: 2026-05-12

Implements gap §3.4 from docs/BACKEND_FRONTEND_PARITY_GAPS.md:
  - Add propostas.enviado_em                — set when proposta moves to 'enviada'
  - Add propostas.notificacao_enviada_em    — idempotency guard for FCM/WhatsApp dispatch
  - Add propostas.deletado_em + deletado_por — soft-delete
  - Create proposta_versoes                 — append-only snapshot history
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "n7o8p9q0r1s2"
down_revision: Union[str, None] = "m6n7o8p9q0r1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. Auxiliary columns on propostas ──────────────────────────────────
    op.add_column(
        "propostas",
        sa.Column("enviado_em", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "propostas",
        sa.Column(
            "notificacao_enviada_em", sa.DateTime(timezone=True), nullable=True
        ),
    )
    op.add_column(
        "propostas",
        sa.Column("deletado_em", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "propostas",
        sa.Column(
            "deletado_por",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    # Partial index to speed up lists that filter out soft-deleted rows
    op.create_index(
        "idx_propostas_active",
        "propostas",
        ["lead_id", "status"],
        postgresql_where=sa.text("deletado_em IS NULL"),
    )

    # ── 2. proposta_versoes (append-only snapshot table) ───────────────────
    op.create_table(
        "proposta_versoes",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "proposta_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("propostas.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("numero_versao", sa.Integer, nullable=False),
        sa.Column("snapshot_json", postgresql.JSONB, nullable=False),
        sa.Column("motivo", sa.String(length=50), nullable=False),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "proposta_id", "numero_versao", name="uq_proposta_versao"
        ),
        sa.CheckConstraint(
            "motivo IN ('criacao','edicao','envio','aprovacao','recusa','cancelamento')",
            name="ck_proposta_versao_motivo",
        ),
    )
    op.create_index(
        "idx_proposta_versoes_lookup",
        "proposta_versoes",
        ["proposta_id", "numero_versao"],
    )


def downgrade() -> None:
    op.drop_index("idx_proposta_versoes_lookup", table_name="proposta_versoes")
    op.drop_table("proposta_versoes")

    op.drop_index("idx_propostas_active", table_name="propostas")
    op.drop_column("propostas", "deletado_por")
    op.drop_column("propostas", "deletado_em")
    op.drop_column("propostas", "notificacao_enviada_em")
    op.drop_column("propostas", "enviado_em")
