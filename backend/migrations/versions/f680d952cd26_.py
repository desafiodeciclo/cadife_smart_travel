"""empty message

Revision ID: f680d952cd26
Revises: 67b69bf11b14, a3b4c5d6e7f8
Create Date: 2026-05-11 21:32:39.867282

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f680d952cd26'
down_revision: Union[str, None] = ('67b69bf11b14', 'a3b4c5d6e7f8')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
