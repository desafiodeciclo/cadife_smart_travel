# Skill: /bug-catcher

## Descrição

Executa varredura sistemática do código-fonte em busca de bugs, anti-patterns e violações das regras do projeto (CLAUDE.md + `.claude/rules/`). Cataloga os problemas encontrados por severidade e — após aprovação do dev — aplica os fixes respeitando o workflow SDD e as restrições críticas inegociáveis.

## Trigger

Ativado quando o dev escreve: `/bug-catcher` ou `/bug-fix` ou "procure bugs" ou "encontre e corrija bugs" ou "varredura de bugs".

Variações com escopo:
- `/bug-catcher backend` → varredura apenas em `backend/`
- `/bug-catcher flutter` → varredura apenas em `frontend_flutter/`
- `/bug-catcher ai` → varredura apenas nos serviços de IA (`backend/app/services/ai_*.py`)
- `/bug-catcher <caminho>` → varredura em caminho específico

---

## Processo do Agente (Workflow)

### FASE 1 — Preparação e Varredura

1. **Determinar escopo:** ler o argumento passado ao comando; se ausente, varrer todo o projeto.
2. **Carregar regras ativas:** ler os arquivos em `.claude/rules/` correspondentes ao escopo.
3. **Varrer o código** por camada:

#### Checklist Backend FastAPI (`backend/`)

**Crítico (severidade ALTA):**
- [ ] Endpoint `POST /webhook/whatsapp` processa IA de forma síncrona (viola Regra 1 — deve usar `BackgroundTasks`)
- [ ] Falta validação de `X-Hub-Signature-256` no webhook (viola Regra 2 — vulnerabilidade de segurança)
- [ ] Endpoint privado sem `Depends(get_current_user)` (viola Regra 7 — autenticação ausente)
- [ ] Credencial ou token hardcoded no código (viola Regra 6 — vazamento garantido)
- [ ] Delete físico de lead (viola Regra 4 — deve ser soft delete com `is_archived=True`)

**Moderado (severidade MÉDIA):**
- [ ] Função pública sem type hints
- [ ] Route handler sem `async def`
- [ ] Retorno de endpoint sem `response_model` tipado
- [ ] Uso de `dict` como parâmetro de entrada de endpoint (sem Pydantic)
- [ ] Operação I/O (DB, HTTP) dentro de função síncrona
- [ ] Ausência de log estruturado em operações críticas (lead criado, status alterado, webhook recebido)
- [ ] `try/except` genérico sem log do erro (`except Exception: pass`)

**Baixo (severidade BAIXA):**
- [ ] Importação não utilizada
- [ ] Variável definida mas nunca usada
- [ ] Magic strings que deveriam ser constantes ou enums
- [ ] Comentário TODO/FIXME sem issue referenciada

#### Checklist Flutter (`frontend_flutter/`)

**Crítico (severidade ALTA):**
- [ ] `setState` usado para dados remotos (API) — deve usar `AsyncNotifierProvider`
- [ ] `Navigator.push` usado diretamente — deve usar `context.go()` / `context.push()` do GoRouter
- [ ] Mistura de lógica Agency e Client no mesmo arquivo/widget
- [ ] Chamada `Dio` direta dentro de Notifier ou Widget (sem repositório)

**Moderado (severidade MÉDIA):**
- [ ] Cor hexadecimal hardcoded no widget (deve usar `AppColors.*`)
- [ ] Nome de fonte hardcoded (deve usar `AppTheme.*`)
- [ ] Ausência de loading/error states em `AsyncValue` (uso de `.value ?? []` sem `.when()`)
- [ ] Provider sem separação repository/notifier/view
- [ ] Widget com mais de 300 linhas (candidato a refatoração)

**Baixo (severidade BAIXA):**
- [ ] `print()` no código (deve usar logger estruturado)
- [ ] `const` ausente em widgets imutáveis
- [ ] Parâmetro não-nulo sem assert de validação
- [ ] Imports relativos saindo do próprio diretório de feature

#### Checklist IA / LangChain (`backend/app/services/ai_*.py`)

