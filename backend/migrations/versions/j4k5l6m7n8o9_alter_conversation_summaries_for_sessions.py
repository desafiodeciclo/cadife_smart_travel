"""alter_conversation_summaries_for_sessions

Revision ID: j4k5l6m7n8o9
Revises: i3j4k5l6m7n8
Create Date: 2026-05-12

Replaces the single-row-per-lead conversation_summaries table (used by
SimpleWindowMemory persistence) with the spec-compliant schema that supports
multiple session summaries per lead with structured JSON topics, token cost
tracking, and a pending-retry fallback flag.

Changes vs previous schema:
  - DROP UNIQUE constraint on lead_id  → allows one row per session
  - DROP summary (TEXT)                → replaced by resumo_json (JSONB)
  - DROP updated_at                    → replaced by gerado_em
  - ADD sessao_id VARCHAR(64) NOT NULL
  - ADD resumo_json JSONB
  - ADD resumo_pendente BOOLEAN NOT NULL DEFAULT FALSE
  - ADD gerado_em TIMESTAMPTZ NOT NULL DEFAULT now()
  - ADD tokens_utilizados INTEGER
  - ADD composite index (lead_id, gerado_em)
  - ADD partial index on resumo_pendente for fast retry queries
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "j4k5l6m7n8o9"
down_revision: Union[str, None] = "i3j4k5l6m7n8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_index("ix_conversation_summaries_lead_id", table_name="conversation_summaries")
    op.drop_table("conversation_summaries")

    op.create_table(
        "conversation_summaries",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "lead_id",
            UUID(as_uuid=True),
            sa.ForeignKey("leads.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("sessao_id", sa.String(64), nullable=False),
        sa.Column("resumo_json", JSONB, nullable=True),
        sa.Column(
            "resumo_pendente",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("FALSE"),
        ),
        sa.Column(
            "gerado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("tokens_utilizados", sa.Integer(), nullable=True),
    )

    op.create_index(
        "ix_conv_summaries_lead_gerado_em",
        "conversation_summaries",
        ["lead_id", "gerado_em"],
    )
    op.create_index(
        "ix_conv_summaries_pendente",
        "conversation_summaries",
        ["resumo_pendente"],
        postgresql_where=sa.text("resumo_pendente = TRUE"),
    )


def downgrade() -> None:
    op.drop_index("ix_conv_summaries_pendente", table_name="conversation_summaries")
    op.drop_index("ix_conv_summaries_lead_gerado_em", table_name="conversation_summaries")
    op.drop_table("conversation_summaries")

    op.create_table(
        "conversation_summaries",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "lead_id",
            UUID(as_uuid=True),
            sa.ForeignKey("leads.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("summary", sa.Text(), nullable=False, server_default=""),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_conversation_summaries_lead_id",
        "conversation_summaries",
        ["lead_id"],
    )
