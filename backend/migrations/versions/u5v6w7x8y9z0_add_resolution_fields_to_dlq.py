"""add_resolution_fields_to_dlq

Revision ID: u5v6w7x8y9z0
Revises: t4u5v6w7x8y9
Create Date: 2026-05-14

Adds resolution-tracking and index fields to dead_letter_queue (audit §5.2).
Without these fields there is no way to record who resolved an entry or filter
unresolved entries efficiently for the retry worker.

  dead_letter_queue:
    + resolvido       BOOLEAN NOT NULL DEFAULT FALSE  (indexed)
    + resolvido_por   UUID NULLABLE FK users.id
    + resolvido_em    TIMESTAMPTZ NULLABLE
    + index on proximo_retry (for retry worker polling)
"""
from alembic import op

revision = "u5v6w7x8y9z0"
down_revision = "t4u5v6w7x8y9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE dead_letter_queue "
        "ADD COLUMN IF NOT EXISTS resolvido BOOLEAN NOT NULL DEFAULT FALSE"
    )
    op.execute(
        "ALTER TABLE dead_letter_queue "
        "ADD COLUMN IF NOT EXISTS resolvido_por UUID REFERENCES users(id)"
    )
    op.execute(
        "ALTER TABLE dead_letter_queue "
        "ADD COLUMN IF NOT EXISTS resolvido_em TIMESTAMPTZ"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_dlq_resolvido ON dead_letter_queue (resolvido) "
        "WHERE resolvido = FALSE"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_dlq_proximo_retry "
        "ON dead_letter_queue (proximo_retry) WHERE proximo_retry IS NOT NULL"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_dlq_proximo_retry")
    op.execute("DROP INDEX IF EXISTS ix_dlq_resolvido")
    op.execute("ALTER TABLE dead_letter_queue DROP COLUMN IF EXISTS resolvido_em")
    op.execute("ALTER TABLE dead_letter_queue DROP COLUMN IF EXISTS resolvido_por")
    op.execute("ALTER TABLE dead_letter_queue DROP COLUMN IF EXISTS resolvido")
