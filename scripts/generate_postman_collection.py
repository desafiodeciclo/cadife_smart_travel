"""
Gerador de Postman Collection v2.1 a partir do OpenAPI spec do Cadife Smart Travel.
Adiciona exemplos de request/response para os fluxos críticos:
  - login, webhook, criar lead, listar leads, criar proposta
"""
import json
import uuid
from pathlib import Path

OPENAPI_PATH = Path("docs/api/openapi.json")
COLLECTION_PATH = Path("docs/api/Cadife_Smart_Travel_API.postman_collection.json")


def build_collection(openapi: dict) -> dict:
    info = openapi.get("info", {})
    servers = openapi.get("servers", [{}])
    base_url = servers[0].get("url", "http://localhost:8000") if servers else "http://localhost:8000"

    collection = {
        "info": {
            "_postman_id": str(uuid.uuid4()),
            "name": info.get("title", "Cadife Smart Travel API"),
            "description": info.get("description", ""),
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        },
        "item": [],
        "variable": [
            {"key": "baseUrl", "value": base_url, "type": "string"},
            {"key": "accessToken", "value": "", "type": "string"},
        ],
    }

    # Agrupar por tag
    tags_map: dict[str, list] = {}
    paths = openapi.get("paths", {})
    for path, methods in paths.items():
        for method, details in methods.items():
            if method == "parameters":
                continue
            tag = "Default"
            if details.get("tags"):
                tag = details["tags"][0]
            entry = {
                "name": details.get("summary", f"{method.upper()} {path}"),
                "request": {
                    "method": method.upper(),
                    "header": [],
                    "url": {
                        "raw": "{{baseUrl}}" + path,
                        "host": ["{{baseUrl}}"],
                        "path": path.strip("/").split("/"),
                    },
                    "description": details.get("description", ""),
                },
                "response": [],
            }

            # Auth header para endpoints protegidos
            if any(
                "HTTPBearer" in sec or "OAuth2PasswordBearer" in sec
                for sec in details.get("security", [])
            ):
                entry["request"]["header"].append(
                    {
                        "key": "Authorization",
                        "value": "Bearer {{accessToken}}",
                        "type": "text",
                    }
                )

            # Body
            req_body = details.get("requestBody", {})
            if req_body:
                content = req_body.get("content", {})
                if "application/json" in content:
                    schema = content["application/json"].get("schema", {})
                    example = content["application/json"].get("example")
                    entry["request"]["body"] = {
                        "mode": "raw",
                        "raw": json.dumps(example, indent=2, ensure_ascii=False)
                        if example
                        else "{}",
                        "options": {"raw": {"language": "json"}},
                    }

            # Query params
            params = details.get("parameters", [])
            query = []
            for p in params:
                if p.get("in") == "query":
                    query.append(
                        {
                            "key": p["name"],
                            "value": str(p.get("example", "")),
                            "description": p.get("description", ""),
                        }
                    )
            if query:
                entry["request"]["url"]["query"] = query

            tags_map.setdefault(tag, []).append(entry)

    for tag, items in tags_map.items():
        collection["item"].append({"name": tag, "item": items})

    return collection


