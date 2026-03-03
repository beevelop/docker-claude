#!/usr/bin/env bash
set -euo pipefail

echo "[claude-entrypoint] Starting Claude Code container..."

# Run one-time init if requested and not yet done
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
