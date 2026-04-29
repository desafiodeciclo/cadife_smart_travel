"""add_telefone_hash_to_leads

Revision ID: b2c3d4e5f6a1
Revises: a1b2c3d4e5f6
Create Date: 2026-04-28

Fernet é não-determinístico (IV aleatório por chamada), então não pode
ser usado em cláusulas WHERE. Adiciona telefone_hash (HMAC-SHA256) para
lookups determinísticos sem expor o número em texto plano no banco.
"""
from alembic import op
import sqlalchemy as sa

revision = 'b2c3d4e5f6a1'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('leads', sa.Column('telefone_hash', sa.String(64), nullable=True))
    op.create_index('ix_leads_telefone_hash', 'leads', ['telefone_hash'], unique=True)
    # nullable=True temporariamente para não quebrar registros existentes;
    # em produção rodar script de backfill antes de tornar NOT NULL.


def downgrade() -> None:
    op.drop_index('ix_leads_telefone_hash', table_name='leads')
    op.drop_column('leads', 'telefone_hash')
