FROM ubuntu:24.04

ARG CLAUDE_CODE_VERSION=latest

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Developer tooling
RUN apt-get update && apt-get install -y \
      build-essential \
      git curl wget ca-certificates \
      openssh-client \
      bash zsh \
      ripgrep jq fzf tree htop less \
      procps sudo \
      unzip xz-utils \
      python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create non-root developer user
RUN useradd -m -s /bin/bash -G sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Pre-populate SSH known_hosts with GitHub host keys (avoids interactive prompt)
RUN mkdir -p /home/developer/.ssh && \
    ssh-keyscan -t ed25519,rsa github.com >> /home/developer/.ssh/known_hosts 2>/dev/null && \
    chown -R developer:developer /home/developer/.ssh && \
    chmod 700 /home/developer/.ssh && \
    chmod 644 /home/developer/.ssh/known_hosts

# Prepare Claude config directory and onboarding marker
RUN mkdir -p /home/developer/.claude && \
    echo '{"hasCompletedOnboarding":true,"installMethod":"native"}' > /home/developer/.claude.json && \
    chown -R developer:developer /home/developer/.claude /home/developer/.claude.json

# Install Claude Code CLI using the official installer
USER developer
RUN curl -fsSL https://claude.ai/install.sh | bash -s -- "${CLAUDE_CODE_VERSION}" && \
    /home/developer/.local/bin/claude --version
USER root

# Ensure claude is on PATH for the developer user
ENV PATH="/home/developer/.local/bin:${PATH}"

# Workspace where projects will be mounted
RUN mkdir -p /workspace && chown developer:developer /workspace
WORKDIR /workspace

# Run as non-root for safety
USER developer

COPY --chown=developer:developer entrypoint.sh /home/developer/bin/entrypoint.sh
RUN chmod +x /home/developer/bin/entrypoint.sh

ENTRYPOINT ["/home/developer/bin/entrypoint.sh"]
