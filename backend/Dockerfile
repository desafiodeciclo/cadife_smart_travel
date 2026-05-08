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

# Cria usuário aqui
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/sh -m appuser

# Instala dependências
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------------------------------------------------------
# Estágio 2: Runtime (Ambiente Distroless - Hardened)
# ---------------------------------------------------------
FROM gcr.io/distroless/python3-debian12 AS runtime

WORKDIR /app

# Configura a localidade para suportar UTF-8 (corrige UnicodeDecodeError)
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONIOENCODING=utf-8
ENV PYTHONUTF8=1

# Copia as bibliotecas instaladas do builder
COPY --from=builder /install /usr/local
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# Copia as definições de usuário
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copia TODAS as bibliotecas necessárias para o PostgreSQL de uma vez
# Isso é mais seguro do que tentar adivinhar nomes de arquivos individuais
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpq.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libldap_r* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/liblber* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libsasl2.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgnutls.so* /usr/lib/x86_64-linux-gnu/

# Copia o código fonte
COPY . .

USER appuser

EXPOSE 8000

ENTRYPOINT ["/usr/bin/python3", "bootstrap.py"]
