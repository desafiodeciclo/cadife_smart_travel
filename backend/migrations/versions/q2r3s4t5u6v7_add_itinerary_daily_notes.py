"""add itinerary_daily_notes table

Revision ID: q2r3s4t5u6v7
Revises: p0q1r2s3t4u5
Create Date: 2026-05-19

Tabela para notas diárias do itinerário de um lead.
Constraint única em (lead_id, date) garante upsert idempotente.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "q2r3s4t5u6v7"
down_revision: Union[str, None] = "p0q1r2s3t4u5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "itinerary_daily_notes",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("lead_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["lead_id"], ["leads.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("lead_id", "date", name="uq_itinerary_daily_notes_lead_date"),
    )
    op.create_index(
        "ix_itinerary_daily_notes_lead_id",
        "itinerary_daily_notes",
        ["lead_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_itinerary_daily_notes_lead_id", table_name="itinerary_daily_notes")
    op.drop_table("itinerary_daily_notes")
