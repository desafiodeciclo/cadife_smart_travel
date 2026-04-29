"""
Semantic Metadata Tagger — Rule-based topic extraction for RAG chunks.

Assigns semantic metadata tags to document chunks for ChromaDB hard-constraint
filtering. Tags narrow bot queries to topically relevant content only.
"""
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Topic taxonomy — Cadife Tour knowledge domain
# ---------------------------------------------------------------------------

DESTINO_KEYWORDS: dict[str, list[str]] = {
    "Nordeste": [
        "nordeste", "natal", "fortaleza", "recife", "salvador", "maceió",
        "joão pessoa", "aracaju", "teresina", "são luís", "lençóis",
        "noronha", "fernando de noronha", "jericoacoara", "porto de galinhas",
        "carneiros", "praia do forte", "arraial d'ajuda",
    ],
    "Sudeste": [
        "sudeste", "rio de janeiro", "são paulo", "belo horizonte", "búzios",
        "angra dos reis", "ilhabela", "arraial do cabo", "cabo frio", "paraty",
        "petrópolis", "visconde de mauá",
    ],
    "Sul": [
        "sul", "florianópolis", "curitiba", "porto alegre", "foz do iguaçu",
        "bombinhas", "balneário camboriú", "gramado", "canela", "bento gonçalves",
        "blumenau", "joinville",
    ],
    "Centro-Oeste": [
        "centro-oeste", "brasília", "goiânia", "campo grande", "cuiabá",
        "pantanal", "chapada dos guimarães", "chapada diamantina", "bonito",
        "corumbá",
    ],
    "Norte": [
        "norte", "manaus", "belém", "amazon", "amazônia", "santarém",
        "alter do chão", "marajó",
    ],
    "Europa": [
        "europa", "paris", "roma", "lisboa", "madrid", "barcelona", "amsterdam",
        "praga", "viena", "london", "londra", "berlim", "veneza", "grécia",
        "atenas", "dublin", "edimburgo", "zurique", "genebra", "bruxelas",
        "copenhague", "estocolmo", "oslo", "helsinki", "budapest", "varsóvia",
        "istanbul", "moscou",
    ],
    "América do Norte": [
        "estados unidos", "eua", "usa", "miami", "orlando", "nova york",
        "new york", "los angeles", "las vegas", "chicago", "disney", "universal",
        "canadá", "toronto", "vancouver", "montreal", "cancún", "cancun",
        "méxico", "cidade do méxico",
    ],
    "América do Sul": [
        "argentina", "buenos aires", "bariloche", "iguazú", "chile", "santiago",
        "atacama", "peru", "lima", "machu picchu", "cusco", "colômbia", "bogotá",
        "cartagena", "uruguai", "montevidéu", "punta del este", "bolívia",
        "equador", "galápagos",
    ],
    "Caribe": [
        "caribe", "punta cana", "cuba", "havana", "aruba", "jamaica", "bahamas",
        "ilhas virgens", "curaçao", "barbados", "trinidad", "antilhas",
    ],
    "Ásia": [
        "ásia", "asia", "japão", "tokyo", "kyoto", "osaka", "china", "pequim",
        "xangai", "tailândia", "bangkok", "phuket", "bali", "indonésia",
        "dubai", "emirados árabes", "índia", "cingapura", "hong kong",
        "coreia do sul", "seul", "vietnã", "hanói", "ho chi minh", "maldivas",
    ],
    "África": [
        "áfrica", "quênia", "tanzânia", "safari", "cape town", "cidade do cabo",
        "marrocos", "marrakech", "egito", "cairo",
    ],
    "Oceania": [
        "oceania", "austrália", "sydney", "melbourne", "nova zelândia", "auckland",
        "fiji",
    ],
}

TEMA_KEYWORDS: dict[str, list[str]] = {
    "Financiamento": [
        "financiamento", "parcelamento", "parcelas", "entrada", "crédito",
        "pagamento", "forma de pagamento", "boleto", "cartão", "pix",
        "sinal", "antecipação", "refinanciamento",
    ],
    "Passagens": [
        "passagem", "voo", "aéreo", "voos", "companhia aérea", "embarque",
        "conexão", "escala", "milhas", "programa de milhas", "smiles", "tudoazul",
        "latam pass", "despacho de bagagem", "bagagem",
    ],
    "Hospedagem": [
        "hotel", "pousada", "resort", "hospedagem", "acomodação", "quarto",
        "all inclusive", "café da manhã", "check-in", "check-out", "suite",
        "chalé", "airbnb", "hostel",
    ],
    "Pacotes": [
        "pacote", "pacote completo", "pacote turístico", "combo", "roteiro",
        "itinerário", "programação", "transfer", "rodoviário", "incluso",
    ],
    "Cruzeiros": [
        "cruzeiro", "navio", "msc", "costa", "royal caribbean", "norwegian",
        "porto", "embarcação", "camarote", "excursão de porto",
    ],
    "Seguro Viagem": [
        "seguro viagem", "seguro", "assistência médica", "emergência médica",
        "cobertura", "sinistro", "repatriação", "cancelamento",
    ],
    "Documentação": [
        "passaporte", "visto", "documentos", "documentação", "rcn",
        "certidão", "autenticação", "apostila", "consulado", "embaixada",
        "validade do passaporte",
    ],
    "Lua de Mel": [
        "lua de mel", "honeymoon", "romântico", "romance", "viagem a dois",
        "aniversário de casamento", "noivos", "casamento", "surpresa",
        "jantar romântico",
    ],
    "Aventura": [
        "aventura", "ecoturismo", "trilha", "rapel", "rafting", "mergulho",
        "snorkel", "kitesurf", "surf", "windsurf", "escalada", "bungee",
        "parapente", "tirolesa", "canyoning",
    ],
    "Gastronomia": [
        "gastronomia", "culinária", "restaurante", "comida típica", "degustação",
        "vinhos", "vinícola", "tour gastronômico", "food tour", "mercado",
    ],
    "Destinos": [
        "destino", "destinos", "onde ir", "onde viajar", "opções de viagem",
        "melhores destinos", "sugestões",
    ],
}

