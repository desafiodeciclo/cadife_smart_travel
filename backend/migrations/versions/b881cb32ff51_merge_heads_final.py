"""merge_heads_final

Revision ID: b881cb32ff51
Revises: o9p0q1r2s3t4, z9y8x7w6v5u4
Create Date: 2026-05-14 13:01:17.781892

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b881cb32ff51'
down_revision: Union[str, None] = ('o9p0q1r2s3t4', 'z9y8x7w6v5u4')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
