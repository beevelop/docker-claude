#!/usr/bin/env bash
set -euo pipefail

echo "[claude-entrypoint] Starting Claude Code container..."

# --- SSH deploy key setup ---
if [[ -n "${DEPLOY_KEY_B64:-}" ]]; then
  echo "[claude-entrypoint] Configuring SSH deploy key..."
  echo "${DEPLOY_KEY_B64}" | base64 -d > /home/node/.ssh/id_ed25519
  chmod 600 /home/node/.ssh/id_ed25519
  echo "[claude-entrypoint] SSH deploy key configured."
else
  echo "[claude-entrypoint] No deploy key found; skipping SSH setup."
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
INIT_MARKER="/home/node/.claude/.init_done"
if [[ -n "${INIT_COMMAND:-}" ]]; then
  if [[ ! -f "${INIT_MARKER}" ]]; then
    echo "[claude-entrypoint] Running INIT_COMMAND..."
    bash -lc "${INIT_COMMAND}"
    mkdir -p /home/node/.claude
    touch "${INIT_MARKER}"
    echo "[claude-entrypoint] INIT_COMMAND complete."
  else
    echo "[claude-entrypoint] INIT_COMMAND already completed; skipping."
  fi
fi

echo "[claude-entrypoint] Claude Code version: $(claude --version)"

# --- Authentication check ---
CRED_FILE="/home/node/.claude/.credentials.json"

if [[ -f "${CRED_FILE}" ]] && [[ -s "${CRED_FILE}" ]]; then
  echo "[claude-entrypoint] Existing credentials found; skipping login."
else
  echo ""
  echo "=============================================="
  echo "  FIRST LAUNCH — Interactive login required"
  echo "=============================================="
  echo ""
  echo "  Claude Code remote-control requires an OAuth login."
  echo "  Please complete the login flow below."
  echo ""
  echo "  After login succeeds, press Ctrl+C to continue"
  echo "  and launch remote-control mode."
  echo ""
  echo "=============================================="
  echo ""

  # Run login interactively; user completes OAuth in browser
  claude login || true

  if [[ -f "${CRED_FILE}" ]] && [[ -s "${CRED_FILE}" ]]; then
    echo "[claude-entrypoint] Login successful. Credentials saved."
  else
    echo "[claude-entrypoint] WARNING: Login may not have completed. Attempting to launch anyway..."
  fi
fi

# --- Build launch command ---
LAUNCH_ARGS=("claude" "remote-control")

# Permission mode (default: acceptEdits)
MODE="${CLAUDE_PERMISSION_MODE:-acceptEdits}"
LAUNCH_ARGS+=("--permission-mode" "${MODE}")

# Append any extra user-provided flags
if [[ -n "${CLAUDE_EXTRA_ARGS:-}" ]]; then
  # Word-split CLAUDE_EXTRA_ARGS intentionally
  read -ra EXTRA <<< "${CLAUDE_EXTRA_ARGS}"
  LAUNCH_ARGS+=("${EXTRA[@]}")
fi

echo "[claude-entrypoint] Launching: ${LAUNCH_ARGS[*]}"

# Remote Control requires a TTY; docker-compose sets tty: true and stdin_open: true
exec "${LAUNCH_ARGS[@]}"
