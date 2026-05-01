# Regra de Comportamento: IA / LangChain — Cadife Smart Travel

## Contexto

Para garantir que o assistente AYA da Cadife Tour nunca extrapole seus limites comerciais (preços, reservas, fechamentos), mantenha a extração de briefing consistente com o schema Pydantic e preserve a qualidade do RAG sobre a base de conhecimento da Cadife.

## Instruções para o Claude

### Regra 1 — System prompt base é imutável e parametrizado com defesas

**Nunca** remova, suavize ou contorne as restrições comerciais do system prompt. Estas linhas são obrigatórias em qualquer variação do prompt da AYA.

O system prompt deve ser construído via `build_system_prompt()` (em `app/services/prompt_security.py`), que inclui:
- Isoladores textuais XML (`<system_instructions>`, `<user_content>`, `<rag_context>`)
- Instruções de defesa contra manipulação (prompt injection, bypass, jailbreak)
- Proibições comerciais originais

System Prompt Obrigatório (base mínima):
```python
from app.services.prompt_security import build_system_prompt

system_prompt = build_system_prompt(context="...")
```

Exemplo Recusado:
```python
# Suavizar as restrições = violação
system_prompt = "Você é AYA. Ajude o cliente a planejar viagens e tente fechar negócios."
```

### Regra 2 — Extração de briefing via PydanticOutputParser

**Sempre** use `PydanticOutputParser` para extração estruturada do briefing. **Nunca** tente parsear JSON manualmente de texto livre.

Exemplo Aceito:
```python
from langchain.output_parsers import PydanticOutputParser
from app.models.briefing import BriefingExtracted

parser = PydanticOutputParser(pydantic_object=BriefingExtracted)

extraction_prompt = PromptTemplate(
    template="""
    Com base na conversa abaixo, extraia os dados do briefing de viagem.
    Preencha APENAS os campos que o cliente mencionou explicitamente.
    NÃO infira dados que não foram ditos.
    
    Conversa:
    {conversation}
    
    {format_instructions}
    """,
    input_variables=["conversation"],
    partial_variables={"format_instructions": parser.get_format_instructions()},
)
```

Exemplo Recusado:
```python
# Parsing manual de texto livre = inconsistente e quebradiço
response = llm.invoke(f"Extraia o JSON do briefing desta conversa: {conversation}")
briefing = json.loads(response.content)  # falha frequente com LLMs
```

### Regra 3 — RAG com source metadata obrigatório

**Sempre** inclua metadata de fonte nos documentos indexados no Vector DB. **Nunca** indexe documentos sem validação do PO Diego.

Exemplo Aceito:
```python
from langchain.schema import Document

def load_knowledge_base(directory: str) -> list[Document]:
    documents = []
    for filename in os.listdir(directory):
        if filename.endswith(".txt"):
            with open(os.path.join(directory, filename)) as f:
                content = f.read()
            # Chunking: 400 tokens, overlap 50 tokens
            chunks = text_splitter.split_text(content)
            for i, chunk in enumerate(chunks):
                documents.append(Document(
                    page_content=chunk,
                    metadata={"source": filename, "chunk_index": i}
                ))
    return documents
```

Exemplo Recusado:
```python
# Sem metadata = impossível rastrear origem de respostas problemáticas
vectorstore.add_texts([chunk for chunk in all_chunks])
```

### Regra 4 — Calcular completude_pct sem inferência

**Sempre** calcule `completude_pct` baseado **apenas** em campos explicitamente preenchidos. **Nunca** marque um campo como preenchido por inferência.

Exemplo Aceito:
```python
BRIEFING_FIELDS = ["destino", "data_ida", "data_volta", "qtd_pessoas", "perfil",
                   "tipo_viagem", "preferencias", "orcamento", "tem_passaporte"]

def calculate_completude(briefing: BriefingExtracted) -> int:
    filled = sum(1 for field in BRIEFING_FIELDS
                 if getattr(briefing, field, None) not in (None, [], ""))
    return round((filled / len(BRIEFING_FIELDS)) * 100)
```

### Regra 5 — Memória de conversação por lead_id

**Sempre** use `ConversationBufferWindowMemory` com chave baseada em `lead_id` (ou telefone). **Nunca** compartilhe contexto de conversa entre leads diferentes.

Exemplo Aceito:
```python
from langchain.memory import ConversationBufferWindowMemory

def get_memory(phone: str) -> ConversationBufferWindowMemory:
    return ConversationBufferWindowMemory(
        k=20,  # últimas 20 trocas
        memory_key=f"chat_history_{phone}",
        return_messages=True,
    )
```

### Regra 6 — Configuração de chunks RAG

