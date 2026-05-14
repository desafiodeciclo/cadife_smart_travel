"""stub_merge_k5_j4

Revision ID: 5bf469d38868
Revises: k5l6m7n8o9p0, j4k5l6m7n8o9
Create Date: 2026-05-13

Stub for a merge revision that was applied directly to the database but whose
file was never committed. The schema changes from both parent branches are
already present; upgrade/downgrade are intentionally empty so subsequent
migrations can proceed normally.
"""
from alembic import op

revision = "5bf469d38868"
down_revision = ("k5l6m7n8o9p0", "j4k5l6m7n8o9")
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
