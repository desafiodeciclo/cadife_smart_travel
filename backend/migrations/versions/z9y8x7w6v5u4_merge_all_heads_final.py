"""merge_all_heads_final

Revision ID: z9y8x7w6v5u4
Revises: 1c5bd7370166, o9p0q1r2s3t4, m8n7o6p5q4r3, m6n7o8p9q0r1
Create Date: 2026-05-13

Final merge migration that unifies all remaining heads:
- travel_id + lead_scoring merge (1c5bd7370166)
- fix_enum_drift + offers + aya_toggle merge (o9p0q1r2s3t4)
- agenda_extension + conversation_summaries sessions (m8n7o6p5q4r3)
- settings_and_profile (m6n7o8p9q0r1)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'z9y8x7w6v5u4'
down_revision: Union[str, None] = ('o9p0q1r2s3t4', 'm8n7o6p5q4r3', 'm6n7o8p9q0r1')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
