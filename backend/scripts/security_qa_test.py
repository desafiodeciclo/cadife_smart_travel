import asyncio
import httpx
import time

BASE_URL = "http://localhost:8000"

async def test_security_qa():
    print("🛠️ Iniciando Plano de Validação de QA de Segurança...")

    async with httpx.AsyncClient(timeout=10.0) as client:
        # --- 1. HEADER ANALYSIS ---
        print("\n[QA] Analisando Headers de Segurança...")
        try:
            resp = await client.get(f"{BASE_URL}/health")
            headers = resp.headers
            security_headers = [
                "Strict-Transport-Security",
                "Content-Security-Policy",
                "X-Content-Type-Options",
                "X-Frame-Options",
                "X-XSS-Protection"
            ]
            for h in security_headers:
                status = "✅" if h in headers else "❌ (Ausente)"
                print(f"  - {h}: {status}")
        except Exception as e:
            print(f"  - ❌ Erro ao ler headers: {type(e).__name__} - {str(e)}")

        # --- 2. ENDPOINT FUZZING ---
        print("\n[QA] Fuzzing de Endpoints (Caracteres Inesperados)...")
        fuzz_payloads = ["%00", "💩", "A" * 1000, "../../../etc/passwd", "None", "undefined"]
        for p in fuzz_payloads:
            try:
                resp = await client.get(f"{BASE_URL}/leads", params={"search": p})
                # Esperamos 401 (Unauthorized) ou 200 (Vazio), mas NUNCA 500
                status = "✅" if resp.status_code != 500 else "❌ CRITICAL (Internal Server Error)"
                print(f"  - Payload '{p[:20]}...': {resp.status_code} {status}")
            except Exception as e:
                print(f"  - Erro no fuzzing: {e}")

        # --- 3. RATE LIMITING RESILIENCE ---
        print("\n[QA] Testando Resiliência de Rate Limiting (Brute Force)...")
        print("  - Enviando 10 requisições sequenciais para /auth/login...")
        hit_429 = False
        for i in range(10):
            resp = await client.post(f"{BASE_URL}/auth/login", json={"email": "test@example.com", "password": "password"})
            if resp.status_code == 429:
                hit_429 = True
                break
        
        if hit_429:
            print(f"  - ✅ Rate Limit detectado (HTTP 429)! O sistema está protegido.")
        else:
            print(f"  - ⚠️ AVISO: Rate Limit não detectado em 10 requests. Verificar configuração.")

        # --- 4. JWT SECURITY (None Algorithm Bypass) ---
        print("\n[QA] Testando Bypass de JWT (Algoritmo 'None')...")
        # Header: {"alg": "none", "typ": "JWT"} -> Base64: eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0
        # Payload: {"sub": "00000000-0000-0000-0000-000000000001"} -> Base64: eyJzdWIiOiAiMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAxIn0
        none_token = "eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0.eyJzdWIiOiAiMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAxIn0."
        try:
            resp = await client.get(f"{BASE_URL}/leads", headers={"Authorization": f"Bearer {none_token}"})
            if resp.status_code == 401 or resp.status_code == 403:
                print("  - ✅ Seguro: Token 'None' rejeitado.")
            else:
                print(f"  - 🔴 CRITICAL: O sistema aceitou um token com algoritmo 'None'! (Status: {resp.status_code})")
        except Exception as e:
            print(f"  - Erro no teste de JWT: {e}")

    print("\n✅ Plano de Validação concluído.")

if __name__ == "__main__":
    asyncio.run(test_security_qa())
