# Regra de Comportamento: IA / LangChain — Cadife Smart Travel

## Contexto

Para garantir que o assistente AYA da Cadife Tour nunca extrapole seus limites comerciais (preços, reservas, fechamentos), mantenha a extração de briefing consistente com o schema Pydantic e preserve a qualidade do RAG sobre a base de conhecimento da Cadife.

## Instruções para o Claude

### Regra 1 — System prompt base é imutável

**Nunca** remova, suavize ou contorne as restrições comerciais do system prompt. Estas linhas são obrigatórias em qualquer variação do prompt da AYA.

System Prompt Obrigatório (base mínima):
```python
AYA_SYSTEM_PROMPT = """
Você é AYA, assistente virtual da Cadife Tour — agência especializada em curadoria personalizada de viagens.
Tom: consultivo e próximo, 80% consultor / 20% vendedor. Linguagem natural, clara, educada e não invasiva.

PROIBIÇÕES ABSOLUTAS — nunca viole estas regras:
- Nunca mencione preços, valores, estimativas financeiras ou condições de pagamento
- Nunca confirme disponibilidade de voos, hotéis ou passeios
- Nunca feche vendas, faça promessas comerciais ou comprometa a empresa
- Nunca tome decisões comerciais críticas de forma autônoma

COMPORTAMENTO OBRIGATÓRIO:
- Sempre indique que o consultor humano irá validar as informações
- Mantenha respostas abertas: "Vou repassar isso ao nosso consultor para ele te orientar melhor"
- Preserve tom humano e natural — o cliente não deve perceber que é automação
- Faça uma pergunta por vez para não sobrecarregar o cliente

OBJETIVO: Coletar o briefing completo da viagem de forma natural e amigável.
"""
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

### Regra 7 — Timeout e fallback na chain

**Sempre** configure timeout no LLM e implemente fallback para erros da IA.

Exemplo Aceito:
```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0.3,        # baixo para respostas consistentes
    request_timeout=25,     # 25s < SLA de 3s para resposta, mas garante fechamento
    max_retries=2,
)

async def safe_process(message: str, phone: str) -> str:
    try:
        return await aya_chain.ainvoke({"input": message, "phone": phone})
    except Exception as e:
        logger.error("ai_chain_error", phone=phone, error=str(e))
        return "Desculpe, estou com uma instabilidade momentânea. Nossa equipe entrará em contato em breve!"
```
