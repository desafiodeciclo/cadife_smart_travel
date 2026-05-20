"""create lead_assignment_cursor singleton table

Revision ID: r3s4t5u6v7w8
Revises: q2r3s4t5u6v7
Create Date: 2026-05-19

Tabela singleton para o cursor de round-robin de auto-atribuição de leads.
Linha única com id fixo é semeada no upgrade para que SELECT FOR UPDATE
sempre encontre algo a travar.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "r3s4t5u6v7w8"
down_revision: Union[str, None] = "q2r3s4t5u6v7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


SINGLETON_ID = "00000000-0000-0000-0000-000000000001"


def upgrade() -> None:
    op.create_table(
        "lead_assignment_cursor",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "last_assigned_user_id", postgresql.UUID(as_uuid=True), nullable=True
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["last_assigned_user_id"],
            ["users.id"],
            ondelete="SET NULL",
        ),
    )
    # Seed singleton row so SELECT FOR UPDATE always finds a target.
    op.execute(
        sa.text(
            "INSERT INTO lead_assignment_cursor (id, last_assigned_user_id) "
            f"VALUES ('{SINGLETON_ID}', NULL)"
        )
    )


def downgrade() -> None:
    op.drop_table("lead_assignment_cursor")
