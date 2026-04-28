# Guia Passo a Passo: Rodando o Backend FastAPI Localmente

Este guia explica como executar o backend do **Cadife Smart Travel** (FastAPI) diretamente na sua máquina usando um ambiente virtual Python (sem colocar o código dentro do Docker). Isso é ótimo para desenvolvimento rápido e debug.

## 1. Pré-requisitos

- **Python 3.10+** instalado.
- **PostgreSQL** rodando (pode ser via Docker ou local).
- Terminal (Linux/macOS) ou PowerShell (Windows).

## 2. Preparando o Ambiente Virtual (venv)

É uma boa prática isolar as dependências do projeto. No seu terminal, navegue até a pasta `backend`:

```bash
cd backend
```

Crie o ambiente virtual:
```bash
python3 -m venv venv
```

Ative o ambiente virtual:
- No **macOS / Linux**:
  ```bash
  source venv/bin/activate
  ```
- No **Windows**:
  ```bash
  .\venv\Scripts\activate
  ```

> Você saberá que deu certo porque o prompt do terminal ficará com o prefixo `(venv)`.

## 3. Instalando as Dependências

Com o `venv` ativado, instale as bibliotecas necessárias:

```bash
pip install --upgrade pip
pip install -r requirements.txt

# Instale o alembic para gerenciar as migrations do banco de dados (caso não esteja no requirements.txt)
pip install alembic
```

## 4. Configuração do Banco de Dados Local

Você precisa de um banco de dados PostgreSQL rodando. Você pode usar o container do banco de dados definido no projeto para facilitar:

```bash
# Volte para a raiz do projeto e suba apenas o banco de dados
cd ..
docker compose -f docker/docker-compose.yml up db -d
cd backend
```

## 5. Configuração das Variáveis de Ambiente (`.env`)

Crie o arquivo `.env` a partir do modelo:
```bash
cp .env.example .env
```

Abra o arquivo `.env` e ajuste as configurações. **Atenção especial para o `DATABASE_URL`**:
Como você vai rodar o FastAPI localmente (fora do Docker) e o banco está no Docker (exposto na porta 5432), a conexão deve ser feita via `localhost`:

```env
# Mude isso:
# DATABASE_URL=postgresql+asyncpg://cadife:cadife@db:5432/cadife_db

# Para isso:
DATABASE_URL=postgresql+asyncpg://cadife:cadife@localhost:5432/cadife_db
```

Preencha também outras variáveis (como as chaves da OpenAI, JWT_SECRET_KEY, etc.).

## 6. Rodando as Migrations (Alembic)

Para criar as tabelas no banco de dados, rode as migrations:

```bash
alembic upgrade head
```

## 7. Executando o Servidor FastAPI

Agora você pode iniciar a aplicação! Como o projeto utiliza `uvicorn` e a instância da aplicação está no arquivo `main.py` com o nome `app`, execute:

```bash
uvicorn main:app --reload
```

> A flag `--reload` faz o servidor reiniciar automaticamente toda vez que você salvar uma alteração no código.

## 8. Testando a Aplicação

Se tudo estiver correto, você verá no terminal uma mensagem indicando que a aplicação está rodando em `http://127.0.0.1:8000`.

- **Acesse o Health Check:** [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)
- **Documentação da API (Swagger UI):** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Documentação da API (ReDoc):** [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

## 9. Comandos Úteis e Debug

- **Parar o servidor:** Pressione `Ctrl + C` no terminal.
- **Sair do ambiente virtual:** Digite `deactivate` no terminal.
- **Expor com ngrok (Para Webhooks do WhatsApp):**
  Em um novo terminal, rode:
  ```bash
  ngrok http 8000
  ```
