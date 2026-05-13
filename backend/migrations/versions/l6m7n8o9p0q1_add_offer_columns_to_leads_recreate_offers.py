"""add_offer_columns_to_leads_recreate_offers

Revision ID: l6m7n8o9p0q1
Revises: k5l6m7n8o9p0, j4k5l6m7n8o9
Create Date: 2026-05-13

Fixes schema drift introduced by the offer feature branch:

1. Adds `offer_interest` value to lead_origem_enum.
2. Drops and recreates the `offers` table with the correct English-named
   columns and updated offer_status_enum values (draft/published/sold_out/
   expired/archived).  The old migration (a3b4c5d6e7f8) used Portuguese
   column names and stale enum values — this migration corrects that.
3. Adds missing columns `client_id`, `offer_id`, `budget` to `leads`.
4. Creates the `lead_offers` tracking table.
"""
from typing import Union

from alembic import op
import sqlalchemy as sa

revision: str = "l6m7n8o9p0q1"
down_revision: Union[str, None] = "5bf469d38868"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # ------------------------------------------------------------------
    # 1. Add `offer_interest` to lead_origem_enum (idempotent)
    # ------------------------------------------------------------------
    has_offer_interest = conn.execute(
        sa.text(
            "SELECT EXISTS("
            "  SELECT 1 FROM pg_enum e"
            "  JOIN pg_type t ON t.oid = e.enumtypid"
            "  WHERE t.typname = 'lead_origem_enum'"
            "    AND e.enumlabel = 'offer_interest'"
            ")"
        )
    ).scalar()
    if not has_offer_interest:
        # ADD VALUE cannot run inside a transaction block in older PG versions;
        # the COMMIT trick is needed only for PG < 12. PG 12+ supports it in
        # transactions. Using raw execute to stay safe.
        op.execute("ALTER TYPE lead_origem_enum ADD VALUE 'offer_interest'")

    # ------------------------------------------------------------------
    # 2. Rebuild the `offers` table with correct schema
    # ------------------------------------------------------------------
    # Drop dependents first
    op.execute("DROP TABLE IF EXISTS lead_offers CASCADE")
    op.execute("DROP TABLE IF EXISTS offers CASCADE")

    # Drop stale enum types
    for enum_name in ("offer_status_enum", "offer_categoria_enum"):
        exists = conn.execute(
            sa.text(
                f"SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = '{enum_name}')"
            )
        ).scalar()
        if exists:
            op.execute(f"DROP TYPE {enum_name} CASCADE")

    op.execute(
        "CREATE TYPE offer_status_enum AS ENUM "
        "('draft', 'published', 'sold_out', 'expired', 'archived')"
    )

    # Use raw SQL to avoid server_default escaping issues with JSON / enum columns
    op.execute(
        """
        CREATE TABLE offers (
            id                    UUID PRIMARY KEY,
            agency_id             UUID NOT NULL REFERENCES users(id),
            title                 VARCHAR(255) NOT NULL,
            description           TEXT NOT NULL,
            destination           VARCHAR(255) NOT NULL,
            destination_image_url VARCHAR(500),
            departure_date        TIMESTAMPTZ NOT NULL,
            return_date           TIMESTAMPTZ NOT NULL,
            booking_deadline      TIMESTAMPTZ NOT NULL,
            duration_days         INTEGER NOT NULL,
            accommodations        JSON NOT NULL DEFAULT '[]',
            included_services     JSON NOT NULL DEFAULT '[]',
            travelers             INTEGER NOT NULL DEFAULT 1,
            available_spots       INTEGER NOT NULL,
            spots_reserved        INTEGER NOT NULL DEFAULT 0,
            base_price            NUMERIC(12,2) NOT NULL,
            currency              VARCHAR(3) NOT NULL DEFAULT 'BRL',
            discounts             JSON,
            final_price           NUMERIC(12,2) NOT NULL,
            highlights            JSON NOT NULL DEFAULT '[]',
            amenities             JSON NOT NULL DEFAULT '[]',
            status                offer_status_enum NOT NULL DEFAULT 'draft',
            views                 INTEGER NOT NULL DEFAULT 0,
            interests             INTEGER NOT NULL DEFAULT 0,
            conversions           INTEGER NOT NULL DEFAULT 0,
            created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
            published_at          TIMESTAMPTZ,
            is_deleted            BOOLEAN NOT NULL DEFAULT false
        )
        """
    )
    op.execute("CREATE INDEX ix_offers_agency_id   ON offers (agency_id)")
    op.execute("CREATE INDEX ix_offers_title        ON offers (title)")
    op.execute("CREATE INDEX ix_offers_destination  ON offers (destination)")
    op.execute("CREATE INDEX ix_offers_departure    ON offers (departure_date)")
    op.execute("CREATE INDEX ix_offers_deadline     ON offers (booking_deadline)")
    op.execute("CREATE INDEX ix_offers_status       ON offers (status)")
    op.execute("CREATE INDEX ix_offers_published_at ON offers (published_at)")
    op.execute("CREATE INDEX ix_offers_status_dest  ON offers (status, destination)")

    # ------------------------------------------------------------------
    # 3. Add missing columns to `leads` (idempotent)
    # ------------------------------------------------------------------
    op.execute(
        "ALTER TABLE leads "
        "ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES users(id) ON DELETE SET NULL"
    )
    op.execute(
        "ALTER TABLE leads "
        "ADD COLUMN IF NOT EXISTS offer_id UUID REFERENCES offers(id) ON DELETE SET NULL"
    )
    op.execute(
        "ALTER TABLE leads ADD COLUMN IF NOT EXISTS budget NUMERIC(12,2)"
    )

    # ------------------------------------------------------------------
    # 4. Create lead_offers tracking table
    # ------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE lead_offers (
            id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            offer_id   UUID NOT NULL REFERENCES offers(id)  ON DELETE CASCADE,
            client_id  UUID NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
            lead_id    UUID NOT NULL REFERENCES leads(id)   ON DELETE CASCADE,
            agency_id  UUID NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT uq_offer_client_interest UNIQUE (offer_id, client_id)
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS lead_offers CASCADE")
    op.execute(
        "ALTER TABLE leads "
        "DROP COLUMN IF EXISTS client_id, "
        "DROP COLUMN IF EXISTS offer_id, "
        "DROP COLUMN IF EXISTS budget"
    )
    op.execute("DROP TABLE IF EXISTS offers CASCADE")
    op.execute("DROP TYPE IF EXISTS offer_status_enum CASCADE")
