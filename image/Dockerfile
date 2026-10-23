FROM python:3.13-slim-trixie

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
RUN --mount=from=ghcr.io/astral-sh/uv:0.13.1,source=/uv,target=/bin/uv \
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
