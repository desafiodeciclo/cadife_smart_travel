# 📝 AGENTE DOCUMENTADOR — CADIFE SMART TRAVEL v1.0

**Gerador Automático de Comentários de Pull Requests**

Transforma mudanças de código em comentários estruturados que explicam QUAIS, COMO e PORQUÊ — tudo em 2 minutos de leitura.

---

## 🎯 O Problema

**Antes (comentário ruim):**
```
"Implementei o endpoint. Tá pronto."
```

**Depois (comentário profissional):**
```markdown
## 📋 Resumo
✅ Implementado POST /api/ai/response com RAG [Backend] [IA]

## 🔄 Alterações
- Integração LangChain com ChromaDB
- Rate limiting: 2 req/min
- Testes: 12 casos

## ✅ Cumprimento
| Requisito | Status |
|-----------|--------|
| Endpoint funciona | ✓ |
| RAG integrado | ✓ |
| Testes | ✓ |

**Conclusão:** COMPLETO
```

---

## 📦 O QUE VOCÊ RECEBEU

### 1. 🤖 `documentador_pr.py`
Script Python que gera comentários automáticos.

**Uso:**
```bash
python documentador_pr.py
# Gera: pr_comment.md + pr_analysis.json
```

**Ou em código:**
```python
from documentador_pr import generate_from_pr_data

comentario = generate_from_pr_data(
    title="Implementar GET /api/leads",
    task="Endpoint com paginação e filtros",
    files_changed=["backend/routes/leads.py", "backend/tests/..."],
    diff="...",
    context="Desbloqueia dashboard"
)
print(comentario)
```

---

### 2. 📋 `PROMPT_DOCUMENTADOR_PR.md`
Instruções detalhadas para usar **manualmente com Claude**.

**Como usar:**
1. Cole o arquivo inteiro em uma conversa comClaude
2. Forneça [TASK], [MUDANÇAS], [CÓDIGO]
3. Claude gera comentário pronto para GitHub

**Cobertura:**
- 7 seções de análise
- Template de output
- Exemplos completos
- Regras de aprovação

---

### 3. 📖 `GUIA_USO_DOCUMENTADOR_PR.md`
Manual prático com:
- Como usar (opção automática + manual)
- 5 tipos de mudança com exemplos
- Interpretação de status (✓/⚠/✗)
- Dicas pro
- Fluxo completo dia-a-dia

---

### 4. 📚 `EXEMPLOS_PR_DOCUMENTADOR.md`
Casos reais do projeto Cadife:

**Caso 1:** Implementação de endpoint FastAPI (POST /api/ai/response)
**Caso 2:** Refatoração com breaking change (schema Lead)
**Caso 3:** Implementação Flutter (Dashboard da Agência)

Cada caso mostra:
- Input (task, mudanças, código)
- Output esperado (comentário completo)
- Decisões tomadas

---

## 🚀 QUICK START

### Opção 1: Manual com Claude (Recomendado)

**Copie e cole em uma conversa:**
```
<conteúdo de PROMPT_DOCUMENTADOR_PR.md>

Agora forneça:

[TASK]
Implementar endpoint GET /api/leads com paginação

[MUDANÇAS]
- backend/routes/leads.py (novo)
- backend/tests/test_leads.py (novo)

[CÓDIGO]
def get_leads(limit: int = 20, offset: int = 0):
    return leads[offset:offset+limit]

[CONTEXTO]
Desbloqueia dashboard da agência
```

**Resultado:** Claude gera comentário profissional

---

### Opção 2: Automático com Python

```bash
python documentador_pr.py
cat pr_comment.md
# Copie e cole no GitHub
```

---

### Opção 3: No seu código

```python
from documentador_pr import generate_from_pr_data

comentario = generate_from_pr_data(
    title="Seu PR title aqui",
    task="O que deveria ser feito",
    files_changed=["arquivo1.py", "arquivo2.py"],
    diff="..."
)

# Salve em variável ou print
print(comentario)
```

