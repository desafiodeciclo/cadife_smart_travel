"""add_missing_columns_interacoes_users

Revision ID: c4d5e6f7a8b9
Revises: 63a1b837b445
Create Date: 2026-05-02

Adds columns that exist in the ORM models but were missing from the DB:

  interacoes:
    - enviado_em   — timestamp of WhatsApp delivery confirmation
    - status_envio — delivery status code (sent, failed, etc.) max 10 chars
    - erro_envio   — raw error payload when delivery fails

  users:
    - avatar_url — skipped in dd4f06e3dc70 because 'users' table pre-existed
                   (the create_table block is guarded by has_table check)

All ADD COLUMN statements use IF NOT EXISTS so this migration is safe to run
on DBs that already have some or all of these columns via out-of-band SQL.
"""
from alembic import op
import sqlalchemy as sa

revision = 'c4d5e6f7a8b9'
down_revision = '63a1b837b445'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE interacoes ADD COLUMN IF NOT EXISTS enviado_em TIMESTAMPTZ")
    op.execute("ALTER TABLE interacoes ADD COLUMN IF NOT EXISTS status_envio VARCHAR(10)")
    op.execute("ALTER TABLE interacoes ADD COLUMN IF NOT EXISTS erro_envio TEXT")
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500)")


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS avatar_url")
    op.execute("ALTER TABLE interacoes DROP COLUMN IF EXISTS erro_envio")
    op.execute("ALTER TABLE interacoes DROP COLUMN IF EXISTS status_envio")
    op.execute("ALTER TABLE interacoes DROP COLUMN IF EXISTS enviado_em")
