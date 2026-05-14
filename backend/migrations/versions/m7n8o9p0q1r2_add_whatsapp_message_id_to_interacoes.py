"""add_whatsapp_message_id_to_interacoes

Revision ID: m7n8o9p0q1r2
Revises: l6m7n8o9p0q1
Create Date: 2026-05-13

Adds whatsapp_message_id to the interacoes table so the application can
deduplicate inbound webhook replays from the Meta platform.

  interacoes:
    - whatsapp_message_id  VARCHAR(255) UNIQUE NULLABLE — wamid from Meta payload
"""
from alembic import op

revision = "m7n8o9p0q1r2"
down_revision = "l6m7n8o9p0q1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE interacoes "
        "ADD COLUMN IF NOT EXISTS whatsapp_message_id VARCHAR(255)"
    )
    op.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS uq_interacoes_whatsapp_message_id "
        "ON interacoes (whatsapp_message_id) "
        "WHERE whatsapp_message_id IS NOT NULL"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_interacoes_whatsapp_message_id "
        "ON interacoes (whatsapp_message_id)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_interacoes_whatsapp_message_id")
    op.execute("DROP INDEX IF EXISTS uq_interacoes_whatsapp_message_id")
    op.execute(
        "ALTER TABLE interacoes DROP COLUMN IF EXISTS whatsapp_message_id"
    )
