# AI Agent Technical Specs

Documentação técnica aprofundada da inteligência artificial (AYA).

## 1. Estrutura do Payload de Briefing Extraído

Exemplo de JSON gerado após extração automática pela IA:

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

## 2. Base de Conhecimento RAG (Cadife Tour)

Documentos indexados no Vector Database (ChromaDB / PGVector):

| Arquivo | Tipo | Conteúdo |
|---|---|---|
| `identidade_empresa.txt` | **Institucional** | Missão, valores, posicionamento, diferenciais da Cadife Tour |
| `fluxo_atendimento.txt` | **Processo** | Etapas de recepção, qualificação, curadoria e encaminhamento |
| `faq.txt` | **FAQ** | Perguntas frequentes: visto, passaporte, seguro, documentação |
| `regras_negocio.txt` | **Regras** | Horários, pagamentos, prazos, limites de atendimento |
| `destinos.txt` | **Produtos** | Destinos principais, tipos de serviço, experiências ofertadas |
| `objecoes.txt` | **Vendas** | Estratégias para clientes indecisos, comparadores de preço, sumidos |
| `argumentacao.txt` | **Vendas** | Argumentação comercial consultiva e gatilhos de valor |

> **Configuração dos chunks:** 300–500 tokens por chunk, sem redundância, contexto objetivo.

## 3. Identidade do Assistente Virtual

| Atributo | Valor |
|---|---|
| **Nome** | AYA (ou NOA / OTTO — a definir com o PO Diego Gil) |
| **Tom** | Consultivo e próximo — 80% consultor / 20% vendedor |
| **Linguagem** | Natural, clara, educada e não invasiva |

## 4. Limitações Obrigatórias

**A IA NUNCA deve:**
- Gerar preços, valores ou estimativas financeiras.
- Confirmar disponibilidade de voos ou hospedagem.
- Fechar vendas ou comprometer a empresa comercialmente.

**A IA SEMPRE deve:**
- Manter respostas abertas, indicando que o consultor irá validar.
- Evitar afirmações definitivas sobre disponibilidade ou preço.
