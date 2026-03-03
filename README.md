# beevelop/claude

Docker image for [Claude Code](https://code.claude.com/) with remote control support. Designed for 24/7 headless operation on a remote server, accessible via the Claude mobile/web app.

Based on `node:22-bookworm-slim` with Claude Code CLI pre-installed.

## Quick Start

```bash
docker run -d \
  --name claude \
  --restart unless-stopped \
  -e ANTHROPIC_API_KEY=sk-ant-api03-xxxx \
  -v claude_home:/opt/claude \
  -v /srv/projects:/workspace \
  --tty --interactive \
  beevelop/claude:latest
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes* | Anthropic API key for authentication |
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes* | OAuth token for Claude Pro/Max subscription (alternative to API key) |
| `INIT_COMMAND` | No | One-time setup command (runs once, tracked via stamp file) |
| `CLAUDE_EXTRA_ARGS` | No | Extra flags passed to `claude remote-control` |

\* One of `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` is required.

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
| `/workspace` | Project files (mount your repos here) |

## BeeCompose Deployment

See the [BeeCompose claude-code service](https://github.com/beevelop/beecompose/tree/main/services/claude-code) for a production-ready Docker Compose setup with health checks and logging.

## Versioning

This image uses [CalVer](https://calver.org/) (`YYYY.MM.MICRO`).

## License

Copyright (c) 2025-2026 [Maik Hummel](https://www.beevelop.com). Licensed under the [MIT License](LICENSE).
