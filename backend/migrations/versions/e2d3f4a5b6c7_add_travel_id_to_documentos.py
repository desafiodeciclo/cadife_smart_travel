"""add_travel_id_to_documentos

Revision ID: e2d3f4a5b6c7
Revises: d1c2b3a4e5f6
Create Date: 2026-05-12

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'e2d3f4a5b6c7'
down_revision = 'd1c2b3a4e5f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # Idempotently add travel_id column
    column_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.columns "
            "WHERE table_name = 'documentos' AND column_name = 'travel_id')"
        )
    ).scalar()

    if not column_exists:
        op.add_column(
            "documentos",
            sa.Column(
                "travel_id",
                postgresql.UUID(as_uuid=True),
                nullable=True,
            ),
        )
        op.create_index(
            op.f("ix_documentos_travel_id"),
            "documentos",
            ["travel_id"],
            unique=False,
        )

    # FK only when travels table exists — it may not be created yet in all envs
    travels_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables "
            "WHERE table_schema='public' AND table_name='travels')"
        )
    ).scalar()
    fk_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.table_constraints "
            "WHERE constraint_name='fk_documentos_travels')"
        )
    ).scalar()
    if travels_exists and not fk_exists:
        op.create_foreign_key(
            "fk_documentos_travels",
            "documentos",
            "travels",
            ["travel_id"],
            ["id"],
            ondelete="SET NULL",
        )


def downgrade() -> None:
    op.drop_index(op.f("ix_documentos_travel_id"), table_name="documentos")
    op.drop_constraint("fk_documentos_travels", "documentos", type_="foreignkey")
    op.drop_column("documentos", "travel_id")
