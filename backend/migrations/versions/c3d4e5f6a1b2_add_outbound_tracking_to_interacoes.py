"""add_outbound_tracking_to_interacoes

Revision ID: c3d4e5f6a1b2
Revises: b2c3d4e5f6a1, 63a1b837b445
Create Date: 2026-04-29

Adds outbound send-tracking columns to `interacoes` that exist in the ORM model
but were missing from the original migration:
  - enviado_em   : timestamp when the WhatsApp reply was dispatched
  - status_envio : "sent" | "failed"
  - erro_envio   : error detail on failure
"""
from alembic import op
import sqlalchemy as sa

revision = 'c3d4e5f6a1b2'
down_revision = ('b2c3d4e5f6a1', '63a1b837b445')
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('interacoes', sa.Column('enviado_em', sa.DateTime(timezone=True), nullable=True))
    op.add_column('interacoes', sa.Column('status_envio', sa.String(10), nullable=True))
    op.add_column('interacoes', sa.Column('erro_envio', sa.Text, nullable=True))


def downgrade() -> None:
    op.drop_column('interacoes', 'erro_envio')
    op.drop_column('interacoes', 'status_envio')
    op.drop_column('interacoes', 'enviado_em')
