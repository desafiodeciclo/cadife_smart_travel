"""add_manual_lead_origins

Revision ID: f547e5dee9bf
Revises: e7f8a9b0c1d2
Create Date: 2026-05-08 10:44:55.406220

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f547e5dee9bf'
down_revision: Union[str, None] = 'e7f8a9b0c1d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Only run on PostgreSQL because SQLite doesn't strictly enforce Enums
    if op.get_context().dialect.name == 'postgresql':
        with op.get_context().autocommit_block():
            # Postgres 12+ supports IF NOT EXISTS for ADD VALUE
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'indicação'")
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'telefone'")
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'presencial'")
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'rede social'")
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'outro'")
            op.execute("ALTER TYPE lead_origem_enum ADD VALUE IF NOT EXISTS 'manual'")


def downgrade() -> None:
    # PostgreSQL does not support dropping a value from an enum type easily.
    pass
