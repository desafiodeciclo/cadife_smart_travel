"""merge travel_id and lead_scoring heads

Revision ID: 1c5bd7370166
Revises: 021932b9a27f, e2d3f4a5b6c7
Create Date: 2026-05-12 14:20:53.224028

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1c5bd7370166'
down_revision: Union[str, None] = ('021932b9a27f', 'e2d3f4a5b6c7')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
