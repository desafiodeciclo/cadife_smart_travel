"""merge heads for travel diary, offers, and aya toggle

Revision ID: a588336b9d68
Revises: 67b69bf11b14, a3b4c5d6e7f8, g1h2i3j4k5l6
Create Date: 2026-05-11 15:47:22.171411

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a588336b9d68'
down_revision: Union[str, None] = ('67b69bf11b14', 'a3b4c5d6e7f8', 'g1h2i3j4k5l6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
