"""add_meet_link_to_agendamentos

Revision ID: p0q1r2s3t4u5
Revises: o9p0q1r2s3t4
Create Date: 2026-05-13

Adds meet_link column to agendamentos table to store the Google Meet URL
generated automatically when a curation appointment is created.

  agendamentos:
    - meet_link  VARCHAR(512) NULLABLE — Google Meet URL (hangoutLink)
"""
from alembic import op

revision = "p0q1r2s3t4u5"
down_revision = "o9p0q1r2s3t4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE agendamentos "
        "ADD COLUMN IF NOT EXISTS meet_link VARCHAR(512)"
    )


def downgrade() -> None:
    op.execute(
        "ALTER TABLE agendamentos DROP COLUMN IF EXISTS meet_link"
    )
