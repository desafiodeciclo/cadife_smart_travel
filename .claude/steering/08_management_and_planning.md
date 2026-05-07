## 10. Cronograma de Execução — 25 Dias

| Período | Fase | Entregas | Responsáveis |
|---|---|---|---|
| **Dias 1–6** | **Fase 1 — Fundação** | Setup do backend FastAPI, configuração do banco de dados, webhook WhatsApp funcional recebendo e logando mensagens, estrutura base do App Flutter (navegação, auth, tema Cadife), configuração do Firebase | *Nikolas (Backend), Luiz (DevOps), Otávio (Flutter)* |
| **Dias 7–13** | **Fase 2 — IA + RAG** | Implementação do LangChain, criação e indexação do Vector DB com documentos da Cadife, lógica de extração de briefing por IA, motor de decisão de fluxo, respostas contextualizadas via RAG, integração WhatsApp → IA → Banco | *Frank (AI), Nikolas (Backend), Diego (UX/API)* |
| **Dias 14–20** | **Fase 3 — App + Firebase** | Desenvolvimento completo das telas do app: dashboard agência, lista de leads, detalhe de lead, telas do cliente (status, histórico, docs), agenda, configuração do FCM, notificações push em tempo real | *Otávio (Flutter Client), Jakeline (Flutter Agency), Luiz (Firebase)* |
| **Dias 21–25** | **Fase 4 — Finalização** | Tratamento de erros e edge cases (áudio, imagem, timeouts), ajustes de UX, documentação da API (Swagger/Postman), containerização (Docker), preparação da demo de 10 min ponta a ponta, organização do GitHub | *Time completo — validação PO Diego* |

### 10.1 Cerimônias Ágeis

| Cerimônia | Frequência | Formato |
|---|---|---|
| **Sprint Planning** | Semanal | Segunda-feira pós-aula ou às 19h — definição de escopo, divisão e atribuição de tarefas (Jira) |
| **Daily Stand-up** | Diária (10–15 min) | O que fiz \| O que farei \| Impedimentos — formato assíncrono ou síncrono via Discord |
| **Sprint Review** | Semanal | Demonstração das entregas, validação pelo PO Diego, time completo presente |
| **Sprint Retrospective** | Semanal | Pontos positivos, negativos e melhorias para o próximo sprint |

---

## 11. Estrutura da Equipe

| Papel | Membro | Responsabilidades |
|---|---|---|
| **Product Owner** | **Diego Gil** | Validação de todas as entregas, definição de prioridades, knowledge base do negócio Cadife Tour, decisão sobre funcionalidades do MVP |
| **Scrum Master** | **Nikolas Tesch** | Aplicação da metodologia ágil, remoção de impedimentos, organização do fluxo do time, manutenção do board Jira e burndown chart |
| **Tech Lead / Backend** | **Nikolas Tesch** | Arquitetura da API FastAPI, segurança (JWT), modelagem de banco, integração WhatsApp Cloud API, code review |
| **AI Engineer** | **Frank Willian** | Implementação do LangChain, configuração do RAG (ChromaDB/PGVector), prompts de extração, lógica de qualificação e roteamento |
| **Flutter Dev — Cliente** | **Otávio Grotto** | Interface do perfil cliente: cadastro, status da viagem, histórico, documentos, consumo da API |
| **Flutter Dev — Agência** | **Jakeline** | Dashboard agência, lista de leads, detalhe de lead, agenda, gestão de propostas, UX do consultor |
| **DevOps & QA** | **Luiz Angelo** | Firebase FCM, notificações push, deploy Docker/LXC, testes de integração, CI/CD GitHub Actions |

### 11.1 Ferramentas do Time

| Ferramenta | Finalidade |
|---|---|
| **Jira** | Gestão do backlog, sprints, tarefas, burndown chart e board Kanban (Backlog → To Do → In Progress → Code Review → Testing → Done) |
| **GitHub** | Versionamento de código, pull requests, code review e CI/CD com GitHub Actions |
| **WhatsApp & Discord** | Comunicação diária (WhatsApp para urgências, Discord para reuniões e dailys) |
| **Postman / Swagger** | Testes de API e documentação dos endpoints do backend |
| **Figma / Stitch** | Design de UX/UI das telas do app Flutter |
| **VS Code / Android Studio** | Desenvolvimento principal (backend Python + frontend Flutter/Dart) |
| **ngrok** | Exposição do webhook local para testes com WhatsApp Cloud API durante desenvolvimento |

---

## 14. Critérios de Aceite e Definition of Done

### 14.1 Critérios de Sucesso do MVP

| Critério | Método de Verificação | Responsável |
|---|---|---|
| Mensagem enviada no WhatsApp aparece no App em < 2 segundos | *Teste manual cronometrado* | QA / Luiz |
| IA responde corretamente usando a base de conhecimento RAG da Cadife | *10 perguntas de teste predefinidas pelo PO* | Frank + Diego |
| Briefing extraído automaticamente com >= 80% de precisão | *Comparação manual de 20 conversas de teste* | Frank |
| Lead criado automaticamente ao final da qualificação | *Verificação no banco e no dashboard* | Nikolas |
| Notificação push entregue ao consultor em < 2 segundos | *Teste com dois dispositivos simultâneos* | Luiz |
| App exibe lista de leads com dados estruturados corretamente | *Validação visual pelo PO* | Otávio / Jakeline |
| Fluxo completo ponta a ponta funciona sem erros críticos | *Demo de 10 minutos ao PO* | Time completo |
| Mensagens de tipo não suportado (áudio/imagem) são tratadas | *Envio de mídia no WhatsApp de teste* | QA / Luiz |
| Documentação da API está disponível e acessível (Swagger) | *Acesso à URL `/docs` do backend* | Nikolas |

### 14.2 Definition of Done (DoD)

Uma tarefa é considerada **PRONTA (Done)** quando:

- Código desenvolvido e funcionando no ambiente de desenvolvimento
- Testado (testes manuais ou automatizados conforme a feature)
- Integrado ao branch principal sem conflitos
- Sem erros críticos ou bugs bloqueantes
- Validado por pelo menos 2 membros do time (incluindo o PO para features de negócio)
- Documentado quando se trata de endpoint de API

### 14.3 Kanban Board — Fluxo de Tarefas

| BACKLOG | TO DO | IN PROGRESS | CODE REVIEW | TESTING | DONE |
|---|---|---|---|---|---|
| Features futuras e ideias | Planejadas para o sprint atual | Em desenvolvimento ativo | Aguardando revisão de código | Em validação e testes | Validado pelo PO e entregue |
