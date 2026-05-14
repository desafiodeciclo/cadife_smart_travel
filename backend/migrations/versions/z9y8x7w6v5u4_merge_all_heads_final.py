"""merge_all_heads_final

Revision ID: z9y8x7w6v5u4
Revises: 1c5bd7370166, a588336b9d68, j4k5l6m7n8o9
Create Date: 2026-05-13

Final merge migration that unifies all remaining heads:
- travel_id + lead_scoring merge (1c5bd7370166)
- travel_diary + offers + aya_toggle merge (a588336b9d68)
- conversation_summaries sessions (j4k5l6m7n8o9)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'z9y8x7w6v5u4'
down_revision: Union[str, None] = ('1c5bd7370166', 'a588336b9d68', 'j4k5l6m7n8o9')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
