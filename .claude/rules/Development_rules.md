# 📋 CADIFE SMART TRAVEL — Development Rules v1.0

> **REGRAS VINCULANTES PARA O DESENVOLVIMENTO DO MVP**  
> *Prazo: 25 dias | Status: Em Desenvolvimento | Versão: 1.0.0*

---

## 🎯 1. REGRAS CRÍTICAS (Bloqueadores)

Estas regras **NÃO PODEM SER QUEBRADAS** sob nenhuma circunstância.

### 1.1 Webhook WhatsApp — Resposta em Tempo Real
- ✅ **OBRIGATÓRIO:** Todo webhook deve responder com HTTP `200` em **até 5 segundos** (timeout da Meta)
- ✅ **OBRIGATÓRIO:** Processamento pesado (IA, BD) deve ser **assíncrono** via fila (Celery, Redis, RabbitMQ)
- ✅ **OBRIGATÓRIO:** Webhook responde imediatamente com `200 OK`, processamento continua em background
- ✅ **OBRIGATÓRIO:** Validar `VERIFY_TOKEN` **antes** de qualquer processamento
- ⚠️ **CRÍTICO:** Se webhook demorar > 5 segundos, Meta desconecta e re-tenta (cascata de erros)

### 1.2 Lead Nunca Pode Ser Perdido
- ✅ **OBRIGATÓRIO:** Toda mensagem do WhatsApp gera um registro de `ConversationLog` antes do processamento
- ✅ **OBRIGATÓRIO:** Se a IA falhar, a mensagem é armazenada em `failed_processing_queue` para retry manual
- ✅ **OBRIGATÓRIO:** Lead criado com dados do briefing extraído automaticamente
- ✅ **OBRIGATÓRIO:** Persistência no banco de dados **sempre** antes de responder ao cliente

### 1.3 Segurança — Nenhuma Credencial no Código
- 🔒 **OBRIGATÓRIO:** Todas as credenciais **APENAS** em `.env` (nunca hardcoded)
- 🔒 **OBRIGATÓRIO:** `.env` **NUNCA** commitado no Git (adicionar a `.gitignore`)
- 🔒 **OBRIGATÓRIO:** Variáveis obrigatórias: `WHATSAPP_TOKEN`, `OPENAI_API_KEY`, `JWT_SECRET_KEY`, `DATABASE_URL`, `FIREBASE_CREDENTIALS`, `VERIFY_TOKEN`, `PHONE_NUMBER_ID`
- 🔒 **OBRIGATÓRIO:** HTTPS em todos os endpoints (webhook + API + FCM)
- 🔒 **OBRIGATÓRIO:** Tokens JWT com expiração: access token 1h, refresh token 7d

### 1.4 IA Não Pode Prometer Preços ou Orçamentos
- 🚫 **BLOQUEADOR:** Prompt base **explicitamente** proíbe: geração de preços, promessas de desconto, orçamentos automáticos
- 🚫 **BLOQUEADOR:** Todas as respostas da IA são **validadas** antes de enviar ao cliente
- 🚫 **BLOQUEADOR:** Logs de todas as respostas IA devem ser armazenados para revisão (auditoria)
- 🚫 **BLOQUEADOR:** Se a IA gera resposta inadequada, deve haver fallback para "Vou conectar com um consultor"

### 1.5 Comunicação em Tempo Real (< 2 segundos)
- ⚡ **OBRIGATÓRIO:** Notificação push FCM ao consultor em **< 2 segundos** após lead ser criado
- ⚡ **OBRIGATÓRIO:** Dashboard deve exibir novo lead em tempo real (WebSocket ou polling rápido)
- ⚡ **CRÍTICO:** Se notificação demorar > 2s, usar cache e message queues

---

## 📐 2. REGRAS ARQUITETURAIS

### 2.1 Separação de Camadas (Não Violar)
```
Camada 1: ENTRADA (WhatsApp Webhook)
    ↓ (POST /webhook/whatsapp)
Camada 2: PROCESSAMENTO (Orquestrador + IA + RAG)
    ↓ (async via background task)
Camada 3: PERSISTÊNCIA (Banco de Dados + Vector DB)
    ↓ (queries estruturadas)
Camada 4: APRESENTAÇÃO (App Frontend + FCM)
```

