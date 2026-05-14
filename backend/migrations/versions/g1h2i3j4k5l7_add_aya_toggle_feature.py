"""add_aya_toggle_feature

Revision ID: g1h2i3j4k5l7
Revises: f6a7b8c9d0e1
Create Date: 2026-05-11

Adds AYA on/off toggle per conversation (spec: feat/aya-toggle):
  1. leads.aya_ativo — boolean, default true.
     When false the webhook persists messages but skips AI processing.
  2. aya_toggle_history — audit table for every toggle action with
     actor, reason, and timestamp.
"""

import uuid
import sqlalchemy as sa
from alembic import op

revision = "g1h2i3j4k5l7"
down_revision = "f6a7b8c9d0e1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Add aya_ativo to leads
    op.add_column(
        "leads",
        sa.Column(
            "aya_ativo",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
    )

    # 2. Create aya_toggle_history
    op.create_table(
        "aya_toggle_history",
        sa.Column(
            "id",
            sa.dialects.postgresql.UUID(as_uuid=True),
            primary_key=True,
            default=uuid.uuid4,
            nullable=False,
        ),
        sa.Column(
            "lead_id",
            sa.dialects.postgresql.UUID(as_uuid=True),
            sa.ForeignKey("leads.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("ativo", sa.Boolean(), nullable=False),
        sa.Column("motivo", sa.Text(), nullable=True),
        sa.Column(
            "alterado_por",
            sa.dialects.postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "alterado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.create_index(
        "ix_aya_toggle_history_lead_id_alterado_em",
        "aya_toggle_history",
        ["lead_id", "alterado_em"],
    )


def downgrade() -> None:
    op.drop_index("ix_aya_toggle_history_lead_id_alterado_em", table_name="aya_toggle_history")
    op.drop_table("aya_toggle_history")
    op.drop_column("leads", "aya_ativo")