---

## 📊 ESTRUTURA DO COMENTÁRIO

Todos os comentários gerados seguem este padrão:

```markdown
## 📋 Resumo das Alterações
[1-2 linhas descrevendo o que foi feito]

---

## 🔄 Detalhes das Mudanças

### Alterações Principais
[3-5 principais mudanças com justificativa]

### Impacto
[Impactos técnicos e de negócio]

---

## ✅ Cumprimento da Task

| Requisito | Status |
|-----------|--------|
| [requisito 1] | ✓/⚠/✗ |
| [requisito 2] | ✓/⚠/✗ |

**Conclusão:** [COMPLETO / COM OBSERVAÇÕES / REQUER AJUSTES]

---

## 🎯 Recomendações
[Próximos passos, validações, etc]
```

---

## ✅ TIPOS DE STATUS

### ✓ COMPLETO — Aprovado para Merge
- Todos requisitos da task implementados
- Testes adicionados
- Documentação atualizada
- **Ação:** Fazer merge imediatamente

### ⚠ COM OBSERVAÇÕES — Revisar antes de Merge
- Requisitos principais completos
- Alguns requisitos secundários pendentes
- Breaking changes comunicados
- **Ação:** Aprovar com condições

### ✗ REQUER AJUSTES — Não fazer merge
- Requisitos críticos faltando
- Task não cumprida
- **Ação:** Solicitar retrabalho

---

## 📊 EXEMPLOS DE SAÍDA

### Exemplo 1: Endpoint FastAPI (Simples)
```markdown
## 📋 Resumo
✅ Implementado GET /api/leads com paginação [Backend] [Tests]

## 🔄 Alterações Principais
- **Novo endpoint:** GET /api/leads
- **Paginação:** limit (1-100) + offset
- **Filtros:** por status
- **Validação:** Pydantic LeadsFilterSchema

## 🎯 Impacto
- ✨ Dashboard da agência agora funciona
- 🚀 Performance: índices adicionados
- 🔒 Segurança: JWT obrigatório

## ✅ Cumprimento
✓ Endpoint funciona
✓ Testes (8 casos)
✓ Documentado em Swagger

**Conclusão:** ✓ COMPLETO
```

### Exemplo 2: Refatoração com Breaking Change
```markdown
## 📋 Resumo
⚠️ Refatorado schema Lead com briefing_json [Database] [Breaking Change]

## 🔄 Alterações
- Nova coluna: Lead.briefing_json
- Migration Alembic criada
- Response API atualizado

## ⚠️ Breaking Change
GET /api/leads agora retorna briefing_json: null
Frontend precisa adaptar!

## 🎯 Recomendações
- [ ] Comunicar ao frontend
- [ ] PR relacionada: #XX
- [ ] Testar em staging primeiro

**Conclusão:** ⚠️ PARCIAL (requer comunicação)
```

### Exemplo 3: Flutter UI (Completo)
```markdown
## 📋 Resumo
✅ Dashboard da Agência com listagem, filtros e real-time [Flutter] [UI]

## 🔄 Alterações
- Tela agency_dashboard_screen.dart
- Controller com GetX
- FCM listener integrado
- 15 testes inclusos

## 🎯 Impacto
- 💡 UX premium para consultores
- ⏱️ Real-time updates via FCM
- 🚀 Desbloqueia workflow completo

## ✅ Cumprimento
✓ Tela implementada
✓ Filtros funcionam
✓ Real-time OK
✓ Testes OK

**Conclusão:** ✓ COMPLETO
```

---

## 🎯 CHECKLIST ANTES DE GERAR

- [ ] Task descrição está clara
- [ ] Arquivos foram listados
- [ ] Código/diff disponível
- [ ] Contexto (fase, impacto) fornecido
- [ ] Sabe se é CRÍTICO/ALTA/MÉDIA

---

## 💡 DICAS PROFISSIONAIS