**REGRA:** Cada camada deve ser independente. Frontend NUNCA chama IA diretamente, sempre via API Backend.

### 2.2 Backend — Padrão de Código
- ✅ **OBRIGATÓRIO:** Usar [STACK_BACKEND] com Pydantic para validação de schemas
- ✅ **OBRIGATÓRIO:** Async/await em todo o fluxo (`async def`, `await`)
- ✅ **OBRIGATÓRIO:** Router pattern: endpoints em arquivos separados (`/routes/whatsapp.py`, `/routes/leads.py`, `/routes/auth.py`)
- ✅ **OBRIGATÓRIO:** Services layer: lógica de negócio em `services/` (ex: `ai_service.py`, `lead_service.py`)
- ✅ **OBRIGATÓRIO:** Models em ORM (SQLAlchemy ou Mongoengine) com relacionamentos claros
- ✅ **OBRIGATÓRIO:** Todas as exceções devem ser tratadas e logadas
- ✅ **OBRIGATÓRIO:** HTTP status codes corretos: 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 500 Server Error

### 2.3 IA / RAG — Padrão
- ✅ **OBRIGATÓRIO:** [STACK_AI] + OpenAI GPT para orquestração de chains
- ✅ **OBRIGATÓRIO:** RAG com ChromaDB (dev) ou PGVector (prod)
- ✅ **OBRIGATÓRIO:** Chunks de base de conhecimento **testados antes da Fase 2** (validar retrieval)
- ✅ **OBRIGATÓRIO:** Memória de conversação persistida por `conversation_id` no banco
- ✅ **OBRIGATÓRIO:** Chain de prompts com clara separação: contexto → pergunta → extração de entidades → resposta
- ✅ **OBRIGATÓRIO:** Fallback sempre pronto: se IA não conseguir responder com confiança, redirecionar para consultor

### 2.4 Frontend — Padrão de Componentes
- ✅ **OBRIGATÓRIO:** [STACK_FRONTEND] com multiplataforma (Android + iOS + Web)
- ✅ **OBRIGATÓRIO:** Componentização: cada tela é um componente reutilizável
- ✅ **OBRIGATÓRIO:** Estado centralizado (Redux, Zustand ou Context API)
- ✅ **OBRIGATÓRIO:** Dois perfis isolados: Cliente (tracking) e Agência (CRM)
- ✅ **OBRIGATÓRIO:** Loading, success, error states **obrigatórios** em todas as ações
- ✅ **OBRIGATÓRIO:** Temas de design clean e premium alinhado à identidade visual da empresa

### 2.5 Banco de Dados — Schema Obrigatório
**Tabelas Mínimas (não remover):**

```
✅ users (id, email, password_hash, role, phone, created_at)
✅ conversations (id, user_id, user_phone, whatsapp_id, status, created_at, updated_at)
✅ conversation_messages (id, conversation_id, sender, content, metadata, timestamp)
✅ leads (id, conversation_id, user_id, briefing_data, score, status, created_at, updated_at)
✅ briefing_data (id, lead_id, destination, dates, party_size, budget, preferences, extracted_at)
✅ notifications (id, user_id, lead_id, type, read, created_at)
✅ audit_log (id, action, user_id, resource_type, resource_id, timestamp)
```

**REGRA:** Nenhuma migração sem backup. Rollback sempre testado.

---

## 🚀 3. REGRAS DE FLUXO / PROCESSAMENTO

### 3.1 Fluxo WhatsApp → App (Sequência Obrigatória)

1. Cliente envia mensagem no WhatsApp
2. WhatsApp Cloud API → webhook `POST /webhook/whatsapp`
3. Backend valida `VERIFY_TOKEN` e estructura payload
4. ✅ **Responde HTTP 200 imediatamente** (antes de processar)
5. Cria `ConversationLog` com timestamp (fallback se falhar depois)
6. Envia para fila assíncrona (Celery + Redis):
   - Chamar [STACK_AI] com RAG
   - Extrair dados estruturados (briefing)
   - Avaliar se briefing completo → criar/atualizar `Lead`
