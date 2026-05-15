"""merge_heads_fix

Revision ID: 7c6e7b09bd20
Revises: 626ebbbeb958, 693168e8c4e0
Create Date: 2026-05-15 19:00:06.151432

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7c6e7b09bd20'
down_revision: Union[str, None] = ('626ebbbeb958', '693168e8c4e0')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