**Crítico (severidade ALTA):**
- [ ] System prompt sem as restrições obrigatórias da AYA (proibições de preço, disponibilidade, fechamento)
- [ ] Parsing manual de JSON de resposta LLM em vez de `PydanticOutputParser`
- [ ] Memória de conversa compartilhada entre leads distintos
- [ ] Campo de briefing marcado como preenchido por inferência (sem menção explícita do cliente)

**Moderado (severidade MÉDIA):**
- [ ] LLM configurado sem `request_timeout`
- [ ] Chain sem fallback de erro (ausência de `try/except` com mensagem de fallback)
- [ ] Documento indexado no Vector DB sem metadata de fonte (`source`, `chunk_index`)
- [ ] `chunk_size` fora da faixa 300–500 tokens
- [ ] Temperature > 0.5 em chains de extração de dados estruturados

**Baixo (severidade BAIXA):**
- [ ] Prompt sem instrução explícita de idioma/tom
- [ ] Variável de ambiente de API key acessada diretamente em vez de via `Settings`

---

### FASE 2 — Relatório de Bugs

Após a varredura, apresentar o relatório no formato abaixo **antes de qualquer modificação**:

```
=== RELATÓRIO DE BUGS — Cadife Smart Travel ===
Data: <data atual>
Escopo: <backend | flutter | ai | full>

BUGS CRÍTICOS (severidade ALTA): <n>
──────────────────────────────────
[BUG-001] <arquivo>:<linha> — <descrição curta>
  Violação: Regra X de .claude/rules/<arquivo>.md
  Impacto: <consequência concreta ex: "Meta cancela webhook após 5s timeout">
  Fix proposto: <descrição do fix em 1-2 linhas>

[BUG-002] ...

BUGS MODERADOS (severidade MÉDIA): <n>
──────────────────────────────────
[BUG-003] <arquivo>:<linha> — <descrição curta>
  ...

BUGS BAIXOS (severidade BAIXA): <n>
──────────────────────────────────
[BUG-004] ...

RESUMO:
  Total: <n> bugs encontrados
  Críticos: <n> | Moderados: <n> | Baixos: <n>
  Arquivos afetados: <lista>

Deseja que eu aplique os fixes? (responda: "todos" | "só críticos" | "BUG-001, BUG-003" | "não")
```

---

### FASE 3 — Aplicação dos Fixes (aguarda aprovação)

Após confirmação do dev:

1. **Verificar se há spec ativa** em `specs/active/` — se sim, informar ao dev e perguntar se deve criar spec separada para os fixes ou incluir como hotfix.
2. **Para cada bug aprovado** (na ordem: críticos → moderados → baixos):
   a. Ler o arquivo completo antes de editar.
   b. Aplicar o fix mínimo necessário — sem refatoração além do escopo do bug.
   c. Confirmar que o fix não quebra outros pontos do mesmo arquivo.
   d. Registrar o fix aplicado na lista de progresso.
3. **Após todos os fixes:**
   - Listar todos os arquivos modificados.
   - Listar os bugs que **não** foram fixados (se o dev optou por um subset).
   - Se foram feitas mudanças relevantes, sugerir criação de spec de documentação em `specs/done/` com título `HOTFIX-<data>-bug-catcher`.

---

## Restrições do Comando

- **Nunca** aplicar fixes antes de apresentar o relatório e aguardar aprovação do dev.
- **Nunca** corrigir um bug introduzindo outro anti-pattern (ex: não use `dict` para corrigir ausência de `response_model`).
- **Nunca** refatorar código além do escopo do bug reportado — a tarefa é fix, não cleanup.
- **Nunca** remover fisicamente registros de leads mesmo que o código bugado faça isso — criar fix de soft delete e alertar o dev sobre dados potencialmente afetados.
- **Nunca** suavizar as restrições comerciais da AYA ao corrigir bugs de prompt — as proibições absolutas são inegociáveis.
- **Sempre** confirmar que o webhook `POST /webhook/whatsapp` continua retornando HTTP 200 em ≤ 5s após qualquer fix no fluxo de mensagens.
- **Sempre** preservar type hints, Pydantic schemas e logs estruturados ao editar arquivos — não os remova como "simplificação".
- Se um bug exigir mudança de schema de banco de dados, **parar** e alertar o dev: mudanças de schema requerem migration Alembic e validação do time antes de executar.
