# beevelop/claude

Docker image for [Claude Code](https://code.claude.com/) with remote control support. Designed for 24/7 headless operation on a remote server, accessible via the Claude mobile/web app.

Based on `node:22-bookworm-slim` with Claude Code CLI pre-installed.

## Quick Start

```bash
docker run -d \
  --name claude \
  --restart unless-stopped \
  -e ANTHROPIC_API_KEY=sk-ant-api03-xxxx \
  -e DEPLOY_KEY_B64="$(base64 < deploy_key | tr -d '\n')" \
  -e GIT_REPO=git@github.com:your-org/your-repo.git \
  -e GIT_USER_NAME="Claude Code" \
  -e GIT_USER_EMAIL="claude@example.com" \
  -v claude_home:/opt/claude \
  -v claude_workspace:/workspace \
  --tty --interactive \
  beevelop/claude:latest
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes* | Anthropic API key for authentication |
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes* | OAuth token for Claude Pro/Max subscription (alternative to API key) |
| `DEPLOY_KEY_B64` | No | Base64-encoded SSH private key for git authentication |
| `GIT_REPO` | No | SSH clone URL (e.g., `git@github.com:org/repo.git`) |
| `GIT_BRANCH` | No | Branch to clone (defaults to repo default) |
| `GIT_USER_NAME` | No | Git commit author name |
| `GIT_USER_EMAIL` | No | Git commit author email |
| `CLAUDE_PERMISSION_MODE` | No | Permission mode for `remote-control`: `default`, `acceptEdits` (default), `bypassPermissions`, `dontAsk`, `plan` |
| `INIT_COMMAND` | No | One-time setup command (runs once, tracked via stamp file) |
| `CLAUDE_EXTRA_ARGS` | No | Extra flags passed to `claude remote-control` |

\* One of `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` is required.

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

## Authentication

**API Key (recommended for automation):**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**OAuth Token (uses Claude Pro/Max subscription):**
```bash
# Generate once on a trusted machine:
claude setup-token
# Then use the resulting token:
CLAUDE_CODE_OAUTH_TOKEN=clt-oauth-xxxxxxxxxxxxxxxxxxxxxxxxx
```

## Volumes

| Path | Purpose |
|------|---------|
| `/opt/claude` | Claude config, credentials, and history |
| `/workspace` | Project files (auto-cloned from `GIT_REPO`) |

## BeeCompose Deployment

See the [BeeCompose claude-code service](https://github.com/beevelop/beecompose/tree/main/services/claude-code) for a production-ready Docker Compose setup with health checks, logging, and secrets management.

## Versioning

This image uses [CalVer](https://calver.org/) (`YYYY.MM.MICRO`).

## License

Copyright (c) 2025-2026 [Maik Hummel](https://www.beevelop.com). Licensed under the [MIT License](LICENSE).
