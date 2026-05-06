# ---------------------------------------------------------
# Estágio 1: Builder (Ambiente de Compilação)
# ---------------------------------------------------------
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /build

# Instala dependências de compilação
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria usuário aqui (pois builder tem shell e comandos de sistema)
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/sh -m appuser

# Instala dependências diretamente no site-packages do sistema do builder
# para facilitar a cópia para o distroless depois
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------------------------------------------------------
# Estágio 2: Runtime (Ambiente Distroless - Hardened)
# ---------------------------------------------------------
FROM gcr.io/distroless/python3-debian12 AS runtime

WORKDIR /app

# Copia as bibliotecas instaladas do builder
COPY --from=builder /install /usr/local
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# Copia as definições de usuário (necessário pois distroless não tem groupadd/useradd)
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copia bibliotecas nativas essenciais (libpq para o Postgres)
# Nota: Distroless debian12 já costuma vir com libs básicas, mas garantimos o necessário
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpq.so.5 /usr/lib/x86_64-linux-gnu/libpq.so.5
COPY --from=builder /usr/lib/x86_64-linux-gnu/libldap_r-2.5.so.0 /usr/lib/x86_64-linux-gnu/libldap_r-2.5.so.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/liblber-2.5.so.0 /usr/lib/x86_64-linux-gnu/liblber-2.5.so.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.2
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgnutls.so.30 /usr/lib/x86_64-linux-gnu/libgnutls.so.30

# Copia o código fonte
COPY . .

# Switch para o usuário não-privilegiado
USER appuser

EXPOSE 8000

# No Distroless, chamamos o bootstrap.py que gerencia as migrações e o uvicorn
ENTRYPOINT ["/usr/bin/python3", "bootstrap.py"]
