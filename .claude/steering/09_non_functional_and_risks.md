## 12. Requisitos Não Funcionais

### 12.1 Performance

- Resposta da IA ao cliente via WhatsApp: máximo 3 segundos
- Notificação push ao consultor: máximo 2 segundos após evento
- Carregamento do dashboard (lista de leads): máximo 1,5 segundos
- Atualização em tempo real do app após mensagem no WhatsApp: máximo 2 segundos

### 12.2 Segurança

- Autenticação JWT com expiração configurável (access token 1h, refresh token 7d)
- HTTPS obrigatório em todos os endpoints (webhook + API + FCM)
- Variáveis sensíveis (tokens Meta, OpenAI, DB) exclusivamente via `.env` — nunca no código
- Validação do Verify Token no webhook antes de processar qualquer payload
- Rate limiting nos endpoints de webhook e IA para evitar abuso

### 12.3 Confiabilidade

- O webhook deve responder com HTTP 200 em até 5 segundos (timeout da Meta)
- Tratamento de exceções em todo o fluxo de processamento (try/catch)
- Logs estruturados de todas as interações (entrada, saída, erros)
- Mensagens de mídia não suportadas (áudio, imagem) devem ser tratadas com resposta amigável ao cliente

### 12.4 Usabilidade

- App Flutter deve ser intuitivo para usuários leigos (consultor não-técnico)
- Design clean e premium alinhado ao posicionamento da Cadife Tour (intermediário → premium)
- Feedback visual imediato para todas as ações do usuário (loading, success, error states)

### 12.5 Escalabilidade (preparação futura)

- Backend estruturado para suportar múltiplos números WhatsApp (multi-tenant)
- Docker Compose configurado para escalar horizontalmente o backend
- Vector DB preparado para receber novos documentos sem rebuild completo

---

## 13. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Complexidade da integração WhatsApp Cloud API | **Média** | **Alto** | Utilizar ngrok para testes locais, documentação oficial Meta como referência primária, reservar 2 dias exclusivos para setup e validação |
| Alucinações da IA gerando preços ou promessas indevidas | **Alta** | **Alto** | Prompt base com restrições explícitas, validação de output antes de enviar ao cliente, logs de todas as respostas para revisão |
| Prazo curto (25 dias) para escopo amplo | **Alta** | **Médio** | Foco em MVP funcional ponta a ponta, features adicionais vão para backlog pós-apresentação, priorização rígida no Sprint Planning |
| Desalinhamento técnico do time em tecnologias novas | **Média** | **Médio** | Pair programming nas integrações críticas, Frank apoia o time na parte de IA, Nikolas garante padrão arquitetural |
| Qualidade ruim do RAG por base de conhecimento incompleta | **Alta** | **Médio** | PO Diego valida e complementa base de conhecimento na Fase 1, chunks testados antes da Fase 2 |
| Timeout do webhook da Meta (> 5 segundos) | **Média** | **Alto** | Processamento assíncrono: webhook responde imediatamente com 200, processamento IA em background via fila |
| Mudanças de escopo durante o desenvolvimento | **Baixa** | **Médio** | Mudanças só entram em sprints futuros, sem interromper sprint em andamento, decisão do PO + Scrum Master |

---

## 15. Configuração — Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|---|---|---|
| `WHATSAPP_TOKEN` | **Sim** | Token de acesso da Meta (WhatsApp Cloud API) |
| `PHONE_NUMBER_ID` | **Sim** | ID do número de telefone registrado na Meta |
| `VERIFY_TOKEN` | **Sim** | Token secreto para verificação do webhook pela Meta |
| `OPENAI_API_KEY` | **Sim** | Chave da API OpenAI para o modelo de linguagem (GPT) |
| `DATABASE_URL` | **Sim** | String de conexão com PostgreSQL ou MongoDB |
| `JWT_SECRET_KEY` | **Sim** | Chave secreta para assinatura dos tokens JWT |
| `FIREBASE_CREDENTIALS` | **Sim** | Caminho para o arquivo JSON de credenciais do Firebase Admin |
| `CHROMA_PERSIST_DIR` | Não | Diretório de persistência do ChromaDB (padrão: `./chroma_db`) |
| `LANGCHAIN_API_KEY` | Não | Chave LangSmith para observabilidade das chains (opcional) |
| `DEBUG` | Não | Modo debug: `true` \| `false` (padrão: `false` em produção) |
