FROM ghcr.io/foundry-rs/foundry:latest AS foundry

FROM debian:bookworm-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    nodejs \
    npm \
    zsh \
    && curl --proto '=https' --tlsv1.2 -LsSf https://github.com/astral-sh/uv/releases/download/0.6.10/uv-installer.sh | sh \
    && apt-get purge -y --auto-remove curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:$PATH"
    
RUN npm install --global yarn
RUN uv tool install slither-analyzer

RUN groupadd -g 10001 vscode && useradd -u 10000 -g 10001 --no-log-init -r vscode
RUN mkdir -p /home/vscode && chown -R vscode:vscode /home/vscode

WORKDIR /workspace
USER vscode

COPY --from=foundry /usr/local/bin/forge /usr/local/bin/forge
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast
COPY --from=foundry /usr/local/bin/anvil /usr/local/bin/anvil
COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel

SHELL ["/usr/bin/zsh"]

CMD ["zsh"]