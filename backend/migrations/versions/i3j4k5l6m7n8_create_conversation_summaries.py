"""create_conversation_summaries

Revision ID: i3j4k5l6m7n8
Revises: h2i3j4k5l6m7
Create Date: 2026-05-12

Persists SimpleWindowMemory._summary so compressed conversation context
survives server restarts (resolves BUG #12 follow-up: memory restart-resilience).
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision = "i3j4k5l6m7n8"
down_revision = "h2i3j4k5l6m7"
branch_labels = None
depends_on = None


def upgrade() -> None:
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


def downgrade() -> None:
    op.drop_index("ix_conversation_summaries_lead_id", table_name="conversation_summaries")
    op.drop_table("conversation_summaries")
