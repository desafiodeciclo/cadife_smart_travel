"""merge lead scoring migration with developer heads

Revision ID: 021932b9a27f
Revises: f680d952cd26, a4b5c6d7e8f9
Create Date: 2026-05-12 10:08:21.396751

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '021932b9a27f'
down_revision: Union[str, None] = ('f680d952cd26', 'a4b5c6d7e8f9')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
