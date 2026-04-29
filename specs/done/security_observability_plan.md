### 🔷 ETAPA 1: PLANO DE IMPLEMENTAÇÃO

#### 1.1 Análise da Task
**O quê foi pedido?**
Implementação de três camadas cruciais para a segurança e observabilidade do backend: Rate Limiting com Redis, Security Headers e Criptografia at-rest de PII (AES/Fernet), além de Auditoria de Logs estruturados em JSON no ciclo de vida das requisições. 

**Por quê é importante?**
Garante que a API seja resiliente a ataques de força bruta ou DDoS (Rate Limit), proteja dados sensíveis em conformidade com regulações como a LGPD (Criptografia PII), e permita o rastreamento preciso de ações e falhas para debug ágil (Logs Estruturados).

**Restrições & Dependências**
- **Tecnologias:** Redis para o counter de Rate Limiting, pacote `cryptography` (Fernet) para AES, implementação própria ou baseada em `slowapi` no FastAPI para limitador, e o módulo `logging` customizado ou `structlog` para logs JSON.
- **Bounded Context:** Transversal (Cross-Cutting Concerns, aplicável ao app core).
- **Dados:** A criptografia de PII afeta as entidades da camada Infrastructure/DB.

---

#### 1.2 Decomposição em Subtarefas

| ID | Subtarefa | Camada | Estimativa | Responsabilidade |
|---|---|---|---|---|
| 1.1 | **Rate Limiting Middleware** | Presentation/Infra | 3h | Configurar Redis, implementar limitador de requests por IP/Rota. |
| 1.2 | **Security Headers Middleware**| Presentation | 1h | Middleware FastAPI para injetar HSTS, CSP, X-Content-Type, etc. |
| 1.3 | **Criptografia PII (Fernet)** | Infrastructure | 2h | Implementar TypeDecorator no SQLAlchemy/SQLModel para campos encriptados transparentes. |
| 1.4 | **Auditoria de Logs (JSON)** | Presentation/Core | 2h | Middleware para interceptar life-cycle e logger JSON para observability. |

**Total Estimado:** 8 horas

---

#### 1.3 Decisões Arquiteturais

**Decisões Específicas:**
- [x] **Qual Bounded Context será afetado?** Transversal / Core (afeta toda a API).
- [x] **Quais entidades do Domain estão envolvidas?** Principalmente `Lead` e `User` (campos como `client_phone`, `nome`, etc).
- [x] **Necessita novo repositório?** Não. A criptografia será feita no nível do ORM (TypeDecorator customizado) para manter a camada de Domain limpa e alheia à criptografia.
- [x] **Padrão de persistência:** O PostgreSQL armazenará as strings encriptadas. O Redis atuará exclusivamente como in-memory storage para os contadores do Rate Limit.
- [x] **Dependências Externas:** Servidor Redis.

---

#### 1.4 Prototipagem / Pseudocódigo

**1. Rate Limiting (Pseudocódigo):**
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address, storage_uri=settings.REDIS_URL)

@app.post("/leads")
@limiter.limit("5/minute")
async def create_lead(request: Request):
    ...
```

**2. Security Headers:**
```python
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    return response
```

**3. Criptografia PII (TypeDecorator):**
```python
from sqlalchemy.types import TypeDecorator, String
from cryptography.fernet import Fernet

fernet = Fernet(settings.ENCRYPTION_KEY)

class EncryptedString(TypeDecorator):
    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            return fernet.encrypt(value.encode()).decode()
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            return fernet.decrypt(value.encode()).decode()
        return value
```

**4. Auditoria de Logs JSON:**
```python
import structlog

@app.middleware("http")
async def audit_log_middleware(request: Request, call_next):
    user_id = getattr(request.state, "user_id", "anonymous")
    logger = structlog.get_logger()
    
    logger.info("request_started", path=request.url.path, method=request.method, user_id=user_id)
    response = await call_next(request)
    logger.info("request_finished", status_code=response.status_code)
    
    return response
```

---

#### 1.5 Testes — Estratégia

**O que será testado?**

| Nível | Tipo | Escopo | Ferramenta |
|---|---|---|---|
| **Unitário** | Domain / Infra | Verificar se o EncryptedString cifra e decifra corretamente a string | `pytest` |
| **Integração** | Infra / Pres. | Testar limite de rate excedido (`429 Too Many Requests`) | `pytest` + `TestClient` |
| **Integração** | Presentation | Verificar se a resposta inclui os Headers de Segurança | `pytest` + `TestClient` |

**Casos de teste (mínimo):**
- ✅ Happy path: Dados gravados via repositório são salvos encriptados e lidos desencriptados sem erro.
- ❌ Rate limit: Disparar 6 requests na rota `/leads` e garantir que a 6ª retorne `429`.
- ✅ Logs: Validar se os outputs de logs durante as chamadas do TestClient estão estruturados em JSON contendo as chaves vitais (`user_id`, `path`, `status_code`).

---

#### 1.6 Checklist Pré-Implementação
- [x] Task compreendida (Escopo claro de Security & Observability)
- [x] Arquitetura definida (Middlewares + Types Customizados do SQLAlchemy)
- [x] Dependências externas mapeadas (Redis, Bibliotecas de Cryptography/Logging)
- [x] Testes planejados
- [ ] Novas Variáveis de ambiente a adicionar (`REDIS_URL`, `ENCRYPTION_KEY`) no `.env.example`
