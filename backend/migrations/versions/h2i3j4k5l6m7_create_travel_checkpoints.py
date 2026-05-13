"""create_travel_checkpoints

Revision ID: h2i3j4k5l6m7
Revises: g1h2i3j4k5l6
Create Date: 2026-05-12

Creates the travel_checkpoints table to track ordered milestones in the
travel lifecycle (feat/travel-checkpoints-progress-001).

Schema decisions:
- unique(lead_id, checkpoint): idempotency enforced at DB level — the service
  can call activate_checkpoint() safely on every trigger without extra checks.
- ativado_por VARCHAR(64): accepts either a UUID string (consultor user_id)
  or the literal 'sistema' (automated triggers / cron).
- ON DELETE CASCADE: checkpoints are meaningless without the lead.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import ENUM as PG_ENUM, UUID

revision: str = "h2i3j4k5l6m7"
down_revision: Union[str, None] = "k5l6m7n8o9p0"
branch_labels = None
depends_on = None

CHECKPOINT_VALUES = (
    "BRIEFING_COLETADO",
    "CURADORIA_INICIADA",
    "PROPOSTA_ENVIADA",
    "PROPOSTA_APROVADA",
    "VIAGEM_CONFIRMADA",
    "VIAGEM_EM_ANDAMENTO",
    "VIAGEM_CONCLUIDA",
)


def upgrade() -> None:
    conn = op.get_bind()
    type_exists = conn.execute(
        sa.text("SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'travel_checkpoint_enum')")
    ).scalar()
    if not type_exists:
        op.execute(
            "CREATE TYPE travel_checkpoint_enum AS ENUM ("
            + ", ".join(f"'{v}'" for v in CHECKPOINT_VALUES)
            + ")"
        )

    op.create_table(
        "travel_checkpoints",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "lead_id",
            UUID(as_uuid=True),
            sa.ForeignKey("leads.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "checkpoint",
            PG_ENUM(*CHECKPOINT_VALUES, name="travel_checkpoint_enum", create_type=False),
            nullable=False,
        ),
        sa.Column(
            "ativado_em",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("ativado_por", sa.String(64), nullable=False),
    )

    op.create_index("ix_travel_checkpoints_lead_id", "travel_checkpoints", ["lead_id"])
    op.create_unique_constraint(
        "uq_travel_checkpoints_lead_checkpoint",
        "travel_checkpoints",
        ["lead_id", "checkpoint"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_travel_checkpoints_lead_checkpoint", "travel_checkpoints", type_="unique"
    )
    op.drop_index("ix_travel_checkpoints_lead_id", table_name="travel_checkpoints")
    op.drop_table("travel_checkpoints")
    op.execute("DROP TYPE travel_checkpoint_enum")
