"""add_expiration_to_propostas

Revision ID: e8f9a0b1c2d3
Revises: f6a7b8c9d0e1
Create Date: 2026-05-06

Two changes required for the proposta SLA expiration cronjob:

  1. Ensure 'expirada' exists in proposta_status_enum.
     Handles two scenarios that both occur in practice:
       a) Type is absent entirely (DB was seeded via create_tables() before
          dd4f06e3dc70 ran, or dd4f06e3dc70 failed mid-way) → CREATE TYPE
          with all values including 'expirada'.
       b) Type exists but lacks 'expirada' (normal upgrade path) →
          ALTER TYPE ... ADD VALUE IF NOT EXISTS.

  2. Add expiration_hours column to propostas.
     INTEGER NOT NULL DEFAULT 48 — SLA window in hours from criado_em.
     IF NOT EXISTS makes the statement safe to re-run.
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = 'e8f9a0b1c2d3'
down_revision = 'f6a7b8c9d0e1'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # ── Step 1: ensure proposta_status_enum exists with 'expirada' ──────────
    type_exists = conn.execute(
        sa.text(
            "SELECT EXISTS("
            "SELECT 1 FROM pg_type WHERE typname = 'proposta_status_enum'"
            ")"
        )
    ).scalar()

    if not type_exists:
        # Scenario (a): type was never created — build it from scratch with
        # all current values so a fresh DB reaches the correct final state.
        postgresql.ENUM(
            'rascunho', 'enviada', 'aprovada', 'recusada', 'em_revisao', 'expirada',
            name='proposta_status_enum',
        ).create(conn)
    else:
        # Scenario (b): type exists, add the new value only if absent.
        # ALTER TYPE ADD VALUE IF NOT EXISTS is available in PostgreSQL 9.6+.
        # It can run inside a transaction on PostgreSQL 12+ as long as the new
        # label is not used within the same transaction — safe here.
        conn.execute(
            sa.text(
                "ALTER TYPE proposta_status_enum ADD VALUE IF NOT EXISTS 'expirada'"
            )
        )

    # ── Step 2: add the SLA column (idempotent) ─────────────────────────────
    op.execute(
        "ALTER TABLE propostas "
        "ADD COLUMN IF NOT EXISTS expiration_hours INTEGER NOT NULL DEFAULT 48"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE propostas DROP COLUMN IF EXISTS expiration_hours")

    # PostgreSQL has no DROP VALUE for enums. To fully revert 'expirada' you
    # would need to recreate the type without it and ALTER the column. Left as
    # a no-op for the MVP — the extra value is harmless if the code is rolled back.
