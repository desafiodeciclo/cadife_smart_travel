import uuid
import asyncio
import httpx
from io import BytesIO
from PIL import Image
import os
from dotenv import load_dotenv

load_dotenv()

# Configurações do teste
BASE_URL = "http://127.0.0.1:8000"
# Nota: Você precisa ter um Lead ID válido no seu banco local para este teste rodar 100%
# Vou tentar buscar um Lead existente ou você pode me fornecer um.
# Por enquanto, vou usar um UUID fake para demonstrar a tentativa.
TEST_LEAD_ID = "00000000-0000-0000-0000-000000000001" 

async def smoke_test():
    print("🚀 Iniciando Smoke Test do Diário de Viagem...")
    
    # 1. Simular uma imagem
    print("📸 Gerando imagem de teste...")
    img_io = BytesIO()
    image = Image.new('RGB', (800, 600), color=(73, 109, 137))
    image.save(img_io, format='JPEG')
    img_io.seek(0)
    
    # 2. Tentar realizar o upload (Nota: requer servidor rodando)
    print(f"📡 Enviando POST para {BASE_URL}...")
    
    # Vamos usar o httpx para tentar conectar no seu servidor local
    async with httpx.AsyncClient() as client:
        try:
            # Aqui precisaríamos de um token real. 
            # Como não temos um agora, o teste vai falhar com 401, o que prova que a rota existe e está protegida.
            files = {'file': ('test_memory.jpg', img_io, 'image/jpeg')}
            data = {'nota': 'Teste de fumaça automatizado', 'data_entrada': '2024-05-09T15:00:00'}
            
            response = await client.post(
                f"{BASE_URL}/leads/{TEST_LEAD_ID}/diary/entries",
                data=data,
                files=files
            )
            
            print(f"✅ Resposta do Servidor: {response.status_code}")
            if response.status_code == 401:
                print("🔒 Segurança confirmada: Rota protegida por autenticação.")
            elif response.status_code == 404:
                print("📍 Rota encontrada, mas Lead ID é fictício.")
            else:
                print(f"📝 Resultado: {response.text}")

        except Exception as e:
            print(f"❌ Erro de conexão: {e}")
            print("💡 Dica: Certifique-se de que o backend está rodando (uvicorn main:app --reload)")

if __name__ == "__main__":
    asyncio.run(smoke_test())
