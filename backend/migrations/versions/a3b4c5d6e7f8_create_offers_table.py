"""create_offers_table

Revision ID: a3b4c5d6e7f8
Revises: f547e5dee9bf
Create Date: 2026-05-09

Creates the offers table with:
  - Native PostgreSQL ENUM types for status and categoria
  - JSONB array compatibility via StringArray (PostgreSQL ARRAY / SQLite JSON)
  - Composite indexes for feed filtering
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "a3b4c5d6e7f8"
down_revision: Union[str, None] = "f547e5dee9bf"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # 1. Create offer_status_enum (idempotent)
    status_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'offer_status_enum')"
        )
    ).scalar()
    if not status_exists:
        sa.Enum(
            "rascunho", "publicada", "encerrada",
            name="offer_status_enum",
        ).create(conn)

    # 2. Create offer_categoria_enum (idempotent)
    cat_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'offer_categoria_enum')"
        )
    ).scalar()
    if not cat_exists:
        sa.Enum(
            "internacional", "nacional", "lua_de_mel",
            "família", "aventura", "cruzeiro", "executivo", "outros",
            name="offer_categoria_enum",
        ).create(conn)

    # 3. Create offers table (idempotent)
    offers_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'offers')"
        )
    ).scalar()
    if not offers_exists:
        op.create_table(
            "offers",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("titulo", sa.String(length=255), nullable=False),
            sa.Column("destino", sa.String(length=255), nullable=False),
            sa.Column("descricao", sa.Text(), nullable=True),
            sa.Column(
                "categoria",
                postgresql.ENUM(
                    "internacional", "nacional", "lua_de_mel",
                    "família", "aventura", "cruzeiro", "executivo", "outros",
                    name="offer_categoria_enum",
                    create_type=False,
                ),
                nullable=False,
            ),
            sa.Column("preco_base", sa.Numeric(12, 2), nullable=True),
            sa.Column("servicos_inclusos", postgresql.ARRAY(sa.String()), nullable=True),
            sa.Column("imagens", postgresql.ARRAY(sa.String()), nullable=True),
            sa.Column("data_saida_sugerida", sa.Date(), nullable=True),
            sa.Column("duracao_dias", sa.Integer(), nullable=True),
            sa.Column(
                "status",
                postgresql.ENUM(
                    "rascunho", "publicada", "encerrada",
                    name="offer_status_enum",
                    create_type=False,
                ),
                nullable=False,
                server_default="rascunho",
            ),
            sa.Column("criado_por", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column(
                "criado_em",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
            sa.Column(
                "atualizado_em",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
            sa.Column(
                "is_deleted",
                sa.Boolean(),
                nullable=False,
                server_default="false",
            ),
            sa.ForeignKeyConstraint(
                ["criado_por"],
                ["users.id"],
                ondelete="CASCADE",
            ),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(
            op.f("ix_offers_status_categoria"), "offers", ["status", "categoria"], unique=False
        )
        op.create_index(
            op.f("ix_offers_criado_em"), "offers", ["criado_em"], unique=False
        )
        op.create_index(
            op.f("ix_offers_criado_por"), "offers", ["criado_por"], unique=False
        )


def downgrade() -> None:
    conn = op.get_bind()

    # Drop offers table
    offers_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'offers')"
        )
    ).scalar()
    if offers_exists:
        op.drop_index(op.f("ix_offers_criado_por"), table_name="offers")
        op.drop_index(op.f("ix_offers_criado_em"), table_name="offers")
        op.drop_index(op.f("ix_offers_status_categoria"), table_name="offers")
        op.drop_table("offers")

    # Drop enums
    for enum_name in ("offer_status_enum", "offer_categoria_enum"):
        exists = conn.execute(
            sa.text(f"SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = '{enum_name}')")
        ).scalar()
        if exists:
            sa.Enum(name=enum_name).drop(conn)
