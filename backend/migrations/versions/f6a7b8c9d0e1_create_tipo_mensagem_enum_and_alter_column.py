"""create_tipo_mensagem_enum_and_alter_column

Revision ID: f6a7b8c9d0e1
Revises: c4d5e6f7a8b9
Create Date: 2026-05-04

The dd4f06e3dc70 migration was refactored after it had already been applied
to the database (fix/migrations-db PR), switching interacoes.tipo_mensagem
from VARCHAR to tipo_mensagem_enum. The ENUM type therefore never existed in
previously-created databases, causing asyncpg to fail with UndefinedObjectError
on every INSERT into interacoes.

This migration:
  1. Creates tipo_mensagem_enum if it does not exist.
  2. Alters interacoes.tipo_mensagem to use the new ENUM type (from VARCHAR).
"""
from alembic import op
from sqlalchemy.dialects import postgresql

revision = 'f6a7b8c9d0e1'
down_revision = 'c4d5e6f7a8b9'
branch_labels = None
depends_on = None


def upgrade() -> None:
    tipo_mensagem_enum = postgresql.ENUM(
        'texto', 'audio', 'imagem', 'documento',
        name='tipo_mensagem_enum',
    )
    tipo_mensagem_enum.create(op.get_bind(), checkfirst=True)

    op.execute("""
        ALTER TABLE interacoes
        ALTER COLUMN tipo_mensagem TYPE tipo_mensagem_enum
        USING tipo_mensagem::tipo_mensagem_enum
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE interacoes
        ALTER COLUMN tipo_mensagem TYPE VARCHAR(50)
        USING tipo_mensagem::VARCHAR
    """)
    op.execute("DROP TYPE IF EXISTS tipo_mensagem_enum")
