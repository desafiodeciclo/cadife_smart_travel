# Skill: /new-feature

## Descrição

Inicia o ciclo SDD completo para uma nova feature: lê o requisito em `docs/`, cria o spec JSON em `specs/pending/` e apresenta o plano de implementação para aprovação antes de escrever código.

## Trigger

Ativado quando o dev escreve: `/new-feature <nome-da-feature>` ou "quero implementar [feature]".

## Processo do Agente (Workflow)

1. **Ler contexto:** verificar se já existe design em `docs/design/` para esta feature.
2. **Ler requirements:** verificar se há REQ correspondente em `docs/requirements/mvp_requirements.md`.
3. **Verificar specs existentes:** checar `specs/pending/` e `specs/active/` para evitar duplicata.
4. **Criar spec JSON** em `specs/pending/` com o formato do `specs/_template_spec.json`:
   - `task_id`: formato `MVP-F{fase}-{número sequencial}` (ex: `MVP-F2-003`)
   - `name`: nome descritivo da feature
   - `dependencies`: IDs de specs que precisam estar em `done/` antes desta
   - `steps`: lista de passos técnicos granulares com status `"pending"`
5. **Apresentar plano** ao dev: listar os steps propostos e perguntar se há ajustes.
6. **Aguardar aprovação** antes de mover para `specs/active/` ou escrever qualquer código.

## Restrições

- Nunca escrever código antes da aprovação do plano pelo dev.
- Nunca criar spec para features fora do escopo do MVP (ver `docs/brief.md` e `.claude/steering/product.md`).
- Sempre verificar se a feature tem requisito EARS correspondente — se não tiver, criar o requisito primeiro em `docs/requirements/`.
- Specs de features de IA devem ser revisadas pelo AI Engineer (Frank) antes de execução.
