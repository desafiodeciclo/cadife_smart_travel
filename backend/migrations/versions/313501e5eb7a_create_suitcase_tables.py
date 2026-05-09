"""create_suitcase_tables

Revision ID: 313501e5eb7a
Revises: d1c2b3a4e5f6
Create Date: 2026-05-08 16:31:00.335328

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '313501e5eb7a'
down_revision: Union[str, None] = 'd1c2b3a4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # 1. Create suitcase_category_enum (idempotent)
    cat_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'suitcase_category_enum')"
        )
    ).scalar()
    if not cat_exists:
        sa.Enum(
            'documentos', 'roupas', 'higiene', 'eletrônicos', 'saúde', 'acessórios', 'outros',
            name='suitcase_category_enum'
        ).create(conn)

    # 2. Create destination_type_enum (idempotent)
    dest_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'destination_type_enum')"
        )
    ).scalar()
    if not dest_exists:
        sa.Enum(
            'praia', 'frio', 'urbano', 'aventura',
            name='destination_type_enum'
        ).create(conn)

    # 3. Create suitcase_suggestions table (idempotent)
    sug_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'suitcase_suggestions')"
        )
    ).scalar()
    if not sug_exists:
        op.create_table(
            'suitcase_suggestions',
            sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
            sa.Column('tipo_destino', postgresql.ENUM('praia', 'frio', 'urbano', 'aventura', name='destination_type_enum', create_type=False), nullable=False),
            sa.Column('categoria', postgresql.ENUM('documentos', 'roupas', 'higiene', 'eletrônicos', 'saúde', 'acessórios', 'outros', name='suitcase_category_enum', create_type=False), nullable=False),
            sa.Column('nome', sa.String(length=255), nullable=False),
            sa.Column('quantidade_sugerida', sa.Integer(), nullable=False),
            sa.Column('descricao', sa.String(length=512), nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_suitcase_suggestions_tipo_destino'), 'suitcase_suggestions', ['tipo_destino'], unique=False)

    # 4. Create suitcase_items table (idempotent)
    items_exists = conn.execute(
        sa.text(
            "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'suitcase_items')"
        )
    ).scalar()
    if not items_exists:
        op.create_table(
            'suitcase_items',
            sa.Column('id', sa.UUID(), nullable=False),
            sa.Column('lead_id', sa.UUID(), nullable=False),
            sa.Column('user_id', sa.UUID(), nullable=False),
            sa.Column('categoria', postgresql.ENUM('documentos', 'roupas', 'higiene', 'eletrônicos', 'saúde', 'acessórios', 'outros', name='suitcase_category_enum', create_type=False), nullable=False),
            sa.Column('nome', sa.String(length=255), nullable=False),
            sa.Column('quantidade', sa.Integer(), nullable=False),
            sa.Column('empacotado', sa.Boolean(), nullable=False),
            sa.Column('criado_em', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
            sa.Column('atualizado_em', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
            sa.ForeignKeyConstraint(['lead_id'], ['leads.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_suitcase_items_lead_id'), 'suitcase_items', ['lead_id'], unique=False)
        op.create_index(op.f('ix_suitcase_items_user_id'), 'suitcase_items', ['user_id'], unique=False)


def downgrade() -> None:
    # Drop suitcase_items
    items_exists = op.get_bind().execute(
        sa.text("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'suitcase_items')")
    ).scalar()
    if items_exists:
        op.drop_index(op.f('ix_suitcase_items_user_id'), table_name='suitcase_items')
        op.drop_index(op.f('ix_suitcase_items_lead_id'), table_name='suitcase_items')
        op.drop_table('suitcase_items')

    # Drop suitcase_suggestions
    sug_exists = op.get_bind().execute(
        sa.text("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'suitcase_suggestions')")
    ).scalar()
    if sug_exists:
        op.drop_index(op.f('ix_suitcase_suggestions_tipo_destino'), table_name='suitcase_suggestions')
        op.drop_table('suitcase_suggestions')

    # Drop enums
    conn = op.get_bind()
    for enum_name in ('suitcase_category_enum', 'destination_type_enum'):
        exists = conn.execute(
            sa.text(f"SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = '{enum_name}')")
        ).scalar()
        if exists:
            sa.Enum(name=enum_name).drop(conn)
