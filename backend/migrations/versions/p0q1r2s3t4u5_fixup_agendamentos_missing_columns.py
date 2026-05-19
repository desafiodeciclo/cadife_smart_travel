"""fixup: add missing columns and check constraints to agendamentos

Revision ID: p0q1r2s3t4u5
Revises: 626ebbbeb958
Create Date: 2026-05-19

m8n7o6p5q4r3_agenda_extension was stamped but never executed against this DB.
Enums and indexes were applied, but the 4 columns and 3 CHECK constraints are missing.
This migration adds them idempotently.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "p0q1r2s3t4u5"
down_revision: Union[str, None] = "626ebbbeb958"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # Add columns only if missing (idempotent)
    existing = {
        row[0]
        for row in conn.execute(
            sa.text(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_name = 'agendamentos'"
            )
        )
    }

    if "motivo_bloqueio" not in existing:
        op.add_column(
            "agendamentos",
            sa.Column(
                "motivo_bloqueio",
                postgresql.ENUM(
                    "pausa",
                    "reuniao_interna",
                    "indisponibilidade",
                    "outro",
                    name="motivo_bloqueio_enum",
                    create_type=False,
                ),
                nullable=True,
            ),
        )

    if "notas" not in existing:
        op.add_column(
            "agendamentos",
            sa.Column("notas", sa.String(length=2000), nullable=True),
        )

    if "cancelado_em" not in existing:
        op.add_column(
            "agendamentos",
            sa.Column("cancelado_em", sa.DateTime(timezone=True), nullable=True),
        )

    if "motivo_cancelamento" not in existing:
        op.add_column(
            "agendamentos",
            sa.Column("motivo_cancelamento", sa.String(length=500), nullable=True),
        )

    # Add CHECK constraints only if missing (idempotent)
    existing_constraints = {
        row[0]
        for row in conn.execute(
            sa.text(
                "SELECT conname FROM pg_constraint "
                "WHERE conrelid='agendamentos'::regclass AND contype='c'"
            )
        )
    }

    if "ck_agendamento_bloqueio_no_lead" not in existing_constraints:
        op.create_check_constraint(
            "ck_agendamento_bloqueio_no_lead",
            "agendamentos",
            "(tipo <> 'bloqueio') OR (lead_id IS NULL)",
        )

    if "ck_agendamento_bloqueio_motivo" not in existing_constraints:
        op.create_check_constraint(
            "ck_agendamento_bloqueio_motivo",
            "agendamentos",
            "(tipo <> 'bloqueio') OR (motivo_bloqueio IS NOT NULL)",
        )

    if "ck_agendamento_curadoria_lead" not in existing_constraints:
        op.create_check_constraint(
            "ck_agendamento_curadoria_lead",
            "agendamentos",
            "(tipo = 'bloqueio') OR (lead_id IS NOT NULL)",
        )


def downgrade() -> None:
    op.drop_constraint("ck_agendamento_curadoria_lead", "agendamentos", type_="check")
    op.drop_constraint("ck_agendamento_bloqueio_motivo", "agendamentos", type_="check")
    op.drop_constraint("ck_agendamento_bloqueio_no_lead", "agendamentos", type_="check")
    op.drop_column("agendamentos", "motivo_cancelamento")
    op.drop_column("agendamentos", "cancelado_em")
    op.drop_column("agendamentos", "notas")
    op.drop_column("agendamentos", "motivo_bloqueio")
