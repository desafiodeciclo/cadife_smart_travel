"""create_base_tables_lead_briefing_interacao_agendamento_proposta

Revision ID: dd4f06e3dc70
Revises:
Create Date: 2026-04-22

Creates all base entity tables with:
  - Native PostgreSQL ENUM types (enforced at DB level)
  - CheckConstraints (telefone length, numeric ranges, value positivity)
  - Composite indexes for frequent CRM dashboard query patterns
  - UniqueConstraints (appointment slot deduplication)
  - ON DELETE CASCADE / SET NULL FK cascades

Tables created (in dependency order):
  1. users (referenced by other tables — pre-existing, skip if exists)
  2. leads
  3. briefings (1-to-1 with leads)
  4. interacoes (many-to-1 with leads)
  5. agendamentos (many-to-1 with leads)
  6. propostas (many-to-1 with leads)
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'dd4f06e3dc70'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── users (must exist before leads/agendamentos/propostas FK) ─────────
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if not inspector.has_table('users'):
        op.create_table(
            'users',
            sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column('email', sa.String(255), nullable=False, unique=True),
            sa.Column('nome', sa.String(255), nullable=False),
            sa.Column('hashed_password', sa.String(255), nullable=False),
            sa.Column('perfil', sa.String(20), nullable=False, server_default='agencia'),
            sa.Column('telefone', sa.String(20), nullable=True),
            sa.Column('fcm_token', sa.String(500), nullable=True),
            sa.Column('avatar_url', sa.String(500), nullable=True),
            sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
            sa.Column('criado_em', sa.DateTime(timezone=True),
                      server_default=sa.func.now(), nullable=False),
        )
        op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # ── PostgreSQL ENUM types ──────────────────────────────────────────────
    lead_status_enum = postgresql.ENUM(
        'novo', 'em_atendimento', 'qualificado', 'agendado', 'proposta', 'fechado', 'perdido',
        name='lead_status_enum',
    )
    lead_score_enum = postgresql.ENUM(
        'quente', 'morno', 'frio',
        name='lead_score_enum',
    )
    lead_origem_enum = postgresql.ENUM(
        'whatsapp', 'app', 'web',
        name='lead_origem_enum',
    )
    perfil_viagem_enum = postgresql.ENUM(
        'casal', 'família', 'solo', 'grupo', 'amigos',
        name='perfil_viagem_enum',
    )
    orcamento_perfil_enum = postgresql.ENUM(
        'baixo', 'médio', 'alto', 'premium',
        name='orcamento_perfil_enum',
    )
    tipo_mensagem_enum = postgresql.ENUM(
        'texto', 'audio', 'imagem', 'documento',
        name='tipo_mensagem_enum',
    )
    agendamento_status_enum = postgresql.ENUM(
        'pendente', 'confirmado', 'realizado', 'cancelado',
        name='agendamento_status_enum',
    )
    agendamento_tipo_enum = postgresql.ENUM(
        'online', 'presencial',
        name='agendamento_tipo_enum',
    )
    proposta_status_enum = postgresql.ENUM(
        'rascunho', 'enviada', 'aprovada', 'recusada', 'em_revisao',
        name='proposta_status_enum',
    )

    for enum in [
        lead_status_enum, lead_score_enum, lead_origem_enum,
        perfil_viagem_enum, orcamento_perfil_enum, tipo_mensagem_enum,
        agendamento_status_enum, agendamento_tipo_enum, proposta_status_enum,
    ]:
        enum.create(op.get_bind(), checkfirst=True)

    # ── leads ──────────────────────────────────────────────────────────────
    op.create_table(
        'leads',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('nome', sa.String(255), nullable=True),
        sa.Column('telefone', sa.String(20), nullable=False, unique=True),
        sa.Column('origem', lead_origem_enum, nullable=False, server_default='whatsapp'),
        sa.Column('status', lead_status_enum, nullable=False, server_default='novo'),
        sa.Column('score', lead_score_enum, nullable=True),
        sa.Column('consultor_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('is_archived', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('criado_em', sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column('atualizado_em', sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("length(telefone) >= 10", name="ck_leads_telefone_min_length"),
    )
    # Indexes
    op.create_index('ix_leads_telefone', 'leads', ['telefone'], unique=True)
    op.create_index('ix_leads_status_criado_em', 'leads', ['status', 'criado_em'])
    op.create_index('ix_leads_consultor_status', 'leads', ['consultor_id', 'status'])

    # ── briefings ─────────────────────────────────────────────────────────
    op.create_table(
        'briefings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('lead_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('leads.id', ondelete='CASCADE'), nullable=False, unique=True),
        sa.Column('destino', sa.String(255), nullable=True),
        sa.Column('origem', sa.String(255), nullable=True),
        sa.Column('data_ida', sa.Date, nullable=True),
        sa.Column('data_volta', sa.Date, nullable=True),
        sa.Column('duracao_dias', sa.Integer, nullable=True),
        sa.Column('qtd_pessoas', sa.Integer, nullable=True),
        sa.Column('perfil', perfil_viagem_enum, nullable=True),
        sa.Column('tipo_viagem', postgresql.ARRAY(sa.String), nullable=True),
        sa.Column('preferencias', postgresql.ARRAY(sa.String), nullable=True),
        sa.Column('orcamento', orcamento_perfil_enum, nullable=True),
        sa.Column('tem_passaporte', sa.Boolean, nullable=True),
        sa.Column('observacoes', sa.Text, nullable=True),
        sa.Column('completude_pct', sa.Integer, nullable=False, server_default='0'),
        sa.CheckConstraint("completude_pct BETWEEN 0 AND 100", name="ck_briefings_completude_range"),
        sa.CheckConstraint("qtd_pessoas IS NULL OR qtd_pessoas >= 1", name="ck_briefings_qtd_pessoas_min"),
        sa.CheckConstraint("duracao_dias IS NULL OR duracao_dias >= 1", name="ck_briefings_duracao_min"),
    )
    op.create_index('ix_briefings_lead_id', 'briefings', ['lead_id'], unique=True)

    # ── interacoes ────────────────────────────────────────────────────────
    op.create_table(
        'interacoes',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('lead_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('leads.id', ondelete='CASCADE'), nullable=False),
        sa.Column('mensagem_cliente', sa.Text, nullable=True),
        sa.Column('mensagem_ia', sa.Text, nullable=True),
        sa.Column('tipo_mensagem', tipo_mensagem_enum, nullable=False, server_default='texto'),
        sa.Column('timestamp', sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_interacoes_lead_id', 'interacoes', ['lead_id'])
    op.create_index('ix_interacoes_lead_timestamp', 'interacoes', ['lead_id', 'timestamp'])

    # ── agendamentos ──────────────────────────────────────────────────────
    op.create_table(
        'agendamentos',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('lead_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('leads.id', ondelete='CASCADE'), nullable=False),
        sa.Column('data', sa.Date, nullable=False),
        sa.Column('hora', sa.Time, nullable=False),
        sa.Column('status', agendamento_status_enum, nullable=False, server_default='pendente'),
        sa.Column('tipo', agendamento_tipo_enum, nullable=False, server_default='online'),
        sa.Column('consultor_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('criado_em', sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint('lead_id', 'data', 'hora', name='uq_agendamento_lead_slot'),
    )
    op.create_index('ix_agendamentos_lead_id', 'agendamentos', ['lead_id'])
    op.create_index('ix_agendamentos_lead_status', 'agendamentos', ['lead_id', 'status'])
    op.create_index('ix_agendamentos_consultor_data', 'agendamentos', ['consultor_id', 'data'])

    # ── propostas ─────────────────────────────────────────────────────────
    op.create_table(
        'propostas',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('lead_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('leads.id', ondelete='CASCADE'), nullable=False),
        sa.Column('descricao', sa.Text, nullable=False),
        sa.Column('valor_estimado', sa.Numeric(12, 2), nullable=True),
        sa.Column('status', proposta_status_enum, nullable=False, server_default='rascunho'),
        sa.Column('consultor_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('criado_em', sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint(
            "valor_estimado IS NULL OR valor_estimado >= 0",
            name="ck_propostas_valor_positivo",
        ),
    )
    op.create_index('ix_propostas_lead_id', 'propostas', ['lead_id'])
    op.create_index('ix_propostas_lead_status', 'propostas', ['lead_id', 'status'])
    op.create_index('ix_propostas_consultor_status', 'propostas', ['consultor_id', 'status'])


def downgrade() -> None:
    # Drop tables in reverse dependency order
    op.drop_table('propostas')
    op.drop_table('agendamentos')
    op.drop_table('interacoes')
    op.drop_table('briefings')
    op.drop_table('leads')

    # Drop ENUM types
    for enum_name in [
        'proposta_status_enum', 'agendamento_tipo_enum', 'agendamento_status_enum',
        'tipo_mensagem_enum', 'orcamento_perfil_enum', 'perfil_viagem_enum',
        'lead_origem_enum', 'lead_score_enum', 'lead_status_enum',
    ]:
        op.execute(f"DROP TYPE IF EXISTS {enum_name}")
        