7. Enviar resposta ao cliente via `send_message()` WhatsApp API
8. Notificar agência via FCM `firebase_send_notification()`
9. Atualizar `conversations` status + timestamp
10. Dashboard App exibe novo lead em tempo real

### 3.2 Score de Qualificação de Lead (Fórmula)
```
SCORE = (completude_briefing * 0.5) + (nível_interesse * 0.3) + (urgência * 0.2)

completude_briefing = (campos_preenchidos / total_campos) * 100
- Campos: destino, datas, num_pessoas, orçamento, tipo_viagem
- Se >= 80% → "Lead Quente"

nível_interesse = análise de sentimentos + ação (pergunta detalhada = +25)
- Neutro = 0 | Morno = 5 | Quente = 10

urgência = se mencionou datas próximas (+10) ou timeframe urgente (+5)
```

**REGRA:** Score recalculado a cada mensagem. Lead só é criado se score >= 5.

### 3.3 Tratamento de Mídia (Áudio / Imagem)
- ✅ Se cliente enviar áudio: transcrever via OpenAI Whisper → processar como texto
- ✅ Se cliente enviar imagem: armazenar em objeto storage (S3/GCS), não processar IA diretamente
- ✅ Responder sempre com mensagem amigável: "Entendi a imagem/áudio, vou processar!"
- ⚠️ **NÃO BLOQUEAR:** Se falhar transcrição, continuar atendimento com fallback

### 3.4 Rate Limiting
- ✅ **OBRIGATÓRIO:** Rate limit no webhook: máx 10 requisições por segundo por IP
- ✅ **OBRIGATÓRIO:** Rate limit na IA: máx 5 chamadas simultâneas por conversation
- ✅ **OBRIGATÓRIO:** Responder com HTTP 429 se limite excedido
- ✅ **OBRIGATÓRIO:** Logs de tentativas excedidas para análise de abuso

---

## 🧪 4. REGRAS DE TESTE E QUALIDADE

### 4.1 Definition of Done (DoD) — Nada é Pronto Sem Isto

Uma tarefa é **DONE** apenas se:

- ✅ Código desenvolvido e funcionando em ambiente **dev** (não produção)
- ✅ Testado (testes manuais OU automatizados — conforme complexidade)
- ✅ Integrado ao branch principal **sem conflitos**
- ✅ **Sem erros críticos ou bugs bloqueantes**
- ✅ Validado por **MÍNIMO 2 membros do time** (incluindo PO para features de negócio)
- ✅ **Documentado** em Swagger (se API) ou comentários (se lógica complexa)
- ✅ Code review aprovado (PR comentada e aprovada antes de merge)

### 4.2 Testes Obrigatórios (por Fase)

**Fase 1 (Dias 1–6) — Backend + Auth**
- ✅ Teste webhook mock (simular payload WhatsApp)
- ✅ Teste JWT (geração, validação, expiração)
- ✅ Teste HTTPS e VERIFY_TOKEN
- ✅ Teste rate limiting

**Fase 2 (Dias 7–13) — IA + RAG**
- ✅ Teste 10 perguntas de validação (definidas pelo PO)
- ✅ Teste extração de briefing em 20 conversas (>= 80% precisão)
- ✅ Teste RAG retrieval (chunks corretos recuperados)
- ✅ Teste fallback quando IA incerta

**Fase 3 (Dias 14–20) — Frontend + Notificações**
- ✅ Teste FCM delivery em < 2s (cronometrado)
- ✅ Teste fluxo completo WhatsApp → App (ponta a ponta)
- ✅ Teste perfil Cliente (visualizar status viagem)
- ✅ Teste perfil Agência (visualizar e gerenciar leads)
- ✅ Teste UI/UX em Android + iOS

**Fase 4 (Dias 21–25) — Documentação + Deploy**
- ✅ Swagger documentado e acessível (`/docs`)
- ✅ Docker builds sem erro
- ✅ Docker Compose com todos os serviços rodando
- ✅ Teste de erro e recuperação (resiliência)

### 4.3 Critérios de Sucesso do MVP (Verificáveis)

