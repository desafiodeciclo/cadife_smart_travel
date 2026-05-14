"""fix_enum_drift_lead_origem_proposta_status_suitcase

Revision ID: o9p0q1r2s3t4
Revises: n8o9p0q1r2s3
Create Date: 2026-05-13

Corrige drift acumulado entre enums Python e tipos PostgreSQL:

1. lead_origem_enum — adiciona 5 valores presentes no Python mas ausentes no banco:
   indicação, telefone, presencial, rede social, outro

2. proposta_status_enum — adiciona 'expirada', usado pelo job de expiração automática
   mas nunca incluído via migration.

3. suitcase_category_enum — os valores com acento (eletrônicos, saúde, acessórios)
   que o banco tem não batem com os valores sem acento do Python enum.
   Renomeia os valores acentuados para sem acento via pg_catalog.
"""
from typing import Union

from alembic import op
import sqlalchemy as sa

revision: str = "o9p0q1r2s3t4"
down_revision: Union[str, None] = "n8o9p0q1r2s3"
branch_labels = None
depends_on = None


def _enum_has_value(conn, type_name: str, value: str) -> bool:
    return conn.execute(
        sa.text(
            "SELECT EXISTS("
            "  SELECT 1 FROM pg_enum e"
            "  JOIN pg_type t ON t.oid = e.enumtypid"
            "  WHERE t.typname = :type AND e.enumlabel = :val"
            ")"
        ),
        {"type": type_name, "val": value},
    ).scalar()


def upgrade() -> None:
    conn = op.get_bind()

    # ------------------------------------------------------------------
    # 1. lead_origem_enum — 5 valores faltantes
    # ------------------------------------------------------------------
    for val in ("indicação", "telefone", "presencial", "rede social", "outro"):
        if not _enum_has_value(conn, "lead_origem_enum", val):
            op.execute(f"ALTER TYPE lead_origem_enum ADD VALUE '{val}'")

    # ------------------------------------------------------------------
    # 2. proposta_status_enum — adiciona 'expirada'
    # ------------------------------------------------------------------
    if not _enum_has_value(conn, "proposta_status_enum", "expirada"):
        op.execute("ALTER TYPE proposta_status_enum ADD VALUE 'expirada'")

    # ------------------------------------------------------------------
    # 3. suitcase_category_enum — renomear valores acentuados para sem acento
    #    UPDATE pg_enum.enumlabel é a forma correta para PG >= 9.1
    # ------------------------------------------------------------------
    accented_to_plain = {
        "eletrônicos": "eletronicos",
        "saúde": "saude",
        "acessórios": "acessorios",
    }
    for old_val, new_val in accented_to_plain.items():
        if _enum_has_value(conn, "suitcase_category_enum", old_val):
            conn.execute(
                sa.text(
                    "UPDATE pg_enum SET enumlabel = :new"
                    "  WHERE enumlabel = :old"
                    "    AND enumtypid = ("
                    "      SELECT oid FROM pg_type WHERE typname = 'suitcase_category_enum'"
                    "    )"
                ),
                {"old": old_val, "new": new_val},
            )


def downgrade() -> None:
    # Não é possível remover valores de ENUM no PostgreSQL sem recriar o tipo.
    # O downgrade apenas reverte os labels do suitcase_category_enum.
    conn = op.get_bind()

    plain_to_accented = {
        "eletronicos": "eletrônicos",
        "saude": "saúde",
        "acessorios": "acessórios",
    }
    for old_val, new_val in plain_to_accented.items():
        if _enum_has_value(conn, "suitcase_category_enum", old_val):
            conn.execute(
                sa.text(
                    "UPDATE pg_enum SET enumlabel = :new"
                    "  WHERE enumlabel = :old"
                    "    AND enumtypid = ("
                    "      SELECT oid FROM pg_type WHERE typname = 'suitcase_category_enum'"
                    "    )"
                ),
                {"old": old_val, "new": new_val},
            )
