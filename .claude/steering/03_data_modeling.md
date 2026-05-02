## 4. Modelagem de Dados

### 4.1 Entidade: LEAD

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único gerado automaticamente |
| `nome` | String | Não | Nome extraído pela IA ou informado pelo cliente |
| `telefone` | String | **Sim** | Número WhatsApp — chave de identificação do contato |
| `origem` | Enum | **Sim** | Canal de entrada: `whatsapp` \| `app` \| `web` |
| `status` | Enum | **Sim** | `novo` \| `em_atendimento` \| `qualificado` \| `agendado` \| `proposta` \| `fechado` \| `perdido` |
| `score` | Enum | Não | Temperatura do lead: `quente` \| `morno` \| `frio` |
| `criado_em` | DateTime | **Sim** | Timestamp da criação do registro |
| `atualizado_em` | DateTime | **Sim** | Timestamp da última atualização |

### 4.2 Entidade: BRIEFING

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead pai |
| `destino` | String | Não | Destino desejado extraído pela IA |
| `origem` | String | Não | Cidade/país de origem do cliente |
| `data_ida` | Date | Não | Data de partida desejada |
| `data_volta` | Date | Não | Data de retorno desejada |
| `duracao_dias` | Integer | Não | Duração calculada da viagem em dias |
| `qtd_pessoas` | Integer | Não | Número de viajantes |
| `perfil` | String | Não | Perfil: `casal` \| `família` \| `solo` \| `grupo` \| `amigos` |
| `tipo_viagem` | String[] | Não | `turismo` \| `lazer` \| `aventura` \| `imigração` \| `negócios` |
| `preferencias` | String[] | Não | `frio` \| `calor` \| `praia` \| `cidade` \| `luxo` \| `econômico` |
| `orcamento` | Enum | Não | `baixo` \| `médio` \| `alto` \| `premium` |
| `tem_passaporte` | Boolean | Não | Cliente possui passaporte válido |
| `observacoes` | String | Não | Observações livres extraídas da conversa |
| `completude_pct` | Integer | Não | Percentual de campos preenchidos (0–100) |

### 4.3 Entidade: INTERAÇÃO

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único da mensagem |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `mensagem_cliente` | Text | Não | Texto enviado pelo cliente |
| `mensagem_ia` | Text | Não | Resposta gerada pela IA |
| `tipo_mensagem` | Enum | **Sim** | `texto` \| `audio` \| `imagem` \| `documento` |
| `timestamp` | DateTime | **Sim** | Momento da interação |

### 4.4 Entidade: AGENDAMENTO

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `data` | Date | **Sim** | Data da curadoria |
| `hora` | Time | **Sim** | Horário do atendimento |
| `status` | Enum | **Sim** | `pendente` \| `confirmado` \| `realizado` \| `cancelado` |
| `tipo` | Enum | **Sim** | `online` \| `presencial` |
| `consultor_id` | UUID (FK) | Não | Consultor responsável pelo atendimento |

### 4.5 Entidade: PROPOSTA

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `descricao` | String | **Sim** | Resumo da proposta (ex: 'Pacote Portugal 10 dias') |
| `valor_estimado` | Decimal | Não | Valor estimado em BRL |
| `status` | Enum | **Sim** | `rascunho` \| `enviada` \| `aprovada` \| `recusada` \| `em_revisao` |
| `criado_em` | DateTime | **Sim** | Data de criação da proposta |
