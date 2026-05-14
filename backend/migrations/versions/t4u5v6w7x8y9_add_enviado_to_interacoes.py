"""add_enviado_to_interacoes

Revision ID: t4u5v6w7x8y9
Revises: s3t4u5v6w7x8
Create Date: 2026-05-14

Adds enviado boolean flag to interacoes table (audit §7.3).
Without this flag, CRM consultors cannot distinguish AI replies that were
successfully delivered from those that failed silently after all retries.
Existing rows default to FALSE (unknown delivery status).

  interacoes:
    - enviado  BOOLEAN NOT NULL DEFAULT FALSE
"""
from alembic import op

revision = "t4u5v6w7x8y9"
down_revision = "s3t4u5v6w7x8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE interacoes "
        "ADD COLUMN IF NOT EXISTS enviado BOOLEAN NOT NULL DEFAULT FALSE"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE interacoes DROP COLUMN IF EXISTS enviado")
