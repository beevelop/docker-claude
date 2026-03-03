#!/usr/bin/env bash
set -euo pipefail

echo "[claude-entrypoint] Starting Claude Code container..."

# --- SSH deploy key setup ---
SSH_KEY="/run/secrets/deploy_key"
if [[ -f "${SSH_KEY}" ]]; then
  echo "[claude-entrypoint] Configuring SSH deploy key..."
  cp "${SSH_KEY}" /home/node/.ssh/id_ed25519
  chmod 600 /home/node/.ssh/id_ed25519
  echo "[claude-entrypoint] SSH deploy key configured."
else
  echo "[claude-entrypoint] No deploy key found at ${SSH_KEY}; skipping SSH setup."
fi

# --- Git user config ---
if [[ -n "${GIT_USER_NAME:-}" ]]; then
  git config --global user.name "${GIT_USER_NAME}"
  echo "[claude-entrypoint] Git user.name set to '${GIT_USER_NAME}'"
fi
if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
  git config --global user.email "${GIT_USER_EMAIL}"
  echo "[claude-entrypoint] Git user.email set to '${GIT_USER_EMAIL}'"
fi

# --- Auto-clone repository ---
if [[ -n "${GIT_REPO:-}" ]]; then
  BRANCH="${GIT_BRANCH:-}"
  if [[ -z "$(ls -A /workspace 2>/dev/null)" ]]; then
    echo "[claude-entrypoint] Cloning ${GIT_REPO}..."
    CLONE_ARGS=("--single-branch")
    if [[ -n "${BRANCH}" ]]; then
      CLONE_ARGS+=("--branch" "${BRANCH}")
    fi
    git clone "${CLONE_ARGS[@]}" "${GIT_REPO}" /workspace
    echo "[claude-entrypoint] Repository cloned."
  else
    echo "[claude-entrypoint] /workspace is not empty; skipping clone."
  fi
fi

# --- One-time init command ---
if [[ -n "${INIT_COMMAND:-}" ]]; then
  if [[ ! -f "${CLAUDE_HOME}/.init_done" ]]; then
    echo "[claude-entrypoint] Running INIT_COMMAND..."
    bash -lc "${INIT_COMMAND}"
    touch "${CLAUDE_HOME}/.init_done"
    echo "[claude-entrypoint] INIT_COMMAND complete."
  else
    echo "[claude-entrypoint] INIT_COMMAND already completed; skipping."
  fi
fi

echo "[claude-entrypoint] Claude Code version: $(claude --version)"
echo "[claude-entrypoint] Launching: claude remote-control ${CLAUDE_EXTRA_ARGS:-}"

# Remote Control requires a TTY; docker-compose sets tty: true and stdin_open: true
exec bash -lc "claude remote-control ${CLAUDE_EXTRA_ARGS:-}"
