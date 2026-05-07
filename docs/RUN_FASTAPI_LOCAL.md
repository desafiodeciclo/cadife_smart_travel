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

### Opção A — venv dentro do projeto (padrão original)

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

### Opção B — venv global com Python 3.14 (recomendado para desenvolvimento local)

Crie o ambiente virtual em `~/python_envs/` (apenas na primeira vez):

```bash
python3.14 -m venv ~/python_envs/cadife_smart_travel
```

Ative o ambiente virtual:

- No **macOS / Linux**:
  ```bash
  source ~/python_envs/cadife_smart_travel/bin/activate
  ```
- No **Windows** (PowerShell):
  ```powershell
  ~\python_envs\cadife_smart_travel\Scripts\Activate.ps1
  ```

> O prompt do terminal ficará com o prefixo `(cadife_smart_travel)`.

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

Já está configurado.

## 6. Rodando as Migrations (Alembic)

Para criar as tabelas no banco de dados, rode as migrations, precisa rodar somente uma vez, depois de criado
o banco não precisa mais rodar as migrations:

```bash
alembic upgrade head
```

## 7. Executando o Servidor FastAPI

Agora você pode iniciar a aplicação! Como o projeto utiliza `uvicorn` e a instância da aplicação está no arquivo `main.py` com o nome `app`, execute:

```bash
python -m uvicorn main:app --reload
```

> **Importante (Opção B — pyenv + venv global):** Use sempre `python -m uvicorn` em vez de `uvicorn` diretamente. O pyenv instala shims que podem interceptar o comando `uvicorn` e apontar para a instalação global do pyenv (sem os pacotes do venv), causando `ModuleNotFoundError`. O `python -m uvicorn` garante que o Python do venv ativo seja usado.

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

### Conexão com o Banco de Dados

| Campo       | Valor                                            |
| :---------- | :----------------------------------------------- |
| **Host**    | `localhost`                                      |
| **Porta**   | `5433` _(mapeada para 5432 dentro do container)_ |
| **Usuário** | `cadife`                                         |
| **Senha**   | `cadife`                                         |
| **Banco**   | `cadife_db`                                      |

#### Opção 1 — Via terminal (psql dentro do container)

```bash
docker exec -it cadife_smart_travel-db-1 psql -U cadife -d cadife_db
```

> **Nota:** O nome do container pode variar. Para ver o nome exato, execute: `docker ps`

#### Opção 2 — Via psql local (se tiver instalado)

```bash
psql -h localhost -p 5433 -U cadife -d cadife_db
```

> Vai pedir a senha: `cadife`

#### Opção 3 — Via GUI (DBeaver, TablePlus, pgAdmin)

- **Host:** `localhost`
- **Port:** `5433`
- **Database:** `cadife_db`
- **User:** `cadife`
- **Password:** `cadife`
