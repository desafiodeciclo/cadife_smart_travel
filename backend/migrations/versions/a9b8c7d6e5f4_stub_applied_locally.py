"""stub_applied_locally

Revision ID: a9b8c7d6e5f4
Revises: e8f9a0b1c2d3
Create Date: 2026-05-12

Stub for a migration that was applied directly to the database but never
committed to the repository. The database's alembic_version table records this
revision as the last applied head. The actual schema changes it introduced are
already present in the DB; upgrade/downgrade are intentionally empty so
subsequent migrations can proceed normally.
"""
from alembic import op

revision = "a9b8c7d6e5f4"
down_revision = "e8f9a0b1c2d3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
