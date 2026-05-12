"""merge_heads_add_deletado_em

Revision ID: g1h2i3j4k5l6
Revises: a3b4c5d6e7f8, 67b69bf11b14
Create Date: 2026-05-11

Merges the two open heads (offers table and travel diary) and adds the
`deletado_em` timestamp column to `leads` for spec-compliant soft delete.

Previously soft delete only set `is_archived=True` (boolean) without a
timestamp. The spec requires `deletado_em` (TIMESTAMPTZ) so audit trails
can show when a lead was archived.

Both `is_archived` (boolean flag, backward-compat) and `deletado_em`
(timestamp) are kept. Existing archived leads will have `deletado_em=NULL`
until the next soft-delete operation.
"""
from typing import Union
from alembic import op
import sqlalchemy as sa

revision: str = 'g1h2i3j4k5l6'
down_revision: Union[tuple, None] = ('a3b4c5d6e7f8', '67b69bf11b14')
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE leads ADD COLUMN IF NOT EXISTS deletado_em TIMESTAMPTZ NULL"
    )


def downgrade() -> None:
    op.drop_column('leads', 'deletado_em')
