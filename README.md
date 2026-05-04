# Cadife Smart Travel 🌍✈️

Assistente inteligente de atendimento turístico via WhatsApp e App Mobile, integrando IA (RAG) para propostas personalizadas.

> ⚠️ **STATUS ATUAL DO PROJETO:** O projeto encontra-se em fase de desenvolvimento e refatoração. Atualmente, existem **bloqueadores críticos** (erros de compilação, pacotes faltando, conflitos de nomenclatura) que impedem a execução direta tanto do Backend quanto do Frontend.
> 
> **ANTES DE QUALQUER ALTERAÇÃO OU TENTATIVA DE EXECUÇÃO:** Leia o documento obrigatório **[docs/STATUS_E_ROADMAP.md](./docs/STATUS_E_ROADMAP.md)**. Ele mapeia detalhadamente o estado atual (o que está quebrado) e a ordem de execução das sprints para estabilizar o sistema.

---

## 🏗️ Arquitetura
- **Backend**: FastAPI (Python 3.11) + SQLAlchemy/Alembic.
- **Frontend**: Flutter.
- **Banco de Dados**: PostgreSQL 16.
- **Cache/Rate Limit**: Redis.
- **Vetor DB (RAG)**: ChromaDB.
- **Orquestração**: Docker Compose.

---

## 🚀 Como Executar o Projeto (Comportamento Esperado)

> **Nota:** As instruções abaixo refletem como o projeto *deveria* ser executado. Devido ao status atual (veja o aviso acima), esses passos podem falhar até que os bloqueadores sejam resolvidos conforme o roadmap.

### 1. Pré-requisitos
- [Docker](https://www.docker.com/) & Docker Compose.
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (para rodar o app localmente).
- Chave de API da OpenAI (para as funcionalidades de IA).

---

### 2. Configuração do Backend (Docker)

O backend é totalmente containerizado, incluindo o banco de dados e serviços auxiliares.

1.  **Configurar Variáveis de Ambiente**:
    Navegue até a pasta `backend` e crie o arquivo `.env`:
    ```powershell
    cp backend/.env.example backend/.env
    ```
    > [!IMPORTANT]
    > Edite o arquivo `backend/.env` e insira sua `OPENAI_API_KEY`, juntamente com outras chaves obrigatórias descritas no `.env.example`.

2.  **Subir os Serviços**:
    Na raiz do projeto, execute:
    ```powershell
    docker compose -f docker/docker-compose.yml up --build -d
    ```

3.  **Verificar Status**:
    - API Health Check: [http://localhost:8000/health](http://localhost:8000/health)
    - Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs)

---

### 3. Configuração do Frontend (Flutter)

1.  **Instalar Dependências**:
    ```powershell
    cd frontend_flutter
    flutter pub get
    ```

2.  **Rodar o Aplicativo**:
    ```powershell
    flutter run
    ```
    *Nota: Certifique-se de ter um emulador aberto ou dispositivo conectado.*

---

## 🛠️ Comandos Úteis

### Backend & Database
- **Ver logs**: `docker compose -f docker/docker-compose.yml logs -f backend`
- **Rodar migrações manualmente**: `docker compose -f docker/docker-compose.yml exec backend alembic upgrade head`
- **Reiniciar tudo**: `docker compose -f docker/docker-compose.yml restart`

### Frontend
- **Gerar arquivos (Isar/Build Runner)**: `flutter pub run build_runner build --delete-conflicting-outputs`

---

## 📄 Especificações & Documentação
- **Status & Roadmap (Leitura Obrigatória):** [docs/STATUS_E_ROADMAP.md](./docs/STATUS_E_ROADMAP.md)
- **Especificações de Negócio:** [specs/spec.md](./specs/spec.md)
- **Arquitetura Frontend:** [frontarquiteture.md](./frontarquiteture.md)