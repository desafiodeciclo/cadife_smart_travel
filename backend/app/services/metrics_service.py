import uuid
from datetime import datetime, timezone
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.proposta_model import PropostaModel

async def get_consultor_metrics(db: AsyncSession, user_id: uuid.UUID):
    # Leads total and qualified
    # Qualified = anything beyond 'novo' usually, but let's follow the suggested list:
    # ["qualificado", "agendado", "proposta", "fechado"]
    
    lead_q = select(
        func.count().label("total"),
        func.count().filter(LeadModel.status.in_(["qualificado", "agendado", "proposta", "fechado"])).label("qualificados"),
        func.count().filter(LeadModel.status == "fechado").label("fechados"),
    ).where(LeadModel.consultor_id == user_id, LeadModel.deletado_em.is_(None))
    
    lead_res = await db.execute(lead_q)
    lead_row = lead_res.one()
    
    # Propostas enviadas
    prop_q = select(func.count()).where(
        PropostaModel.consultor_id == user_id,
        PropostaModel.status.in_(["enviada", "aprovada", "recusada"])
    )
    prop_res = await db.execute(prop_q)
    propostas_enviadas = prop_res.scalar_one()
    
    total = lead_row.total
    fechados = lead_row.fechados
    
    return {
        "leads_total": total,
        "leads_qualificados": lead_row.qualificados,
        "propostas_enviadas": propostas_enviadas,
        "vendas_fechadas": fechados,
        "taxa_conversao": (fechados / total) if total > 0 else 0.0,
        "gerado_em": datetime.now(timezone.utc)
    }
