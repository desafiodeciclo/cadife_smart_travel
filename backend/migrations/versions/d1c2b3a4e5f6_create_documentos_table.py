"""create_documentos_table

Revision ID: d1c2b3a4e5f6
Revises: e8f9a0b1c2d3
Create Date: 2026-05-07

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'd1c2b3a4e5f6'
down_revision = 'e8f9a0b1c2d3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # 1. Create the enum type for document categories (idempotent)
    type_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'documento_categoria_enum')"
        )
    ).scalar()

    if not type_exists:
        documento_categoria_enum = postgresql.ENUM(
            "passagem",
            "voucher",
            "transfer",
            "seguro",
            "itinerario",
            "outros",
            name="documento_categoria_enum",
        )
        documento_categoria_enum.create(conn)

    # 2. Create the table 'documentos' (idempotent)
    table_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'documentos')"
        )
    ).scalar()

    if not table_exists:
        op.create_table(
            "documentos",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("lead_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("nome", sa.String(length=255), nullable=False),
            sa.Column("s3_key", sa.String(length=512), nullable=False),
            sa.Column(
                "categoria",
                postgresql.ENUM(
                    "passagem",
                    "voucher",
                    "transfer",
                    "seguro",
                    "itinerario",
                    "outros",
                    name="documento_categoria_enum",
                    create_type=False,
                ),
                nullable=False,
            ),
            sa.Column("tamanho_bytes", sa.BigInteger(), nullable=False),
            sa.Column("mimetype", sa.String(length=100), nullable=False),
            sa.Column("enviado_por", postgresql.UUID(as_uuid=True), nullable=True),
            sa.Column(
                "criado_em",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
            sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(["enviado_por"], ["users.id"], ondelete="SET NULL"),
            sa.ForeignKeyConstraint(["lead_id"], ["leads.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(
            op.f("ix_documentos_deleted_at"),
            "documentos",
            ["deleted_at"],
            unique=False,
        )
        op.create_index(
            op.f("ix_documentos_lead_id"), "documentos", ["lead_id"], unique=False
        )


def downgrade() -> None:
    op.drop_index(op.f('ix_documentos_lead_id'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_deleted_at'), table_name='documentos')
    op.drop_table('documentos')
    
    # Drop enum type
    sa.Enum(name='documento_categoria_enum').drop(op.get_bind())