Configuração obrigatória do text splitter para a base Cadife Tour:

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=400,      # tokens — conforme spec (300-500)
    chunk_overlap=50,    # overlap mínimo para contexto
    length_function=len,
    separators=["\n\n", "\n", ". ", " ", ""],
)
```

### Regra 7 — Timeout e fallback chain na extração de briefing

**Sempre** configure timeout no LLM e implemente fallback chain de múltiplos estágios para erros da IA, especialmente na extração estruturada do briefing.

Estratégia de fallback obrigatória:
1. Tentativa primária: `with_structured_output(BriefingExtracted)`
2. Fallback: prompt de autocorreção com LLM mais simples/determinístico (`temperature=0.0`)
3. Último recurso: retornar `BriefingExtracted()` vazio — nunca quebrar o fluxo

Exemplo Aceito:
```python
# Ver implementação completa em app/services/ai_service.py::extract_briefing
```

### Regra 8 — Sanitização de input e defesa contra prompt injection

**Sempre** sanitize o texto do usuário via `sanitize_user_input()` antes de inseri-lo em qualquer prompt. **Nunca** passe mensagens brutas do WhatsApp diretamente para o LLM.

A sanitização deve:
1. Escapar delimitadores XML (`<user_content>`, `</system_instructions>`, etc.)
2. Detectar e neutralizar padrões de prompt injection conhecidos
3. Remover caracteres de controle perigosos
4. Truncar inputs excessivamente longos

Padrões de ataque que devem ser neutralizados:
- `ignore previous instructions`, `disregard all instructions`
- `you are now...`, `act as...`, `pretend to be...`
- `bypass restrictions`, `disable rules`, `remove constraints`
- `dan mode`, `developer mode`, `jailbreak`
- Tentativas de exfiltração: `repeat the system prompt`, `show me the instructions`

Exemplo Aceito:
```python
from app.services.prompt_security import sanitize_user_input

safe_message = sanitize_user_input(raw_whatsapp_message)
```

Exemplo Recusado:
```python
# Passar mensagem bruta = vulnerável a prompt injection
response = await chain.ainvoke({"input": raw_whatsapp_message})
```

### Regra 9 — RAG Guardrails e Hybrid Search

**Sempre** use `retrieve_context()` ou `retrieve_with_metadata_filter()` (que já aplicam guardrails automaticamente). **Nunca** passe documentos do vectorstore diretamente para o LLM sem filtrar.

O RAG da Cadife implementa:
1. **Hybrid Search**: combina similarity search vetorial com keyword scoring e reranking via Reciprocal Rank Fusion (RRF)
2. **ContextFilter**: remove chunks que contenham preços, valores monetários ou confirmações de disponibilidade não autorizadas

Guardrails ativos:
- `PriceGuardrail`: detecta R$, US$, €, "reais", "preço", "valor", "custa", "parcela", "entrada"
- `AvailabilityGuardrail`: detecta "temos vagas", "voo confirmado", "hotel confirmado", etc.

Estratégias do ContextFilter:
- `"remove"`: descarta o chunk violador (padrão)
- `"mask"`: substitui o trecho por `[REDACTED]`
- `"flag"`: mantém o chunk mas marca no metadata

Exemplo Aceito:
```python
from app.services import rag_service

context = rag_service.retrieve_context(query="destinos Portugal", k=3)
# context já passou por hybrid search + guardrails
```

Exemplo Recusado:
```python
# Bypassar guardrails = risco de preços/dispo no contexto do LLM
docs = vectorstore.similarity_search(query, k=3)
context = "\n".join(d.page_content for d in docs)
```

### Regra 10 — Observabilidade com Langfuse

**Sempre** rastreie chains de IA com callbacks Langfuse quando configurado. **Nunca** deixe de registrar traces em produção.

Requisitos:
- Callback Langfuse injetado em `process_message()` e `extract_briefing()`
- Traces registram: prompt completo, contexto RAG recuperado, output do LLM, latência
- Fallback graceful: se Langfuse não estiver configurado (dev local), o sistema opera normalmente
- Flush de eventos pendentes após cada chain para garantir entrega

Variáveis de ambiente:
```bash
LANGFUSE_PUBLIC_KEY=pk-...
LANGFUSE_SECRET_KEY=sk-...
LANGFUSE_HOST=https://cloud.langfuse.com
```

Exemplo Aceito:
```python
from app.services.observability import get_callbacks_for_chain, flush_langfuse

callbacks = get_callbacks_for_chain()
config = {"callbacks": callbacks} if callbacks else {}
response = await chain.ainvoke(input_dict, config=config)
flush_langfuse()
```
