## 6. Especificação da Inteligência Artificial (RAG)

### 6.1 Arquitetura da Camada de IA

A IA é composta por três módulos integrados via LangChain:

- **Módulo RAG:** recuperação de contexto da base de conhecimento da Cadife Tour via embeddings vetoriais (ChromaDB / PGVector)
- **Módulo de Extração:** prompt estruturado que identifica entidades do briefing (destino, datas, pessoas, orçamento, perfil) na conversa
- **Módulo de Decisão (Motor de Fluxo):** avalia completude do briefing e roteia para curadoria, coleta adicional ou consultor

### 6.2 Identidade do Assistente Virtual

| Atributo | Valor |
|---|---|
| **Nome** | AYA (ou NOA / OTTO — a definir com o PO Diego Gil) |
| **Tom** | Consultivo e próximo — 80% consultor / 20% vendedor |
| **Linguagem** | Natural, clara, educada e não invasiva |
| **Apresentação** | "Olá, sou a AYA da Cadife Tour. Vou te ajudar a organizar sua próxima viagem." |

### 6.3 Limitações Obrigatórias da IA

**A IA NUNCA deve:**

- Gerar preços, valores ou estimativas financeiras
- Confirmar disponibilidade de voos ou hospedagem
- Fechar vendas ou comprometer a empresa comercialmente
- Tomar decisões comerciais críticas de forma autônoma

**A IA SEMPRE deve:**

- Manter respostas abertas, indicando que o consultor irá validar
- Evitar afirmações definitivas sobre disponibilidade ou preço
- Preservar tom humano e natural, mesmo sendo automatizada

### 6.4 Fluxo de Qualificação (Briefing)

A IA conduz perguntas estratégicas para preencher o briefing:

| # | Campo | Pergunta estratégica |
|---|---|---|
| **1** | **Destino** | *Você já tem um destino em mente, ou posso te ajudar a escolher?* |
| **2** | **Datas** | *Tem alguma data em mente para a viagem? Ou ainda está avaliando?* |
| **3** | **Nº Pessoas** | *Quantas pessoas vão viajar com você?* |
| **4** | **Perfil da viagem** | *É uma viagem em família, casal, sozinho ou grupo de amigos?* |
| **5** | **Tipo** | *O que você busca: turismo, lazer, aventura, imigração ou outra coisa?* |
| **6** | **Preferências** | *Prefere clima frio ou quente? Praia ou cidade? Algo mais específico?* |
| **7** | **Orçamento** | *Tem uma faixa de investimento em mente? (Apenas para eu te orientar melhor)* |
| **8** | **Passaporte** | *Já possui passaporte válido?* |
| **9** | **Viagens anteriores** | *Já viajou internacionalmente antes?* |

### 6.5 Estrutura do Payload de Briefing Extraído pela IA

Exemplo de JSON gerado após extração automática:

```json
{
  "destino": "Portugal",
  "data_ida": "2026-02-10",
  "data_volta": "2026-02-20",
  "qtd_pessoas": 3,
  "perfil": "família",
  "tipo_viagem": ["turismo", "imigração"],
  "preferencias": ["cidade", "cultura"],
  "orcamento": "médio",
  "tem_passaporte": true,
  "observacoes": "primeira viagem internacional da família",
  "completude_pct": 85
}
```

### 6.6 Base de Conhecimento RAG (Cadife Tour)

Documentos indexados no Vector Database:

| Arquivo | Tipo | Conteúdo |
|---|---|---|
| `identidade_empresa.txt` | **Institucional** | Missão, valores, posicionamento, diferenciais da Cadife Tour |
| `fluxo_atendimento.txt` | **Processo** | Etapas de recepção, qualificação, curadoria e encaminhamento |
| `faq.txt` | **FAQ** | Perguntas frequentes: visto, passaporte, seguro, documentação |
| `regras_negocio.txt` | **Regras** | Horários, pagamentos, prazos, limites de atendimento |
| `destinos.txt` | **Produtos** | Destinos principais, tipos de serviço, experiências ofertadas |
| `objecoes.txt` | **Vendas** | Estratégias para clientes indecisos, comparadores de preço, sumidos |
| `argumentacao.txt` | **Vendas** | Argumentação comercial consultiva e gatilhos de valor |

> *Configuração dos chunks: 300–500 tokens por chunk, sem redundância, contexto objetivo.*
