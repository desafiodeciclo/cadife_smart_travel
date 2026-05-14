"""merge_all_branches_add_deletado_em

Revision ID: k5l6m7n8o9p0
Revises: 1c5bd7370166, g1h2i3j4k5l6
Create Date: 2026-05-12

Merges the two open heads:
  - 1c5bd7370166: chain lead-scoring + documentos travel_id + diary + offers
  - g1h2i3j4k5l6: aya-toggle feature branch (f6a7b8c9d0e1 → aya_ativo + aya_toggle_history)

Also adds `deletado_em` (TIMESTAMPTZ) to leads for spec-compliant soft delete.
Previously only `is_archived` (boolean) existed; both are kept for backward
compatibility — existing archived leads will have deletado_em=NULL until the
next soft-delete operation.
"""
from typing import Union

from alembic import op
import sqlalchemy as sa

revision: str = "k5l6m7n8o9p0"
down_revision: Union[tuple, None] = ("1c5bd7370166", "g1h2i3j4k5l6")
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE leads ADD COLUMN IF NOT EXISTS deletado_em TIMESTAMPTZ NULL"
    )


def downgrade() -> None:
    op.drop_column("leads", "deletado_em")
