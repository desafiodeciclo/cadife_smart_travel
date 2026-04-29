"""alter_leads_columns_for_pii_encryption

Revision ID: a1b2c3d4e5f6
Revises: dd4f06e3dc70
Create Date: 2026-04-28

Fernet-encrypted PII values (telefone, nome) are ~88-120 chars in base64.
Previous VARCHAR(20) and VARCHAR(255) are too short for ciphertext storage.
Also drops the plain-text length CheckConstraint on telefone — meaningless
when the stored value is ciphertext, not the raw phone number.
"""
from alembic import op
import sqlalchemy as sa

revision = 'a1b2c3d4e5f6'
down_revision = 'dd4f06e3dc70'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        'leads', 'telefone',
        existing_type=sa.String(20),
        type_=sa.String(512),
        existing_nullable=False,
    )
    op.alter_column(
        'leads', 'nome',
        existing_type=sa.String(255),
        type_=sa.String(512),
        existing_nullable=True,
    )
    op.execute('ALTER TABLE leads DROP CONSTRAINT IF EXISTS ck_leads_telefone_min_length')


def downgrade() -> None:
    op.create_check_constraint(
        'ck_leads_telefone_min_length', 'leads', 'length(telefone) >= 10'
    )
    op.alter_column(
        'leads', 'nome',
        existing_type=sa.String(512),
        type_=sa.String(255),
        existing_nullable=True,
    )
    op.alter_column(
        'leads', 'telefone',
        existing_type=sa.String(512),
        type_=sa.String(20),
        existing_nullable=False,
    )
