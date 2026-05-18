import asyncio
import json

# Import core models to register their mapping with SQLAlchemy DeclarativeBase
import app.models.lead  # noqa: F401
import app.models.briefing  # noqa: F401
import app.models.interacao  # noqa: F401
import app.models.agendamento  # noqa: F401
import app.models.proposta  # noqa: F401
import app.models.user  # noqa: F401
import app.models.offer  # noqa: F401
import app.models.notification_queue  # noqa: F401
import app.models.dead_letter_queue  # noqa: F401
import app.models.lead_score_history  # noqa: F401
import app.models.documento  # noqa: F401
import app.models.travel_checkpoint  # noqa: F401

from app.core.database import AsyncSessionLocal
from app.services.ai_tools import _get_lead_context_by_wa_id, _check_existing_lead
from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
from app.domain.entities.enums import LeadStatus
from app.infrastructure.security.pii_encryption import hmac_hash

async def main():
    print("Iniciando simulação de teste para correção das ferramentas de IA...")
    
    # Telefone do log que causou o erro
    test_phone = "554791103131"
    
    async with AsyncSessionLocal() as db:
        repo = LeadRepository(db)
        
        # 1. Verificar se o lead de teste já existe no banco
        lead = await repo.get_by_phone(test_phone)
        if not lead:
            print(f"Lead de teste com telefone {test_phone} não encontrado.")
            # Buscar qualquer lead existente para realizar a validação
            from sqlalchemy import select
            from app.infrastructure.persistence.models.lead_model import LeadModel
            result = await db.execute(select(LeadModel).limit(1))
            lead = result.scalar_one_or_none()
            if lead:
                test_phone = lead.telefone
                print(f"Usando lead existente no banco - ID: {lead.id}, Nome: {lead.nome}, Telefone: {test_phone}")
            else:
                print("Nenhum lead encontrado no banco de dados para o teste.")
                return
        else:
            print(f"Lead de teste encontrado - ID: {lead.id}, Nome: {lead.nome}, Status: {lead.status}, Score: {lead.score}")
            
        print("\n--- Testando _get_lead_context_by_wa_id ---")
        try:
            result_context = await _get_lead_context_by_wa_id(test_phone, db)
            parsed_context = json.loads(result_context)
            print("Sucesso! JSON retornado:")
            print(json.dumps(parsed_context, indent=2, ensure_ascii=False))
            assert parsed_context["exists"] is True
            print("Validação do context passada!")
        except Exception as e:
            print(f"FALHA em _get_lead_context_by_wa_id: {e}")
            raise e
            
        print("\n--- Testando _check_existing_lead ---")
        try:
            result_check = await _check_existing_lead(test_phone, db)
            parsed_check = json.loads(result_check)
            print("Sucesso! JSON retornado:")
            print(json.dumps(parsed_check, indent=2, ensure_ascii=False))
            assert parsed_check["exists"] is True
            print("Validação do check passada!")
        except Exception as e:
            print(f"FALHA em _check_existing_lead: {e}")
            raise e

        print("\nTodos os testes de simulação passaram com sucesso! A correção com 'hasattr' funcionou perfeitamente.")

if __name__ == "__main__":
    asyncio.run(main())
