## 16. Stakeholders e Alinhamento

| Stakeholder | Papel | Envolvimento |
|---|---|---|
| **Diego Gil** | PO / CEO | Valida todas as entregas, define prioridades de negócio, conhecimento das regras operacionais da Cadife Tour, aprovação final do MVP |
| **Nikolas Tesch** | Scrum Master / Backend | Garante metodologia ágil, remove impedimentos, organiza cerimônias e artefatos |
| **Equipe de Desenvolvimento (6 membros)** | Dev Team | Execução técnica — sprints, code review, testes e integração |
| **Instrutores Alpha** | Avaliadores | Revisões de progresso, avaliação do projeto final e pitch de demo |
| **Clientes da Cadife Tour (leads)** | Usuários finais | Validação de fluxo UX via teste demo, feedback sobre atendimento da IA |
| **Consultores de Viagem (Cadife)** | Usuários internos | Uso do dashboard agência, feedback de usabilidade do CRM |
| **Terceiros (Marketing)** | Suporte | Fornecimento de logomarca, manual de identidade visual e conteúdos para base RAG |

---

## 17. Glossário

| Termo | Definição |
|---|---|
| **RAG** | Retrieval-Augmented Generation — técnica de IA que recupera documentos relevantes de uma base de conhecimento antes de gerar uma resposta, reduzindo alucinações |
| **Webhook** | Endpoint HTTP que recebe notificações automáticas de sistemas externos (neste projeto: da Meta/WhatsApp) quando há uma mensagem nova |
| **Lead** | Potencial cliente que iniciou contato com a Cadife Tour via WhatsApp e teve seus dados registrados no sistema |
| **Briefing** | Conjunto estruturado de informações do cliente: destino, datas, pessoas, orçamento, perfil — coletado pela IA durante a conversa |
| **Curadoria** | Processo de atendimento aprofundado e personalizado realizado pelo consultor humano da Cadife Tour |
| **FCM** | Firebase Cloud Messaging — serviço do Google para envio de notificações push para dispositivos móveis |
| **JWT** | JSON Web Token — padrão de autenticação stateless usado para proteger os endpoints da API |
| **Score de Lead** | Classificação da temperatura do lead (quente/morno/frio) baseada na completude do briefing e nível de interesse demonstrado |
| **LangChain** | Framework Python para orquestração de LLMs, com suporte a cadeia de prompts, RAG e memória de conversação |
| **Vector DB** | Banco de dados vetorial que armazena embeddings de documentos para busca semântica (ChromaDB ou PGVector) |
| **DoD** | Definition of Done — critérios que uma tarefa deve atender para ser considerada concluída pelo time |
| **MVP** | Minimum Viable Product — versão mínima funcional do produto que entrega valor real ao usuário |

---

*CADIFE SMART TRAVEL — Project Specification v1.0*
*Documento gerado para o Desafio Tech OmniConnect — Uso Interno*
*Cadife Tour — Plataforma de Atendimento Inteligente*
