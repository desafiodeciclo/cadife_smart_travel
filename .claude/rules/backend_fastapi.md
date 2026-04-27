# Regra de Comportamento: Backend FastAPI — Cadife Smart Travel

## Contexto

Para manter consistência no backend Python FastAPI do Cadife Smart Travel, garantindo o SLA crítico do webhook Meta (HTTP 200 em ≤ 5s), a segurança dos endpoints e o padrão assíncrono em todo o sistema.

## Instruções para o Claude

### Regra 1 — Webhook SEMPRE retorna 200 antes da IA processar

**Sempre** use `BackgroundTasks` para todo processamento que envolva IA ou chamadas externas.

Exemplo Aceito:
```python
@router.post("/webhook/whatsapp")
async def receive_whatsapp(
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    payload = await request.json()
    background_tasks.add_task(process_incoming_message, payload, db)
    return {"status": "received"}
```

Exemplo Recusado:
```python
@router.post("/webhook/whatsapp")
async def receive_whatsapp(payload: dict, db: AsyncSession = Depends(get_db)):
    response = await ai_service.process(payload, db)  # IA síncrona = timeout Meta
    return response
```

### Regra 2 — Validar assinatura do webhook antes de processar

**Sempre** valide `X-Hub-Signature-256` para toda requisição `POST /webhook/whatsapp`.

Exemplo Aceito:
```python
async def verify_whatsapp_signature(request: Request, settings: Settings = Depends(get_settings)):
    signature = request.headers.get("X-Hub-Signature-256", "")
    body = await request.body()
    expected = hmac.new(settings.WHATSAPP_TOKEN.encode(), body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(f"sha256={expected}", signature):
        raise HTTPException(status_code=403, detail="Invalid signature")
```

Exemplo Recusado:
```python
@router.post("/webhook/whatsapp")
async def receive_whatsapp(payload: dict):
    # Processar sem validar assinatura = vulnerabilidade crítica
    await process(payload)
```

### Regra 3 — Type hints e Pydantic obrigatórios

**Sempre** declare tipos em toda função pública. **Nunca** use `dict` como tipo de retorno de endpoint.

Exemplo Aceito:
```python
class LeadCreate(BaseModel):
    telefone: str
    origem: LeadOrigem = LeadOrigem.whatsapp
    nome: Optional[str] = None

@router.post("/leads", response_model=LeadResponse, status_code=201)
async def create_lead(lead_in: LeadCreate, db: AsyncSession = Depends(get_db)) -> LeadResponse:
    return await lead_service.create(db, lead_in)
```

Exemplo Recusado:
```python
@router.post("/leads")
async def create_lead(lead_in: dict):  # dict não tem validação
    return {"ok": True}               # retorno sem tipagem
```

### Regra 4 — Soft delete em leads

**Nunca** delete fisicamente registros de leads. Use campo `deleted_at` ou `is_archived`.

Exemplo Aceito:
```python
@router.delete("/leads/{lead_id}", status_code=204)
async def archive_lead(lead_id: UUID, db: AsyncSession = Depends(get_db)) -> None:
    await lead_service.soft_delete(db, lead_id)  # sets is_archived=True
```

Exemplo Recusado:
```python
@router.delete("/leads/{lead_id}")
async def delete_lead(lead_id: UUID, db: AsyncSession = Depends(get_db)):
    await db.delete(lead)  # exclusão física — proibido
    await db.commit()
```

### Regra 5 — Logs estruturados com contexto

**Sempre** inclua `lead_id`, `action` e `endpoint` nos logs de operações críticas.

Exemplo Aceito:
```python
import structlog
logger = structlog.get_logger()

async def process_incoming_message(payload: dict, db: AsyncSession) -> None:
    phone = extract_phone(payload)
    logger.info("message_received", phone=phone, source="whatsapp")
    lead = await lead_service.get_or_create_by_phone(db, phone)
    logger.info("lead_updated", lead_id=str(lead.id), status=lead.status)
```

### Regra 6 — Credenciais exclusivamente via Settings

**Nunca** hardcode tokens, chaves ou senhas. **Sempre** use a classe `Settings`.

Exemplo Aceito:
```python
# app/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    WHATSAPP_TOKEN: str
    OPENAI_API_KEY: str
    JWT_SECRET_KEY: str
    DATABASE_URL: str

    class Config:
        env_file = ".env"
```

Exemplo Recusado:
```python
WHATSAPP_TOKEN = "EAABx..."  # token hardcoded no código = vazamento garantido
```

### Regra 7 — Proteção JWT em todos os endpoints privados

**Sempre** use `Depends(get_current_user)` em endpoints que retornam dados de leads, briefings ou usuários.

Exemplo Aceito:
```python
@router.get("/leads", response_model=list[LeadResponse])
async def list_leads(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[LeadResponse]:
    return await lead_service.list_all(db)
```

Endpoints **isentos** de JWT: `GET /webhook/whatsapp`, `POST /webhook/whatsapp`, `GET /health`, `POST /auth/login`, `POST /auth/refresh`.
