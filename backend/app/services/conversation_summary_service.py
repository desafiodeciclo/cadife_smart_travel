import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.persistence.models.conversation_summary_model import ConversationSummaryModel
from app.infrastructure.persistence.models.interacao_model import InteracaoModel  # wait, check path
from app.services.ai_service import SimpleWindowMemory, get_llm

logger = structlog.get_logger()

async def retry_pending_summaries(db: AsyncSession, batch_size: int = 50) -> int:
    """
    Busca resumos que falharam na geração inicial e tenta novamente.
    """
    stmt = (
        select(ConversationSummaryModel)
        .where(ConversationSummaryModel.resumo_pendente == True)
        .limit(batch_size)
    )
    result = await db.execute(stmt)
    rows = result.scalars().all()
    
    if not rows:
        return 0
        
    resolved = 0
    for row in rows:
        try:
            # Busca as últimas interações do lead para ter contexto
            from app.services import lead_service
            interacoes = await lead_service.get_recent_interacoes(db, row.lead_id, limit=20)
            
            memory = SimpleWindowMemory(k=20)
            for i in range(0, len(interacoes) - 1, 2):
                user_msg = interacoes[i].get("mensagem_cliente", "")
                ai_msg = interacoes[i+1].get("mensagem_ia", "") if i+1 < len(interacoes) else ""
                memory._pending_for_summary.append((user_msg, ai_msg))
            
            await memory.compress_pending(get_llm())
            
            if memory._summary:
                row.resumo_json = {"text": memory._summary}
                row.resumo_pendente = False
                resolved += 1
                
        except Exception as exc:
            logger.warning("retry_summary_failed", lead_id=str(row.lead_id), error=str(exc))
            
    await db.commit()
    return resolved