| Critério | Meta | Teste |
|----------|------|-------|
| Mensagem WhatsApp → App | < 2s | Cronometrado (10 tentativas) |
| IA responde corretamente | 10/10 perguntas PO | Validação manual pelo PO |
| Briefing extraído | >= 80% precisão | 20 conversas testadas |
| Lead criado automaticamente | 100% | Verificação BD + Dashboard |
| Notificação push | < 2s | Teste de dois dispositivos |
| App exibe leads | Dados estruturados | Validação visual PO |
| Fluxo ponta a ponta | Zero erros críticos | Demo ao PO |
| Mídia tratada | Sem erros | Envio de áudio/imagem |
| Documentação API | Acessível | URL `/docs` funciona |

---

## 🔒 5. REGRAS DE SEGURANÇA E PRIVACIDADE

### 5.1 Dados Sensíveis
- 🔒 **NUNCA** armazenar senhas em texto plano (usar bcrypt com salt)
- 🔒 **NUNCA** logar tokens, chaves API ou dados de cartão de crédito
- 🔒 **NUNCA** expor IDs internos em URLs públicas (usar UUID)
- 🔒 Mascarar números de telefone em logs (ex: `+55 9 8801-****`)

### 5.2 Autenticação e Autorização
- ✅ JWT com expiração configurável: access token 1h, refresh token 7d
- ✅ Endpoints protegidos exigem bearer token válido
- ✅ Roles (admin, consultor, cliente) com verificação em cada request
- ✅ Refresh token deve regenerar um novo refresh token (rotating refresh)

### 5.3 Auditoria
- ✅ Logs estruturados de **todas** as ações críticas:
  - Login/logout
  - Criação de lead
  - Modificação de lead
  - Envio de notificações
  - Erros críticos
- ✅ `audit_log` tabela com: `user_id, action, resource_type, resource_id, timestamp, details`
- ✅ Retenção de logs por **mínimo 90 dias** (requisito legal)

### 5.4 Validação de Input
- ✅ **Whitelist approach:** validar o que se **aceita**, não o que se **rejeita**
- ✅ Validar comprimento, tipo, formato de **todas** as entradas
- ✅ Escape de HTML/JS em campos de texto (prevenção de XSS)
- ✅ Prepared statements em queries de BD (prevenção de SQL injection)

---

## 📅 6. REGRAS DE COMUNICAÇÃO E SPRINTS

### 6.1 Ceremony Schedule (Fixo)
- **Segunda 10h:** Sprint Planning (próximas 2 semanas)
- **Terça 14h:** Daily Standup (5 min, síncrono)
- **Quarta 14h:** Tech Review (validação técnica)
- **Sexta 15h:** Demo + Retrospective (ao PO, stakeholders)

### 6.2 Sprint Board (Kanban)
Colunas obrigatórias:
```
BACKLOG → TO DO → IN PROGRESS → CODE REVIEW → TESTING → DONE
```

**REGRA:** 
- Máximo **3 tarefas** por pessoa em "IN PROGRESS"
- Mínimo **2 aprovações** antes de passar para "DONE"
- Task não pode ficar em "CODE REVIEW" > 4h (bottleneck)

### 6.3 Comunicação de Bloqueadores
- ⚠️ **CRÍTICO:** Se estiver bloqueado > 30 min, avisar imediatamente no Slack/chat
- ⚠️ **CRÍTICO:** Bloqueador técnico = parar e escalar para Tech Lead
- ⚠️ **CRÍTICO:** Bloqueador de negócio = parar e escalar para PO

### 6.4 Code Review Checklist
Antes de fazer merge, verificar:

```
☐ Código segue padrão da codebase
☐ Sem credenciais hardcoded
☐ Testes passando (manual ou automatizado)
☐ Documentado (comentários em lógica complexa)
☐ Sem erros de linting
☐ Nenhum console.log() ou print() de debug deixado
☐ Performance aceitável (sem N+1 queries)
☐ Sem merge conflicts não resolvidos
```

---

## 📊 7. REGRAS DE PRIORIZAÇÃO (Ordem Fixa)

### Fase 1 — Dias 1–6 (Backend + Auth)
1. Webhook WhatsApp + validação (CRÍTICO)
2. JWT Auth (CRÍTICO)
3. Setup BD + migrations (CRÍTICO)
4. HTTPS + segurança base (CRÍTICO)

