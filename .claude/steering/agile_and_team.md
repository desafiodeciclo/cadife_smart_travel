# Agile Management and Team

Informações de gestão, processos, cronograma e equipe.

## 1. Cronograma de Execução (MVP 25 Dias)

| Período | Fase | Foco Principal |
|---|---|---|
| **Dias 1–6** | **Fundação** | Backend FastAPI, WhatsApp Webhook, Flutter Base, Firebase Setup |
| **Dias 7–13** | **IA + RAG** | LangChain, Vector DB, Extração de Briefing, Respostas RAG |
| **Dias 14–20** | **App + Firebase** | Dashboards Agência/Cliente, Agenda, Notificações Push |
| **Dias 21–25** | **Finalização** | Erros/Edge cases, UX, Docker, Documentação, Demo |

## 2. Estrutura da Equipe

| Papel | Membro |
|---|---|
| **Product Owner** | Diego Gil |
| **Scrum Master / Backend** | Nikolas Tesch |
| **AI Engineer** | Frank Willian |
| **Flutter Dev — Cliente** | Otávio Grotto |
| **Flutter Dev — Agência** | Jakeline |
| **DevOps & QA** | Luiz Angelo |

## 3. Cerimônias Ágeis

- **Sprint Planning:** Semanal (Segunda-feira).
- **Daily Stand-up:** Diária (10–15 min).
- **Sprint Review:** Semanal (Demonstração das entregas).
- **Sprint Retrospective:** Semanal (Melhoria contínua).

## 4. Critérios de Sucesso do MVP

| Critério | Método de Verificação |
|---|---|
| Msg WhatsApp → App < 2s | Teste manual cronometrado |
| Respostas RAG corretas | 10 perguntas predefinidas pelo PO |
| Precisão Briefing >= 80% | Comparação manual de 20 conversas |
| Lead automático no Banco | Verificação no dashboard |
| Push Notification < 2s | Teste com dois dispositivos |
| Demo funcional ponta a ponta | Demo de 10 min ao PO |

## 5. Definition of Done (DoD)

Uma tarefa é **PRONTA** quando:
- Código funciona em ambiente de dev.
- Testado (manual ou automatizado).
- Integrado ao branch principal sem conflitos.
- Sem bugs bloqueantes.
- Validado por 2 membros do time (incluindo PO para features de negócio).
- Documentado (se endpoint de API).

## 6. Riscos e Mitigações Detalhados

| Risco | Impacto | Mitigação |
|---|---|---|
| Integração WhatsApp API | Alto | Usar ngrok, reservar tempo extra para setup. |
| Alucinações da IA | Alto | Prompts restritivos e logs de revisão. |
| Prazo Curto (25 dias) | Médio | Foco estrito em MVP, priorização rígida. |
| Timeout Webhook Meta | Alto | Processamento assíncrono (Task background). |
| Mudanças de Escopo | Médio | Só entram em sprints futuros (decisão PO). |
| Qualidade RAG Baixa | Médio | PO valida e complementa base na Fase 1. |
