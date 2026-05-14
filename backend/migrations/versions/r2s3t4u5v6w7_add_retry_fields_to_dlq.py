"""add_retry_fields_to_dlq

Revision ID: r2s3t4u5v6w7
Revises: q1r2s3t4u5v6
Create Date: 2026-05-14

Adds retry mechanism fields to dead_letter_queue (audit §4.5 — medium).
Without these fields the DLQ has no way to schedule or track re-processing attempts.

  dead_letter_queue:
    - tentativas     INTEGER NOT NULL DEFAULT 0
    - proximo_retry  TIMESTAMPTZ NULLABLE
"""
from alembic import op

revision = "r2s3t4u5v6w7"
down_revision = "q1r2s3t4u5v6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE dead_letter_queue "
        "ADD COLUMN IF NOT EXISTS tentativas INTEGER NOT NULL DEFAULT 0"
    )
    op.execute(
        "ALTER TABLE dead_letter_queue "
        "ADD COLUMN IF NOT EXISTS proximo_retry TIMESTAMPTZ"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE dead_letter_queue DROP COLUMN IF EXISTS proximo_retry")
    op.execute("ALTER TABLE dead_letter_queue DROP COLUMN IF EXISTS tentativas")
