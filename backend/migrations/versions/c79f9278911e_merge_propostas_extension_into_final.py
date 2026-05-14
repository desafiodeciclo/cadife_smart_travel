"""merge_propostas_extension_into_final

Revision ID: c79f9278911e
Revises: n7o8p9q0r1s2, z9y8x7w6v5u4
Create Date: 2026-05-14 11:48:33.242485

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c79f9278911e'
down_revision: Union[str, None] = ('n7o8p9q0r1s2', 'z9y8x7w6v5u4')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
