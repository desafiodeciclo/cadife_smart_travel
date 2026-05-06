"""add_expiration_to_propostas

Revision ID: e8f9a0b1c2d3
Revises: f6a7b8c9d0e1
Create Date: 2026-05-06

Two changes required for the proposta SLA expiration cronjob:

  1. Add 'expirada' value to the proposta_status_enum PostgreSQL type.
     Uses 'IF NOT EXISTS' (PostgreSQL 9.6+) so this is safe to re-run.

  2. Add expiration_hours column to propostas table.
     INTEGER NOT NULL DEFAULT 48 — represents the SLA window in hours
     from criado_em before the proposal is automatically expired.
     Server default of 48 means existing rows are treated as having a
     2-day SLA retroactively, which is acceptable for the MVP.

All statements use IF NOT EXISTS / conditional guards so the migration
is safe to run on databases that were partially migrated.
"""
from alembic import op
import sqlalchemy as sa

revision = 'e8f9a0b1c2d3'
down_revision = 'f6a7b8c9d0e1'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Step 1: extend the enum type — must run outside a transaction block
    # because PostgreSQL does not allow ALTER TYPE inside a transaction.
    op.execute("ALTER TYPE proposta_status_enum ADD VALUE IF NOT EXISTS 'expirada'")

    # Step 2: add the SLA column to propostas
    op.execute(
        "ALTER TABLE propostas "
        "ADD COLUMN IF NOT EXISTS expiration_hours INTEGER NOT NULL DEFAULT 48"
    )


def downgrade() -> None:
    # Remove the column added in upgrade
    op.execute("ALTER TABLE propostas DROP COLUMN IF EXISTS expiration_hours")

    # PostgreSQL does not support removing enum values natively.
    # To fully revert 'expirada': recreate the enum without it and
    # ALTER TABLE propostas ALTER COLUMN status TYPE proposta_status_enum USING ...
    # This is intentionally left as a no-op for the MVP — document in ADR if needed.