1. **Seja específico:** "Reduzido latência de 800ms → 120ms" > "Otimizado"
2. **Cite números:** "8 testes" > "testes adicionados"
3. **Pense no revisor:** Ele tem 30 segundos para decidir
4. **Antecipe questões:** Se há trade-off, explique por quê
5. **Documente tudo:** Sem docs = sem merge

---

## 🔄 FLUXO COMPLETO (dia-a-dia)

```
1. Você escreve código
   ↓
2. Cria PR no GitHub
   ↓
3. Executa documentador (manual ou automático)
   ↓
4. Cola comentário no PR
   ↓
5. Revisor lê em 2 minutos
   ↓
6. Aprovar ou solicitar ajustes
   ↓
7. Merge!
```

---

## 📱 INTEGRAÇÃO COM CI/CD

**Adicionar ao `.github/workflows/comment.yml`:**
```yaml
name: Auto-Documentação de PR

on: [pull_request]

jobs:
  document:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
      - run: python documentador_pr.py
      - uses: actions/upload-artifact@v3
        with:
          name: pr-docs
          path: pr_comment.md
```

Assim, cada PR gera documentação automaticamente!

---

## 📊 MÉTRICAS DE SUCESSO

Um bom comentário PR:
- ✅ Lido em < 2 minutos
- ✅ Deixa claro o impacto
- ✅ Indica status de aprovação
- ✅ Serve como documentação histórica
- ✅ Facilita decisão do revisor

---

## 🎓 EXEMPLOS INSPIRADORES

Veja `EXEMPLOS_PR_DOCUMENTADOR.md` para:

**Caso 1: Backend API**
- POST /api/ai/response com LangChain RAG
- Input → Output completo
- Status: ✅ COMPLETO

**Caso 2: Database Migration**
- Schema refactoring com breaking change
- Como comunicar mudanças
- Status: ⚠️ COM OBSERVAÇÕES

**Caso 3: Flutter UI**
- Dashboard completo com real-time
- Integração com backend
- Status: ✅ COMPLETO

---

## 🚀 PRÓXIMOS PASSOS

1. **Leia** `PROMPT_DOCUMENTADOR_PR.md` (entenda a lógica)
2. **Experimente** em um PR seu (teste automático)
3. **Adapte** o padrão para seu workflow
4. **Compartilhe** com o time (padronize)
5. **Melhore** baseado em feedback

---

## 📞 SUPORTE

**Dúvida sobre formato?**
→ Veja `GUIA_USO_DOCUMENTADOR_PR.md`

**Precisa de exemplo específico?**
→ Veja `EXEMPLOS_PR_DOCUMENTADOR.md`

**Quer customizar o padrão?**
→ Edite `PROMPT_DOCUMENTADOR_PR.md`

**Erro no script Python?**
→ Verifique `documentador_pr.py`

---

## 📈 EVOLUÇÃO DO PROJETO

### Semana 1-2
Todos os PRs com comentários claros
→ 70% dos PRs aprovados na primeira review

### Semana 3+
Documentação padronizada
→ 90% dos PRs aprovados na primeira review
→ Menos volta-e-volta

### Mês 2+
Histórico completo documentado
→ Onboarding de novos devs mais rápido
→ Decisões técnicas rastreáveis

---

## 🏆 BENEFÍCIOS

**Para o Dev:**
- ✅ Menos "voltas" no PR
- ✅ Comunicação clara
- ✅ Documentação automática

**Para o Revisor:**
- ✅ Entende rapidamente
- ✅ Contexto completo
- ✅ Aprova com confiança

**Para o Projeto:**
- ✅ Histórico documentado
- ✅ Decisões rastreáveis
- ✅ Onboarding facilitado

---

## 📝 CHANGELOG

| Versão | Data | Mudança |
|--------|------|---------|
| 1.0 | Jun 2025 | Versão inicial |

---

**Status:** ✅ Pronto para usar

Comece agora com seu próximo PR! 🎉