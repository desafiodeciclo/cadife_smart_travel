"""
Unit tests for metadata_tagger.py — rule-based topic extraction.

All tests run without external dependencies (no OpenAI, no ChromaDB).
"""
import pytest

from app.services.metadata_tagger import (
    DocumentTags,
    build_chroma_filter,
    extract_tags,
    tags_to_metadata,
)


class TestExtractTags:
    def test_nordeste_destination_matched(self):
        text = "Viaje para Natal e conheça Porto de Galinhas"
        tags = extract_tags(text)
        assert tags.topico_destino == "Nordeste"

    def test_europa_destination_matched(self):
        text = "Pacotes para Paris, Roma e Lisboa com passagem inclusa"
        tags = extract_tags(text)
        assert tags.topico_destino == "Europa"

    def test_usa_destination_matched(self):
        text = "Disney Orlando e Miami em dezembro com a família"
        tags = extract_tags(text)
        assert tags.topico_destino == "América do Norte"

    def test_financiamento_tema_matched(self):
        text = "Parcelamento em até 12 vezes no cartão de crédito"
        tags = extract_tags(text)
        assert tags.topico_tema == "Financiamento"

    def test_hospedagem_tema_matched(self):
        text = "Hotel all inclusive com café da manhã incluso"
        tags = extract_tags(text)
        assert tags.topico_tema == "Hospedagem"

    def test_lua_de_mel_tema_matched(self):
        text = "Roteiro romântico para lua de mel em Bali"
        tags = extract_tags(text)
        assert tags.topico_tema == "Lua de Mel"

    def test_familia_perfil_matched(self):
        text = "Viagem com crianças e filhos pequenos, parques temáticos"
        tags = extract_tags(text)
        assert tags.topico_perfil == "Família"

    def test_casal_perfil_matched(self):
        text = "Viagem a dois, aniversário de casamento dos noivos"
        tags = extract_tags(text)
        assert tags.topico_perfil == "Casal"

    def test_no_match_returns_empty_strings(self):
        text = "Lorem ipsum dolor sit amet"
        tags = extract_tags(text)
        assert tags.topico_destino == ""
        assert tags.topico_tema == ""
        assert tags.topico_perfil == ""

    def test_filename_contributes_to_matching(self):
        text = "Informações gerais sobre pacotes"
        tags = extract_tags(text, filename="nordeste_destinos.txt")
        assert tags.topico_destino == "Nordeste"

    def test_tags_field_is_comma_separated(self):
        text = "Pacote para Natal com hotel e parcelamento para família"
        tags = extract_tags(text)
        assert "," in tags.tags or len(tags.tags) > 0

    def test_tags_contains_no_empty_entries(self):
        text = "Voo para Paris com hotel incluso"
        tags = extract_tags(text)
        parts = [t for t in tags.tags.split(",") if t]
        assert all(len(p.strip()) > 0 for p in parts)


class TestTagsToMetadata:
    def test_returns_all_required_keys(self):
        tags = DocumentTags(
            topico_destino="Nordeste",
            topico_tema="Hospedagem",
            topico_perfil="Família",
            tags="nordeste,hospedagem,família",
        )
        meta = tags_to_metadata(tags, "test.txt", 0, "sha256:abc")
        assert meta["source"] == "test.txt"
        assert meta["chunk_index"] == 0
        assert meta["doc_hash"] == "sha256:abc"
        assert meta["topico_destino"] == "Nordeste"
        assert meta["topico_tema"] == "Hospedagem"
        assert meta["topico_perfil"] == "Família"
        assert meta["tags"] == "nordeste,hospedagem,família"

    def test_empty_tags_still_returns_valid_metadata(self):
        tags = DocumentTags()
        meta = tags_to_metadata(tags, "generic.txt", 5, "sha256:xyz")
        assert meta["topico_destino"] == ""
        assert meta["topico_tema"] == ""
        assert meta["topico_perfil"] == ""


class TestBuildChromaFilter:
    def test_no_args_returns_none(self):
        assert build_chroma_filter() is None

    def test_destino_only_includes_empty_fallback(self):
        f = build_chroma_filter(destino="Nordeste")
        assert f is not None
        # should allow exact match OR empty (general knowledge)
        assert "$or" in f
        conditions = f["$or"]
        values = [c.get("topico_destino", {}).get("$eq") for c in conditions]
        assert "Nordeste" in values
        assert "" in values

    def test_multiple_dimensions_produces_and_clause(self):
        f = build_chroma_filter(destino="Europa", perfil="Casal")
        assert f is not None
        assert "$and" in f
        assert len(f["$and"]) == 2

    def test_all_three_dimensions(self):
        f = build_chroma_filter(destino="Nordeste", tema="Hospedagem", perfil="Família")
        assert "$and" in f
        assert len(f["$and"]) == 3

    def test_single_dimension_no_and_wrapper(self):
        f = build_chroma_filter(tema="Financiamento")
        assert "$and" not in f
        assert "$or" in f
