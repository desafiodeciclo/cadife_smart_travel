"""add_composite_indexes_for_lead_filters

Revision ID: e7f8a9b0c1d2
Revises: c4d5e6f7a8b9
Create Date: 2026-05-07

Implements composite indexes for the leads table to optimise the advanced
filter queries defined in spec.md §7.1:

  - status + criado_em  : most common combined filter (pipeline board view)
  - score  + criado_em  : qualification pipeline ordering
  - is_archived + deleted_at + criado_em : base filter present in every query
  - criado_em           : date range filters (data_inicio / data_fim)

Uses IF NOT EXISTS guards so the migration is idempotent.
All indexes are CONCURRENTLY-safe (added via CREATE INDEX IF NOT EXISTS).
"""
from alembic import op

revision = 'e7f8a9b0c1d2'
down_revision = 'f6a7b8c9d0e1'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Index 1: status + criado_em — pipeline board view (most frequent)
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_leads_status_criado_em
        ON leads (status, criado_em DESC)
        WHERE deleted_at IS NULL AND is_archived = FALSE
    """)

    # Index 2: score + criado_em — qualification pipeline ordering
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_leads_score_criado_em
        ON leads (score, criado_em DESC)
        WHERE deleted_at IS NULL AND is_archived = FALSE
    """)

    # Index 3: criado_em — date-range filters (data_inicio / data_fim)
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_leads_criado_em
        ON leads (criado_em DESC)
        WHERE deleted_at IS NULL AND is_archived = FALSE
    """)

    # Index 4: consultor_id + status — RBAC scoped queries for consultores
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_leads_consultor_status
        ON leads (consultor_id, status)
        WHERE deleted_at IS NULL AND is_archived = FALSE
    """)


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_leads_consultor_status")
    op.execute("DROP INDEX IF EXISTS ix_leads_criado_em")
    op.execute("DROP INDEX IF EXISTS ix_leads_score_criado_em")
    op.execute("DROP INDEX IF EXISTS ix_leads_status_criado_em")
