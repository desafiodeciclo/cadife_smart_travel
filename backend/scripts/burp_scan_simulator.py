import os
import sys
import asyncio
import httpx
import structlog

# Ajusta o PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.infrastructure.security.jwt import create_access_token

logger = structlog.get_logger()
BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
ADMIN_ID = "00000000-0000-0000-0000-000000000001"

async def run_automated_scan():
    print(f"🔍 Iniciando Automated Scan (Burp Simulator) em {BASE_URL}...")
    
    token = create_access_token(ADMIN_ID)
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=5.0) as client:
        
        # --- 1. REFLECTED XSS ---
        print("\n[XSS] Testando XSS Refletido em /leads...")
        xss_payloads = [
            "<script>alert(1)</script>",
            "javascript:alert(1)",
            "'\"><img src=x onerror=alert(1)>"
        ]
        for p in xss_payloads:
            try:
                resp = await client.get("/leads", params={"search": p}, headers=headers)
                # Se o payload for refletido sem escape no corpo da resposta (JSON ou HTML), é risco Médio/Alto
                if p in resp.text:
                    print(f"  - 🔴 CRITICAL: Payload XSS refletido na resposta! ({p})")
                else:
                    print(f"  - ✅ Limpo: Payload XSS não refletido ({resp.status_code})")
            except Exception as e:
                print(f"  - Erro no teste de XSS: {e}")

        # --- 2. OS COMMAND INJECTION ---
        print("\n[OSINT] Testando OS Command Injection...")
        cmd_payloads = [
            "; ls -la",
            "| cat /etc/passwd",
            "& whoami",
            "`id`"
        ]
        # Testando em campos de busca e nomes de arquivos simulados
        for p in cmd_payloads:
            try:
                resp = await client.get("/leads", params={"search": p}, headers=headers)
                # Se o status for 500 ou houver indícios de output de comando no corpo
                if any(ind in resp.text for ind in ["root:", "total ", "uid="]):
                    print(f"  - 🔴 CRITICAL: Execução de comando detectada! ({p})")
                elif resp.status_code == 500:
                    print(f"  - 🟡 MEDIUM: Erro 500 com payload OSINT ({p}). Verificar logs.")
                else:
                    print(f"  - ✅ Seguro: Payload ignorado ({resp.status_code})")
            except Exception as e:
                print(f"  - Erro no teste de OSINT: {e}")

        # --- 3. CORS VALIDATION ---
        print("\n[CORS] Testando falhas de Cross-Origin Resource Sharing...")
        evil_origin = "http://evil-attacker.com"
        try:
            resp = await client.options("/leads", headers={"Origin": evil_origin, "Access-Control-Request-Method": "GET"})
            allow_origin = resp.headers.get("Access-Control-Allow-Origin", "")
            if allow_origin == "*" or allow_origin == evil_origin:
                print(f"  - 🟠 HIGH: CORS Excessivamente permissivo! Origin permitida: {allow_origin}")
            else:
                print(f"  - ✅ Seguro: Origin '{evil_origin}' não permitida ou tratada corretamente.")
        except Exception as e:
            print(f"  - Erro no teste de CORS: {e}")

        # --- 4. SQL INJECTION (Advanced) ---
        print("\n[SQLi] Testando Injeção SQL Avançada (Time-based)...")
        sqli_payloads = [
            "'; SELECT pg_sleep(2); --",
            "1' AND (SELECT 1 FROM (SELECT(SLEEP(2)))a)--"
        ]
        for p in sqli_payloads:
            start_time = asyncio.get_event_loop().time()
            try:
                resp = await client.get("/leads", params={"search": p}, headers=headers)
                duration = asyncio.get_event_loop().time() - start_time
                if duration >= 2.0:
                    print(f"  - 🔴 CRITICAL: Vulnerabilidade de Time-based SQLi detectada! (Duração: {duration:.2f}s)")
                else:
                    print(f"  - ✅ Seguro: Latência normal ({duration:.2f}s)")
            except Exception as e:
                print(f"  - Erro no teste de SQLi: {e}")

    print("\n✅ Automated Scan concluído.")

if __name__ == "__main__":
    asyncio.run(run_automated_scan())
