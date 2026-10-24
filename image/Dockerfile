# Build tools
FROM ghcr.io/astral-sh/uv:0.13.1@sha256:4a1f3666816dafadd20ceb71eac9a7d56d7ef30279f7d64048519ab901ada336 AS uv

FROM python:3.13-slim-trixie@sha256:70729b46c69b4f1e97c4822c1af3df53a1476cf5ddc6c087c0c10bc3a5678c2f

# Metadata
LABEL org.opencontainers.image.source="https://github.com/LeonardoSextare/WinPlaybook" \
      org.opencontainers.image.description="Ansible tools for WinPlaybook" \
      org.opencontainers.image.licenses="MIT"

# System packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends git less nano openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Python packages
COPY pyproject.toml uv.lock /opt/winplaybook/
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    uv sync \
        --project /opt/winplaybook \
        --locked \
        --no-python-downloads \
        --compile-bytecode \
        --no-cache
ENV PATH=/opt/winplaybook/.venv/bin:$PATH

# Runtime
ENV EDITOR=nano

CMD ["ansible", "--version"]
