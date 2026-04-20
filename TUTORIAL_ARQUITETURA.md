# Guia de Arquitetura e Uso SDD (Spec-Driven Development)

Este tutorial documenta detalhadamente como o projeto **Cadife Smart Travel** está estruturado e como a metodologia **SDD com o Claude Code** é materializada na árvore de diretórios. A principal premissa é que **todas as alterações de código são premeditadas por documentações em JSONs rastreáveis e controladas.**

---

## 🗺️ Mapa Conceitual da Arquitetura de Diretórios

```text
Cadife Smart Travel (Repositório Root)
├── .claude/               -> Orquestração e Memória de Contexto do Agente
├── docs/                  -> Contexto de Negócio e EARS criado por humanos
├── specs/                 -> "Jira" do Claude: rastreabilidade e tarefas
├── backend/               -> Código fonte da API (Python/FastAPI)
└── frontend_flutter/      -> Código fonte do App (Dart/Flutter Riverpod)
```

Sempre que formos iniciar um ciclo de trabalho, o Claude entra nessa árvore, lê o `claude.md`, carrega a constituição, depois lê as descrições nas pastas `.claude` e `docs`, e finalmente trabalha na elaboração de uma spec dentro de `specs/`.

---

## 📂 1. `.claude/`: O Cérebro de Operações
Este é o ambiente particular onde o Claude se situa. Contém orientações sistêmicas ativas na sessão.

- **`steering/`**: Diretrizes estratégicas macro.
  - `structure.md`: Lembra o Claude de como o Monorepo está arquitetado (onde fica backend, frontend, etc).
  - `tech.md`: Define a Stack exata (ex. "somos um projeto que usa FastAPI, SQLModel").
  - `product.md`: O "porquê". A essência do produto (MVP, CRM, Chatbot de Triagem).
- **`rules/`**: Sempre que há lições aprendidas (ex. "Erro comum no Flutter ao gerenciar forms"), você cria uma regra aqui (`_template_rule.md`) para o Claude não errar mais naquilo no futuro.
- **`comands/`**: Scripts que dizem como workflows personalizados `/comando` funcionam internamente no prompt do agent.
- **`agents/`**: Definição de personalidades ou prompts alternativos para rodadas específicas (se houver variação no fluxo metodológico).

---

## 📂 2. `docs/`: A Mente Humana (The Foundation)
A fonte da verdade para onde a aplicação aponta. Qualquer "mudança de ideia" no projeto deve ser averbada primeiro nesta pasta, antes de pedir ao Claude para mudar o código. O fluxo de criação de features segue o modelo EARS e passa pelo pipeline daqui.

- **`brief.md`**: Resumo executivo rápido de propósito para não esquecer o modelo principal (MVP em 25 dias).
- **`requirements/`**: Formulamos o Product Requirement Document em EARS (WHEN/THEN/SHALL) para forçar uma verificação estrita. *(Veja _template_ears.md)*
- **`design/`**: Documentos de texto para detalhamento técnico sobre como um requisito EARS se transforma em banco de dados e UX. Usa descrições em forma de arquitetura de C4 Model ou fluxogramas (Mermaid/Textual).
- **`contracts/`**: Os esqueletos da comunicação (Esboço JSON das rotas da API, Schemas de dados), servindo como o contrato de fronteira que tanto front quanto back lerão.
- **`tasks/`**: Arquivos de detalhamento humano sobre como as specs deverão ser modeladas e programadas pelos desenvolvedores de squad no caso de uso do Claude não realizar tudo sozinho.
- **`adr/`**: Repositório de Rastreamento (Architecture Decision Records). Mudou banco de Mongo para Postgres? Escreva o ADR aqui. *(Veja _template_adr.md)*
- **`bugs/`**: Onde depositamos relatórios críveis com trace route ou print textual de terminal quando achamos problemas, para o Claude consertar de modo investigativo.

---

## 📂 3. `specs/`: A Oficina do Robô
É aqui que o "Claude Manager" funciona. As tarefas do `docs` ganham um arquivo JSON que vira a tarefa a ser cumprida pelo Claude Coding Agent.

- **`pending/`**: Você (humano) via SDD injeta um `faseX_feature.json` aqui. O agente verá as dependências.
- **`active/`**: O Claude move ou cria um JSON rastreando que ele **começou** o trabalho. Ele listará steps com `status: "in-progress"`. Se a rodada de token morrer, ele volta após o reinício, lê o repositório, lê que essa tarefa estava incompleta e retoma sozinho de onde parou.
- **`done/`**: Após tudo criado e validado, o Claude migra o JSON da sprint para `done/`, mantendo um histórico auditável do que foi desenvolvido pelo LLM. *(Veja _template_spec.json)*

---

## 💻 Como Operar Neste Repositório Com O Claude

1. **Ideação:** Comece pela pasta `docs`. Crie o seu requisito em `docs/requirements/req_vendas.md`.
2. **Setup do Agente:** Chame o Claude ou utilize a CLI dele e mande-o ler o requisito e propor a execução técnica.
3. **Spec-Driven:** O Claude dirá: "Ok, vou estruturar a spec em `specs/pending/req_vendas_spec.json`".
4. **Execução:** Você aprova. O Claude move o manifesto para `active/` e toca os arquivos do `backend/` ou `frontend_flutter/`.
5. **Teste:** O código é rodado, validado. Tudo Certo?
6. **Fechamento:** A task no `active/` ganha status complete e move para `done/`.

**Utilize os templates deixados em cada uma dessas pastas** para entender qual é o padrão mínimo esperado que facilita a predição da sua IA. Respeitar essa topologia evita que o contexto do LLM descarrilhe ao longo de MVPs ou projetos com muitas APIs e integrações.
