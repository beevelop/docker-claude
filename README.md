# beevelop/claude

Docker image for [Claude Code](https://code.claude.com/) with remote control support. Designed for 24/7 headless operation on a remote server, accessible via the Claude mobile/web app.

Based on `ubuntu:24.04` with a full developer toolchain (Node.js 22, Python 3, build-essential, ripgrep, fzf, etc.) and Claude Code CLI pre-installed via the official installer.

## Quick Start

```bash
docker run -d \
  --name claude \
  --restart unless-stopped \
  -e DEPLOY_KEY_B64="$(base64 < deploy_key | tr -d '\n')" \
  -e GIT_REPO=git@github.com:your-org/your-repo.git \
  -e GIT_USER_NAME="Claude Code" \
  -e GIT_USER_EMAIL="claude@example.com" \
  -v claude_config:/home/developer/.claude \
  -v claude_workspace:/workspace \
  --tty --interactive \
  beevelop/claude:latest
```

## First Launch — Interactive Login

Remote control mode requires an OAuth login (API keys are **not** supported). On first launch, you must attach to the container and complete the login flow:

1. **Start the container** (see Quick Start above).

2. **Attach to the running container:**
   ```bash
   docker attach claude
   ```

3. **Complete the OAuth login** — the entrypoint will automatically run `claude login`. Follow the URL printed in the terminal to authenticate in your browser.

4. **After login succeeds**, press `Ctrl+C` to continue. The entrypoint will then launch `claude remote-control`.

5. **Detach from the container** with `Ctrl+P` then `Ctrl+Q` (Docker's detach sequence). The container continues running in the background.

Subsequent container restarts will use the persisted credentials and skip the login step entirely.

## Credential Storage & Persistence

Claude Code stores its credentials in these locations inside the container:

| Path | Purpose |
|------|---------|
| `/home/developer/.claude/.credentials.json` | OAuth tokens (access + refresh) |
| `/home/developer/.claude.json` | Account metadata and onboarding state |
| `/home/developer/.claude/` | Full config directory (credentials, settings, history) |

To persist credentials across container restarts, mount a volume at `/home/developer/.claude`:

```yaml
volumes:
  - claude_config:/home/developer/.claude
```

The image pre-seeds `/home/developer/.claude.json` with onboarding state so Claude Code does not prompt for initial setup.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEPLOY_KEY_B64` | No | Base64-encoded SSH private key for git authentication |
| `GIT_REPO` | No | SSH clone URL (e.g., `git@github.com:org/repo.git`) |
| `GIT_BRANCH` | No | Branch to clone (defaults to repo default) |
| `GIT_USER_NAME` | No | Git commit author name |
| `GIT_USER_EMAIL` | No | Git commit author email |
| `CLAUDE_PERMISSION_MODE` | No | Permission mode for `remote-control`: `default`, `acceptEdits` (default), `bypassPermissions`, `dontAsk`, `plan` |
| `CLAUDE_SESSION_NAME` | No | Custom session title visible in claude.ai/code (e.g., `"My Project"`) |
| `INIT_COMMAND` | No | One-time setup command (runs once on first launch, tracked via stamp file) |
| `CLAUDE_EXTRA_ARGS` | No | Extra flags passed to `claude remote-control` |

## Git Authentication

The image supports SSH deploy keys for git clone/push. GitHub host keys are baked into the image at build time, so there is no interactive prompt.

1. Generate a deploy key:
   ```bash
   ssh-keygen -t ed25519 -f deploy_key -N ""
   ```

2. Add `deploy_key.pub` as a deploy key to your GitHub repo (with write access).

3. Base64-encode the private key and pass it via the `DEPLOY_KEY_B64` environment variable:
   ```bash
   base64 < deploy_key | tr -d '\n'
   ```

On first start, if `GIT_REPO` is set and `/workspace` is empty, the entrypoint clones the repository automatically.

## Volumes

| Path | Purpose |
|------|---------|
| `/home/developer/.claude` | Claude credentials, config, and history (persists login across restarts) |
| `/workspace` | Project files (auto-cloned from `GIT_REPO`) |

## BeeCompose Deployment

See the [BeeCompose claude-code service](https://github.com/beevelop/beecompose/tree/main/services/claude-code) for a production-ready Docker Compose setup with health checks, logging, and secrets management.

## Versioning

This image uses [CalVer](https://calver.org/) (`YYYY.MM.MICRO`).

## License

Copyright (c) 2025-2026 [Maik Hummel](https://www.beevelop.com). Licensed under the [MIT License](LICENSE).