PERFIL_KEYWORDS: dict[str, list[str]] = {
    "Família": [
        "família", "criança", "filho", "filhos", "crianças", "kids", "infantil",
        "parque temático", "bebê", "bebe", "adolescente", "escola",
    ],
    "Casal": [
        "casal", "lua de mel", "honeymoon", "noivos", "dois", "romântico",
        "aniversário de casamento", "parceiro", "cônjuge",
    ],
    "Solo": [
        "solo", "sozinho", "mochileiro", "backpacker", "solo travel",
        "viagem sozinha", "viagem sozinho",
    ],
    "Grupo": [
        "grupo", "turma", "amigos", "confraternização", "corporativo",
        "incentivo", "time", "equipe", "escola", "faculdade",
    ],
    "Luxo": [
        "luxo", "premium", "5 estrelas", "cinco estrelas", "vip", "exclusivo",
        "primeira classe", "business class", "suite presidencial", "iate",
        "helicóptero",
    ],
    "Econômico": [
        "econômico", "barato", "low cost", "menor preço", "acessível",
        "promoção", "desconto", "orçamento limitado",
    ],
    "Aventura": [
        "aventureiro", "adrenalina", "ecoturismo", "trilha", "natureza",
        "off-road", "mochileiro",
    ],
}


# ---------------------------------------------------------------------------
# Tag extraction result
# ---------------------------------------------------------------------------

@dataclass
class DocumentTags:
    topico_destino: str = ""
    topico_tema: str = ""
    topico_perfil: str = ""
    tags: str = ""  # comma-separated; ChromaDB doesn't support list metadata


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def extract_tags(text: str, filename: str = "") -> DocumentTags:
    """
    Extract semantic tags from a text chunk using rule-based keyword matching.

    Returns DocumentTags with the best-matching category for each dimension.
    All fields default to "" when no match is found (prevents false hard-constraints).
    """
    normalized = _normalize(text + " " + filename)

    destino = _best_match(normalized, DESTINO_KEYWORDS)
    tema = _best_match(normalized, TEMA_KEYWORDS)
    perfil = _best_match(normalized, PERFIL_KEYWORDS)

    raw_tags: list[str] = []
    if destino:
        raw_tags.append(destino.lower())
    if tema:
        raw_tags.append(tema.lower())
    if perfil:
        raw_tags.append(perfil.lower())

    return DocumentTags(
        topico_destino=destino,
        topico_tema=tema,
        topico_perfil=perfil,
        tags=",".join(raw_tags),
    )


def tags_to_metadata(tags: DocumentTags, source: str, chunk_index: int, doc_hash: str) -> dict:
    """Build the full ChromaDB-compatible metadata dict for a chunk."""
    return {
        "source": source,
        "chunk_index": chunk_index,
        "doc_hash": doc_hash,
        "topico_destino": tags.topico_destino,
        "topico_tema": tags.topico_tema,
        "topico_perfil": tags.topico_perfil,
        "tags": tags.tags,
    }


def build_chroma_filter(
    destino: str | None = None,
    tema: str | None = None,
    perfil: str | None = None,
) -> dict | None:
    """
    Build a ChromaDB where-clause that applies hard constraints AND always
    allows chunks with no topic tag (general knowledge base content).

    A chunk with topico_destino="" is included regardless of the destino filter
    so that generic Cadife Tour content is never excluded.
    """
    conditions: list[dict] = []

    if destino:
        conditions.append({
            "$or": [
                {"topico_destino": {"$eq": destino}},
                {"topico_destino": {"$eq": ""}},
            ]
        })
    if tema:
        conditions.append({
            "$or": [
                {"topico_tema": {"$eq": tema}},
                {"topico_tema": {"$eq": ""}},
            ]
        })
    if perfil:
        conditions.append({
            "$or": [
                {"topico_perfil": {"$eq": perfil}},
                {"topico_perfil": {"$eq": ""}},
            ]
        })

    if not conditions:
        return None
    if len(conditions) == 1:
        return conditions[0]
    return {"$and": conditions}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _normalize(text: str) -> str:
    return text.lower()


def _best_match(normalized: str, taxonomy: dict[str, list[str]]) -> str:
    """Return the category with the highest keyword hit count, or '' if none."""
    best_category = ""
    best_score = 0

    for category, keywords in taxonomy.items():
        score = sum(1 for kw in keywords if kw in normalized)
        if score > best_score:
            best_score = score
            best_category = category

    return best_category
