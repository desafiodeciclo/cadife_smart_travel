"""agenda_extension — bloqueio manual + soft-cancel + nullable lead_id

Revision ID: m8n7o6p5q4r3
Revises: j4k5l6m7n8o9
Create Date: 2026-05-12

Implements gap §3.5 from docs/BACKEND_FRONTEND_PARITY_GAPS.md:
  - Extend enum agendamento_tipo with 'bloqueio' value (manual time block).
  - Create new enum motivo_bloqueio_enum.
  - Add nullable columns: motivo_bloqueio, notas, cancelado_em, motivo_cancelamento.
  - Make lead_id nullable so 'bloqueio' rows do not require a lead.
  - Add CHECK constraints:
      * bloqueio rows must NOT have a lead_id (ck_agendamento_bloqueio_no_lead)
      * bloqueio rows MUST have motivo_bloqueio (ck_agendamento_bloqueio_motivo)
      * curation rows (online|presencial) MUST have a lead_id (ck_agendamento_curadoria_lead)

Notes
-----
Postgres does NOT allow ADD VALUE inside a transaction; the upgrade script
runs with autocommit when possible. We use the IF NOT EXISTS form so the
migration is idempotent on re-runs and safe to run on databases that may
have already had the value added manually.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "m8n7o6p5q4r3"
down_revision: Union[str, None] = "j4k5l6m7n8o9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    # 1. Extend existing enum agendamento_tipo_enum with 'bloqueio'.
    #    ADD VALUE IF NOT EXISTS is supported on PG ≥ 10 and outside a tx.
    with op.get_context().autocommit_block():
        op.execute(
            "ALTER TYPE agendamento_tipo_enum ADD VALUE IF NOT EXISTS 'bloqueio'"
        )

    # 2. Create motivo_bloqueio enum.
    motivo_enum = postgresql.ENUM(
        "pausa",
        "reuniao_interna",
        "indisponibilidade",
        "outro",
        name="motivo_bloqueio_enum",
    )
    motivo_enum.create(bind, checkfirst=True)

    # 3. Add nullable columns.
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
    op.add_column(
        "agendamentos",
        sa.Column("notas", sa.String(length=2000), nullable=True),
    )
    op.add_column(
        "agendamentos",
        sa.Column("cancelado_em", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "agendamentos",
        sa.Column("motivo_cancelamento", sa.String(length=500), nullable=True),
    )

    # 4. Make lead_id nullable. Existing rows already have lead_id NOT NULL
    #    so this is a safe widening of the column.
    op.alter_column("agendamentos", "lead_id", nullable=True)

    # 5. CHECK constraints (DB-level invariants for the bloqueio model).
    op.create_check_constraint(
        "ck_agendamento_bloqueio_no_lead",
        "agendamentos",
        "(tipo <> 'bloqueio') OR (lead_id IS NULL)",
    )
    op.create_check_constraint(
        "ck_agendamento_bloqueio_motivo",
        "agendamentos",
        "(tipo <> 'bloqueio') OR (motivo_bloqueio IS NOT NULL)",
    )
    op.create_check_constraint(
        "ck_agendamento_curadoria_lead",
        "agendamentos",
        "(tipo = 'bloqueio') OR (lead_id IS NOT NULL)",
    )


def downgrade() -> None:
    # Drop check constraints first (depend on columns).
    op.drop_constraint(
        "ck_agendamento_curadoria_lead", "agendamentos", type_="check"
    )
    op.drop_constraint(
        "ck_agendamento_bloqueio_motivo", "agendamentos", type_="check"
    )
    op.drop_constraint(
        "ck_agendamento_bloqueio_no_lead", "agendamentos", type_="check"
    )

    # Re-tighten lead_id to NOT NULL. Any 'bloqueio' rows must be removed first
    # because their lead_id is NULL by design.
    op.execute("DELETE FROM agendamentos WHERE tipo = 'bloqueio'")
    op.alter_column("agendamentos", "lead_id", nullable=False)

    # Drop new columns.
    op.drop_column("agendamentos", "motivo_cancelamento")
    op.drop_column("agendamentos", "cancelado_em")
    op.drop_column("agendamentos", "notas")
    op.drop_column("agendamentos", "motivo_bloqueio")

    # Drop motivo_bloqueio enum.
    op.execute("DROP TYPE IF EXISTS motivo_bloqueio_enum")

    # NOTE: Postgres does not support removing a value from an enum without
    # recreating it. The 'bloqueio' value is left in agendamento_tipo_enum
    # after downgrade — it just becomes unused. This is acceptable and
    # consistent with the project's existing migration practice (the same
    # is done for other enum-extension migrations in this codebase).
