"""
Troca o WHATSAPP_TOKEN de 24h por um token de longa duração (60 dias)
e atualiza o .env automaticamente.

Uso:
    cd backend
    venv/Scripts/python scripts/refresh_whatsapp_token.py

Pré-requisitos no .env:
    WHATSAPP_TOKEN   — token atual (mesmo que próximo do vencimento)
    META_APP_ID      — ID do app (Meta Developer Console → Configurações Básicas)
    META_APP_SECRET  — App Secret (mesmo lugar)
"""
import os
import re
import sys
from pathlib import Path

import httpx

ENV_PATH = Path(__file__).parent.parent / ".env"


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if not ENV_PATH.exists():
        return env
    for line in ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    return env


def update_env(key: str, new_value: str) -> None:
    text = ENV_PATH.read_text(encoding="utf-8")
    pattern = rf"^({re.escape(key)}=).*$"
    replacement = rf"\g<1>{new_value}"
    new_text, count = re.subn(pattern, replacement, text, flags=re.MULTILINE)
    if count == 0:
        new_text = text.rstrip("\n") + f"\n{key}={new_value}\n"
    ENV_PATH.write_text(new_text, encoding="utf-8")
    print(f"  .env atualizado: {key}=...{new_value[-10:]}")


def exchange_token(app_id: str, app_secret: str, short_token: str) -> str:
    url = "https://graph.facebook.com/v25.0/oauth/access_token"
    params = {
        "grant_type": "fb_exchange_token",
        "client_id": app_id,
        "client_secret": app_secret,
        "fb_exchange_token": short_token,
    }
    response = httpx.get(url, params=params, timeout=10)
    data = response.json()

    if "error" in data:
        err = data["error"]
        print(f"\nErro da Meta API: {err.get('message')} (code {err.get('code')})")
        sys.exit(1)

    return data["access_token"]


def inspect_token(token: str, app_id: str, app_secret: str) -> None:
    url = "https://graph.facebook.com/v25.0/debug_token"
    params = {
        "input_token": token,
        "access_token": f"{app_id}|{app_secret}",
    }
    response = httpx.get(url, params=params, timeout=10)
    data = response.json().get("data", {})
    import datetime
    expires_at = data.get("expires_at", 0)
    if expires_at:
        exp = datetime.datetime.fromtimestamp(expires_at)
        print(f"  Token expira em: {exp.strftime('%d/%m/%Y %H:%M')}")
    else:
        print("  Token não expira (permanente)")
    print(f"  Escopos: {', '.join(data.get('scopes', []))}")


def main() -> None:
    print("=== Refresh WhatsApp Token ===\n")

    env = load_env()
    token = env.get("WHATSAPP_TOKEN", "")
    app_id = env.get("META_APP_ID", "")
    app_secret = env.get("META_APP_SECRET", "")

    if not token:
        print("Erro: WHATSAPP_TOKEN não encontrado no .env")
        sys.exit(1)
    if not app_id:
        print("Erro: META_APP_ID não encontrado no .env")
        print("Adicione: META_APP_ID=seu_app_id  (Meta Developer Console → Configurações Básicas)")
        sys.exit(1)
    if not app_secret:
        print("Erro: META_APP_SECRET não encontrado no .env")
        sys.exit(1)

    print(f"Token atual: ...{token[-10:]}")
    print("Trocando por token de 60 dias...\n")

    new_token = exchange_token(app_id, app_secret, token)
    update_env("WHATSAPP_TOKEN", new_token)

    print("\nInspecionando novo token:")
    inspect_token(new_token, app_id, app_secret)

    print("\nToken atualizado com sucesso!")
    print("Reinicie o servidor para carregar o novo token.")


if __name__ == "__main__":
    main()