### Fase 2 — Dias 7–13 (IA + RAG)
1. [STACK_AI] + OpenAI integration (CRÍTICO)
2. RAG setup com base de conhecimento (CRÍTICO)
3. Extração de briefing (CRÍTICO)
4. Score de qualificação (ALTA)
5. Logs e auditoria (ALTA)

### Fase 3 — Dias 14–20 (Frontend + Notificações)
1. App [STACK_FRONTEND] — Perfil Agência/CRM (CRÍTICO)
2. Firebase FCM + notificações push (CRÍTICO)
3. App — Perfil Cliente (ALTA)
4. Agendamento de curadoria (MÉDIA)

### Fase 4 — Dias 21–25 (Polish + Deploy)
1. Documentação Swagger (MÉDIA)
2. Docker + Docker Compose (BAIXA)
3. Tratamento de mídia (MÉDIA)
4. QA final + testes de carga (ALTA)

---

## 🎭 8. REGRAS DE RISCO E MITIGAÇÃO

### 8.1 Risco: Timeout do Webhook (> 5s)
**Probabilidade:** Média | **Impacto:** Alto

- ✅ **Mitigação:** Processamento 100% assíncrono
- ✅ **Teste:** Cronometrar webhook em dev antes de Fase 1 terminar
- ✅ **Fallback:** Se timeout, Meta re-tenta automaticamente (máx 5x)
- ✅ **Monitoramento:** Alerta se webhook demorar > 3s (antes de atingir timeout)

### 8.2 Risco: IA Alucina Preços/Promessas
**Probabilidade:** Alta | **Impacto:** Alto

- ✅ **Mitigação:** Prompt base com restrições explícitas (NÃO GERE PREÇOS)
- ✅ **Validação:** Todas as respostas IA validadas antes de enviar
- ✅ **Auditoria:** Log de 100% das respostas para revisão humana
- ✅ **Fallback:** Se detectar preço/promessa, resposta automática: "Vou conectar com um consultor"

### 8.3 Risco: Base RAG Incompleta/Ruim
**Probabilidade:** Alta | **Impacto:** Médio

- ✅ **Mitigação:** PO valida e complementa base na Fase 1
- ✅ **Teste:** 10 chunks testados e aprovados antes de Fase 2
- ✅ **Iteração:** Feedback do consultor → melhorar prompts + chunks
- ✅ **Fallback:** Se RAG não encontra resposta, redireciona para consultor

### 8.4 Risco: Prazo Curto (25 dias)
**Probabilidade:** Alta | **Impacto:** Médio

- ✅ **Mitigação:** MVP estritamente funcional, features extras → backlog
- ✅ **Priorização rígida:** Sprint Planning obrigatório todo sprint
- ✅ **Daily sync:** Standup 5 min diário (remover bloqueadores rápido)
- ✅ **Respaldo:** Pair programming em integrações críticas

### 8.5 Risco: Desalinhamento técnico do time
**Probabilidade:** Média | **Impacto:** Médio

- ✅ **Mitigação:** Pair programming em [STACK_BACKEND], [STACK_AI], [STACK_FRONTEND]
- ✅ **Conhecimento:** [NOME_DO_MEMBRO_AI] apoia parte de IA
- ✅ **Padrão:** [NOME_DO_MEMBRO_BACKEND] garante arquitetura consistente
- ✅ **Documentation:** README com setup local + arquitetura visual

---

## 🔧 9. REGRAS DE INFRAESTRUTURA E DEPLOY

### 9.1 Ambientes
```
LOCAL (dev) → STAGING → PRODUCTION

✅ LOCAL: Mock da WhatsApp API (ngrok), ChromaDB, SQLite ou PostgreSQL local
✅ STAGING: Real WhatsApp API (webhook), PostgreSQL, PGVector, FCM real, SSL
✅ PRODUCTION: Real API, todas as credenciais de prod, SSL, backups 24h
```

### 9.2 Variáveis de Ambiente (por Ambiente)

**LOCAL (.env.local):**
- Debug = true
- DB = SQLite
- Chroma = ./chroma_db local
- WhatsApp mock (ngrok)

