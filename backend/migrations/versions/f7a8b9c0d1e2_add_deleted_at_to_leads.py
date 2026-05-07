"""add_deleted_at_to_leads

Revision ID: f7a8b9c0d1e2
Revises: e8f9a0b1c2d3
Create Date: 2026-05-07

Adds deleted_at column to leads table for soft-delete support.
This column is required by the composite indexes migration.
"""
from alembic import op
import sqlalchemy as sa

revision = 'f7a8b9c0d1e2'
down_revision = 'e8f9a0b1c2d3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'leads',
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True, index=True)
    )


def downgrade() -> None:
    op.drop_column('leads', 'deleted_at')
