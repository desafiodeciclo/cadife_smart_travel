"""add_ocasiao_to_briefings

Revision ID: q1r2s3t4u5v6
Revises: p0q1r2s3t4u5
Create Date: 2026-05-14

Adds ocasiao column to briefings table (audit §4.1 — critical).
Structured field prevents the LLM from hallucinating trip occasion into observacoes.

  briefings:
    - ocasiao  ocasiao_viagem_enum (nullable)
      Values: ferias, lua_de_mel, aniversario, familia, negocios, intercambio, outro
"""
from alembic import op

revision = "q1r2s3t4u5v6"
down_revision = "p0q1r2s3t4u5"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ocasiao_viagem_enum') THEN
                CREATE TYPE ocasiao_viagem_enum AS ENUM (
                    'ferias', 'lua_de_mel', 'aniversario', 'familia',
                    'negocios', 'intercambio', 'outro'
                );
            END IF;
        END$$;
        """
    )
    op.execute(
        "ALTER TABLE briefings ADD COLUMN IF NOT EXISTS ocasiao ocasiao_viagem_enum"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE briefings DROP COLUMN IF EXISTS ocasiao")
    op.execute("DROP TYPE IF EXISTS ocasiao_viagem_enum")
