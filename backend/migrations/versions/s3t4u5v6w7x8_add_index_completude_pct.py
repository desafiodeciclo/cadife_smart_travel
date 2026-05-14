"""add_index_completude_pct

Revision ID: s3t4u5v6w7x8
Revises: r2s3t4u5v6w7
Create Date: 2026-05-14

Adds index on briefings.completude_pct (audit §4.4 — low priority).
Without this index, queries filtering by qualification threshold (>= 60)
perform full table scans — harmful at scale.
"""
from alembic import op

revision = "s3t4u5v6w7x8"
down_revision = "r2s3t4u5v6w7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_briefings_completude_pct "
        "ON briefings (completude_pct)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_briefings_completude_pct")