**STAGING (.env.staging):**
- Debug = false
- DB = PostgreSQL real
- Chroma = PGVector
- WhatsApp Cloud API real
- FCM credenciais reais

**PRODUCTION (.env.production):**
- Debug = false
- DB = PostgreSQL prod (backup 24h)
- Chroma = PGVector prod
- WhatsApp Cloud API
- FCM credenciais prod
- HTTPS obrigatório
- Rate limiting rigoroso

### 9.3 Docker
- ✅ Dockerfile por serviço (backend, frontend, db, redis, chroma)
- ✅ Docker Compose orquestra todos (docker-compose.yml)
- ✅ Imagens leves (base Alpine quando possível)
- ✅ Health checks configurados

### 9.4 Deployment Checklist
```
☐ Todos os testes passando
☐ Código auditado (security scan)
☐ Variáveis de ambiente validadas
☐ Backup do banco realizado
☐ Migrações testadas
☐ Rollback plan preparado
☐ Monitoring e alertas configurados
```

---

## 📚 10. REGRAS DE DOCUMENTAÇÃO

### 10.1 O que Documentar (Obrigatório)
- ✅ README.md (setup local, arquitetura visual, como rodar)
- ✅ API Swagger (todos os endpoints `/docs`)
- ✅ Architecture Decision Records (ADRs) — decisões técnicas importantes
- ✅ Prompt base da IA (copiar exato usado em produção)
- ✅ Schema de BD (ERD diagram)
- ✅ Fluxo ponta a ponta (sequência diagrama)

### 10.2 Comentários no Código
- ✅ **Lógica complexa:** comentar o PORQUÊ, não o QUÊ
- ✅ **Async/await:** comentar se há ordem específica de processamento
- ✅ **RAG retrieval:** detalhar qual chunk é usado e por quê
- ✅ **Rate limiting:** explicar threshold e motivo

### 10.3 Exemplo de ADR (Architecture Decision Record)

```markdown
# ADR-001: Usar [STACK_BACKEND] ao invés de Node.js

## Contexto
Precisamos de uma API com integração forte com IA/LLM

## Decisão
Usar [STACK_BACKEND] com async/await

## Consequências
✅ Melhor integração com OpenAI e Langchain
✅ Async nativo
❌ Menos familiaridade de alguns membros

## Data: 2025-06-15
## Decided by: [NOME_DO_MEMBRO_BACKEND]
```

---

## 📋 Anexo A: Checklist de Kickoff

Antes de começar Fase 1, validar:

```
☐ Repositório Git criado e estrutura inicial pronta
☐ Variáveis .env.example documentadas
☐ Acesso a credenciais: Meta, OpenAI, Firebase
☐ Setup local funciona (backend + frontend rodam sem erro)
☐ Webhook mock pronto (ngrok ou similar)
☐ Todos os membros com acesso a Jira/Trello e repositório
☐ Primeira daily sync marcada
☐ Base de conhecimento RAG preliminar compartilhada
☐ Prompt base versão 0.1 revisada pelo PO
☐ Plano de contingência criado (o que fazer se alguém sair)
```

---

## 📋 Anexo B: Comando Referência (Git)

```bash
# Criar branch
git checkout -b feature/webhook-whatsapp

# Commit com mensagem clara
git commit -m "feat: implementar webhook WhatsApp com validação"

# Fazer push
git push origin feature/webhook-whatsapp

# Abrir Pull Request no GitHub/GitLab
# Aguardar 2 aprovações antes de merge

# Merge ao main
git checkout main
git merge feature/webhook-whatsapp
```

---

## 📌 Referências Rápidas

- **WhatsApp Cloud API:** https://developers.facebook.com/docs/whatsapp/cloud-api
- **Prompt Injection Prevention:** https://owasp.org/www-community/attacks/Prompt_Injection
- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **JWT.io:** https://jwt.io
- **Docker Best Practices:** https://docs.docker.com/develop/dev-best-practices/

---

**Última Atualização:** Junho 2025  
**Versão:** 1.0.0 — MVP  
**Mantido por:** [NOME_DO_MEMBRO_BACKEND] / Tech Lead