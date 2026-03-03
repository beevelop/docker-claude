FROM node:22-bookworm-slim

ENV CLAUDE_CODE_VERSION=2.1.63

# Basic OS tooling for Claude Code operations
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git curl ca-certificates bash openssh-client ripgrep jq procps && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    npm cache clean --force 2>/dev/null && \
    claude --version

# Where Claude will keep its config/credentials/history
ENV CLAUDE_HOME=/opt/claude
RUN mkdir -p "${CLAUDE_HOME}" && chown -R node:node "${CLAUDE_HOME}"

# Pre-populate SSH known_hosts with GitHub host keys (avoids interactive prompt)
RUN mkdir -p /home/node/.ssh && \
    ssh-keyscan -t ed25519,rsa github.com >> /home/node/.ssh/known_hosts 2>/dev/null && \
    chown -R node:node /home/node/.ssh && \
    chmod 700 /home/node/.ssh && \
    chmod 644 /home/node/.ssh/known_hosts

# Workspace where projects will be mounted
RUN mkdir -p /workspace && chown node:node /workspace
WORKDIR /workspace

# Run as non-root for safety
USER node

COPY --chown=node:node entrypoint.sh /home/node/bin/entrypoint.sh
RUN chmod +x /home/node/bin/entrypoint.sh

ENTRYPOINT ["/home/node/bin/entrypoint.sh"]
