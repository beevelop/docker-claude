FROM node:25-bookworm-slim

ENV CLAUDE_CODE_VERSION=2.1.63

# Basic OS tooling for Claude Code operations
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git curl ca-certificates bash openssh-client ripgrep jq procps sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node && \
    chmod 0440 /etc/sudoers.d/node

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    npm cache clean --force 2>/dev/null && \
    claude --version

# Pre-populate SSH known_hosts with GitHub host keys (avoids interactive prompt)
RUN mkdir -p /home/node/.ssh && \
    ssh-keyscan -t ed25519,rsa github.com >> /home/node/.ssh/known_hosts 2>/dev/null && \
    chown -R node:node /home/node/.ssh && \
    chmod 700 /home/node/.ssh && \
    chmod 644 /home/node/.ssh/known_hosts

# Prepare Claude config directory and onboarding marker
RUN mkdir -p /home/node/.claude && \
    echo '{"hasCompletedOnboarding":true,"installMethod":"native"}' > /home/node/.claude.json && \
    chown -R node:node /home/node/.claude /home/node/.claude.json

# Workspace where projects will be mounted
RUN mkdir -p /workspace && chown node:node /workspace
WORKDIR /workspace

# Run as non-root for safety
USER node

COPY --chown=node:node entrypoint.sh /home/node/bin/entrypoint.sh
RUN chmod +x /home/node/bin/entrypoint.sh

ENTRYPOINT ["/home/node/bin/entrypoint.sh"]
