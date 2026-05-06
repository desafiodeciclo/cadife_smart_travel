# ---------------------------------------------------------
# Estágio 1: Builder (Ambiente de Compilação)
# ---------------------------------------------------------
FROM python:3.11-slim AS builder

# Impede que o Python gere arquivos .pyc e permite logs em tempo real
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /build

# Instala dependências de compilação necessárias para pacotes como psycopg2 ou dependências C
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria um Virtual Environment para isolar as dependências
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------
# Estágio 2: Runtime (Ambiente de Execução Seguro)
# ---------------------------------------------------------
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copia apenas o Virtual Environment do estágio anterior
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instala apenas as bibliotecas compartilhadas essenciais (libpq para o Postgres)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Configuração de Usuário Rootless (Segurança K8s)
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/sh -m appuser

# Copia o código fonte e ajusta permissões
COPY . .
RUN chmod +x entrypoint.sh && chown -R appuser:appgroup /app

# Switch para o usuário não-privilegiado
USER appuser

EXPOSE 8000

CMD ["./entrypoint.sh"]
