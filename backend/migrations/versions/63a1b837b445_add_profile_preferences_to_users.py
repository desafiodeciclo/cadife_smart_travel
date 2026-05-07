"""add_profile_preferences_to_users

Revision ID: 63a1b837b445
Revises: b2c3d4e5f6a1
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '63a1b837b445'
down_revision: Union[str, None] = 'b2c3d4e5f6a1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('tipo_viagem', postgresql.ARRAY(sa.String()), nullable=True))
    op.add_column('users', sa.Column('preferencias', postgresql.ARRAY(sa.String()), nullable=True))
    op.add_column('users', sa.Column('tem_passaporte', sa.Boolean(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'tem_passaporte')
    op.drop_column('users', 'preferencias')
    op.drop_column('users', 'tipo_viagem')