def inject_critical_examples(collection: dict) -> dict:
    """Adiciona exemplos manuais nos fluxos críticos."""

    examples = {
        "Auth": {
            "match": lambda i: i["request"]["method"] == "POST" and "/auth/login" in i["request"]["url"]["raw"],
            "request": {
                "email": "consultor@cadifetour.com.br",
                "password": "SenhaSegura123!",
            },
            "response": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 3600,
            },
        },
        "Webhook": {
            "match": lambda i: i["request"]["method"] == "POST" and "/webhook/whatsapp" in i["request"]["url"]["raw"],
            "request": {
                "object": "whatsapp_business_account",
                "entry": [
                    {
                        "id": "123456789",
                        "changes": [
                            {
                                "value": {
                                    "messaging_product": "whatsapp",
                                    "metadata": {
                                        "display_phone_number": "5511999999999",
                                        "phone_number_id": "987654321",
                                    },
                                    "contacts": [{"profile": {"name": "Maria Silva"}, "wa_id": "5511988888888"}],
                                    "messages": [
                                        {
                                            "from": "5511988888888",
                                            "id": "wamid.abc123",
                                            "timestamp": "1715160000",
                                            "type": "text",
                                            "text": {"body": "Olá, quero planejar uma viagem para o Japão em setembro!"},
                                        }
                                    ],
                                },
                                "field": "messages",
                            }
                        ],
                    }
                ],
            },
            "response": {"status": "received"},
        },
        "Leads": {
            "match": lambda i: i["request"]["method"] == "POST" and i["request"]["url"]["raw"].endswith("/leads"),
            "request": {
                "nome": "João Pereira",
                "telefone": "5511977777777",
                "origem": "whatsapp",
            },
            "response": {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "nome": "João Pereira",
                "telefone": "5511977777777",
                "origem": "whatsapp",
                "status": "novo",
                "score": None,
                "consultor_id": None,
                "consultor_nome": None,
                "consultor_avatar": None,
                "is_archived": False,
                "criado_em": "2025-06-01T10:00:00Z",
                "atualizado_em": "2025-06-01T10:00:00Z",
                "propostas": [],
            },
        },
        "LeadsList": {
            "match": lambda i: i["request"]["method"] == "GET" and "/leads" in i["request"]["url"]["raw"] and "/leads/" not in i["request"]["url"]["raw"],
            "request": None,
            "response": {
                "items": [
                    {
                        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                        "nome": "João Pereira",
                        "telefone_mascarado": "55119****7777",
                        "origem": "whatsapp",
                        "status": "novo",
                        "score": None,
                        "criado_em": "2025-06-01T10:00:00Z",
                        "atualizado_em": "2025-06-01T10:00:00Z",
                        "completude_pct": 0,
                    }
                ],
                "total": 1,
                "page": 1,
                "limit": 20,
                "pages": 1,
            },
        },
        "Propostas": {
            "match": lambda i: i["request"]["method"] == "POST" and "/propostas" in i["request"]["url"]["raw"],
            "request": {
                "lead_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "descricao": "Pacote premium Japão 10 dias — Tokyo, Kyoto e Osaka. Inclui passagem aérea, hospedagem 4★ e passeios guiados.",
                "valor_estimado": 18500.00,
                "expiration_hours": 72,
            },
            "response": {
                "id": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
                "lead_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "descricao": "Pacote premium Japão 10 dias — Tokyo, Kyoto e Osaka. Inclui passagem aérea, hospedagem 4★ e passeios guiados.",
                "valor_estimado": 18500.00,
                "status": "rascunho",
                "consultor_id": "c3d4e5f6-a7b8-9012-cdef-345678901234",
                "expiration_hours": 72,
                "criado_em": "2025-06-01T14:30:00Z",
            },
        },
    }

    for folder in collection.get("item", []):
        for item in folder.get("item", []):
            for key, ex in examples.items():
                if ex["match"](item):
                    if ex["request"] is not None:
                        item["request"]["body"] = {
                            "mode": "raw",
                            "raw": json.dumps(ex["request"], indent=2, ensure_ascii=False),
                            "options": {"raw": {"language": "json"}},
                        }
                    # Adiciona exemplo de response
                    item["response"].append(
                        {
                            "name": f"Exemplo {key}",
                            "originalRequest": item["request"],
                            "status": "OK",
                            "code": 200 if key != "Leads" else 201,
                            "body": json.dumps(ex["response"], indent=2, ensure_ascii=False),
                            "header": [{"key": "Content-Type", "value": "application/json"}],
                        }
                    )

    return collection


def main():
    openapi = json.loads(OPENAPI_PATH.read_text(encoding="utf-8"))
    collection = build_collection(openapi)
    collection = inject_critical_examples(collection)
    COLLECTION_PATH.write_text(json.dumps(collection, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Postman Collection gerada: {COLLECTION_PATH}")


if __name__ == "__main__":
    main()
