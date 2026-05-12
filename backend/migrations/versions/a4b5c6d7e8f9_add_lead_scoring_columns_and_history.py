"""add_lead_scoring_columns_and_history

Revision ID: a4b5c6d7e8f9
Revises: f547e5dee9bf
Create Date: 2026-05-11

Motor de scoring determinístico (lead-scoring-engine-001).
Adiciona campos numéricos de score à tabela leads e cria tabela de histórico
imutável lead_score_history para auditoria de evolução do score.

Changes:
  - leads: +score_numerico (INTEGER 0–100), +score_calculado_em (TIMESTAMPTZ)
  - CREATE TABLE lead_score_history (auditoria de cada recálculo)
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'a4b5c6d7e8f9'
down_revision = 'f547e5dee9bf'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── 1. Novos campos na tabela leads ───────────────────────────────────
    op.add_column(
        'leads',
        sa.Column('score_numerico', sa.Integer(), nullable=True),
    )
    op.add_column(
        'leads',
        sa.Column(
            'score_calculado_em',
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    # Índice para filtros de dashboard por score numérico
    op.create_index(
        'ix_leads_score_numerico',
        'leads',
        ['score_numerico'],
        unique=False,
    )

    # ── 2. Tabela de histórico de score ───────────────────────────────────
    op.create_table(
        'lead_score_history',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
        ),
        sa.Column(
            'lead_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('leads.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('score_numerico', sa.Integer(), nullable=False),
        sa.Column('score_label', sa.String(10), nullable=False),
        sa.Column('motivo', sa.String(255), nullable=True),
        sa.Column('criterios_json', sa.Text(), nullable=True),
        sa.Column(
            'criado_em',
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    op.create_index(
        'ix_lead_score_history_lead_id',
        'lead_score_history',
        ['lead_id'],
        unique=False,
    )
    op.create_index(
        'ix_lead_score_history_criado_em',
        'lead_score_history',
        ['criado_em'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index('ix_lead_score_history_criado_em', table_name='lead_score_history')
    op.drop_index('ix_lead_score_history_lead_id', table_name='lead_score_history')
    op.drop_table('lead_score_history')

    op.drop_index('ix_leads_score_numerico', table_name='leads')
    op.drop_column('leads', 'score_calculado_em')
    op.drop_column('leads', 'score_numerico')
