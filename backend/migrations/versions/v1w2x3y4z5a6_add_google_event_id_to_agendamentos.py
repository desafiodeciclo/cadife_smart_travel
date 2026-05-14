"""add google_event_id to agendamentos

Revision ID: v1w2x3y4z5a6
Revises: u5v6w7x8y9z0
Create Date: 2026-05-14 00:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "v1w2x3y4z5a6"
down_revision: str | None = "u5v6w7x8y9z0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "agendamentos",
        sa.Column("google_event_id", sa.String(length=1024), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("agendamentos", "google_event_id")
