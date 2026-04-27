# Skill: /start-session

## Descrição

Executa o ritual completo de início de sessão do SDD: carrega o contexto do projeto, verifica o estado atual das specs e reporta o que está em andamento ou pendente.

## Trigger

Ativado quando o dev escreve: `/start-session` ou "inicie a sessão" ou "o que está pendente?".

## Processo do Agente (Workflow)

1. **Carregar constituição:** ler `CLAUDE.md` inteiro.
2. **Carregar steering:** ler `.claude/steering/product.md`, `tech.md` e `structure.md`.
3. **Carregar regras ativas:** listar e ler arquivos em `.claude/rules/` (exceto templates).
4. **Verificar specs ativas:** ler todos os JSONs em `specs/active/`.
   - Se houver spec ativa: reportar nome, status, e o próximo step pendente.
   - Perguntar ao dev se deseja retomar ou há novo contexto a considerar.
5. **Verificar specs pendentes:** listar nome e `task_id` dos JSONs em `specs/pending/`.
6. **Reportar estado:** apresentar resumo formatado:

```
=== ESTADO DA SESSÃO — Cadife Smart Travel ===

SPEC ATIVA:
  [MVP-F1-001] Implementação da Fase 1 - Fundação
  Próximo step: step3 - Flutter setup com flavor Agency/Client

SPECS PENDENTES (ordem sugerida):
  1. [MVP-F2-001] Fase 2 — IA + RAG
  2. [MVP-F3-001] Fase 3 — App + Firebase
  3. [MVP-F4-001] Fase 4 — Finalização

Qual deseja executar? (ou diga "continuar" para retomar a spec ativa)
```

## Restrições

- Não modificar nenhum arquivo durante o `start-session` — apenas leitura e report.
- Não assumir automaticamente qual spec executar — sempre aguardar confirmação do dev.
- Se houver mais de 1 spec em `specs/active/`, alertar o dev: o SDD prevê máximo de 1 spec ativa por vez.
