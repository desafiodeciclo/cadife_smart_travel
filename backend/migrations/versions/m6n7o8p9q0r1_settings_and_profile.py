"""settings_and_profile — agency_settings + message_templates + sale_goals + users.bio

Revision ID: m6n7o8p9q0r1
Revises: k5l6m7n8o9p0
Create Date: 2026-05-12

Implements PRD `docs/prd/PRD-agency-settings-and-consultor-profile.md`:
  - users.bio (VARCHAR(500) NULL)         — profile of consultant
  - sale_goals                            — monthly sales targets per user
  - agency_settings                       — operating hours + notification prefs
  - message_templates                     — reusable message templates with placeholders

Schema is multi-tenant ready: agency_settings and message_templates carry an
`agency_id` column (default = singleton UUID for the current single Cadife Tour
deployment). When the system goes multi-tenant, drop the default and route
agency_id from JWT claims.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "m6n7o8p9q0r1"
down_revision: Union[str, None] = "k5l6m7n8o9p0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


SINGLETON_AGENCY_ID = "00000000-0000-0000-0000-000000000001"


def upgrade() -> None:
    # ── 1. users.bio ────────────────────────────────────────────────────────
    # avatar_url already exists; only bio is missing.
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(500) NULL")

    # ── 2. sale_goals ───────────────────────────────────────────────────────
    op.create_table(
        "sale_goals",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("period_year", sa.Integer, nullable=False),
        sa.Column("period_month", sa.Integer, nullable=False),
        sa.Column("target", sa.Integer, nullable=False, server_default="0"),
        sa.Column("achieved", sa.Integer, nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "user_id", "period_year", "period_month", name="uq_sale_goal_user_period"
        ),
        sa.CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_sale_goal_month"),
        sa.CheckConstraint("target >= 0", name="ck_sale_goal_target"),
        sa.CheckConstraint("achieved >= 0", name="ck_sale_goal_achieved"),
    )
    op.create_index(
        "idx_sale_goals_user_period",
        "sale_goals",
        ["user_id", "period_year", "period_month"],
    )

    # ── 3. agency_settings ──────────────────────────────────────────────────
    op.create_table(
        "agency_settings",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "agency_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
            server_default=sa.text(f"'{SINGLETON_AGENCY_ID}'::uuid"),
        ),
        sa.Column(
            "horario_funcionamento",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text(
                '\'{"dias"\\:[1,2,3,4,5],"inicio"\\:"09:00","fim"\\:"16:00"}\'::jsonb'
            ),
        ),
        sa.Column(
            "notificacoes_prefs",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text(
                '\'{"leads_qualificados"\\:true,"novos_leads"\\:true,"propostas_aprovadas"\\:true,"agendamentos_confirmados"\\:true}\'::jsonb'
            ),
        ),
        sa.Column(
            "updated_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.UniqueConstraint("agency_id", name="uq_agency_settings_agency"),
    )

    # Seed singleton row so the first GET works without a write.
    op.execute(
        f"""
        INSERT INTO agency_settings (id, agency_id)
        VALUES (gen_random_uuid(), '{SINGLETON_AGENCY_ID}'::uuid)
        ON CONFLICT (agency_id) DO NOTHING
        """
    )

    # ── 4. message_templates ────────────────────────────────────────────────
    op.create_table(
        "message_templates",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "agency_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
            server_default=sa.text(f"'{SINGLETON_AGENCY_ID}'::uuid"),
        ),
        sa.Column("nome", sa.String(length=100), nullable=False),
        sa.Column("categoria", sa.String(length=50), nullable=False),
        sa.Column("conteudo", sa.Text, nullable=False),
        sa.Column(
            "variaveis",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("ativo", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("deletado_em", sa.TIMESTAMP(timezone=True), nullable=True),
        sa.CheckConstraint(
            "categoria IN ('boas_vindas','lembrete','pos_curadoria','follow_up','proposta','outro')",
            name="ck_template_categoria",
        ),
    )
    op.create_index(
        "idx_templates_active",
        "message_templates",
        ["agency_id", "categoria"],
        postgresql_where=sa.text("deletado_em IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("idx_templates_active", table_name="message_templates")
    op.drop_table("message_templates")

    op.drop_table("agency_settings")

    op.drop_index("idx_sale_goals_user_period", table_name="sale_goals")
    op.drop_table("sale_goals")

    op.drop_column("users", "bio")
