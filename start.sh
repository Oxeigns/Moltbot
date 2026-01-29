#!/usr/bin/env bash
set -euo pipefail

corepack enable

node -v
pnpm -v

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

MODEL="${MODEL:-gpt-4o-mini}"
LOG_LEVEL="${LOG_LEVEL:-info}"

mkdir -p /tmp/moltbot-workspace

cat <<JSON > /tmp/moltbot.json
{
  "providers": {
    "openai": {
      "apiKey": "${OPENAI_API_KEY}",
      "model": "${MODEL}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "groups": {
        "requireMention": true
      }
    }
  },
  "logLevel": "${LOG_LEVEL}",
  "agent": {
    "workspace": "/tmp/moltbot-workspace"
  }
}
JSON

echo "Starting Moltbot Telegram Gateway (long polling)"
echo "Workspace: /tmp/moltbot-workspace"
echo "Config: /tmp/moltbot.json"

pnpm dlx clawdbot@latest gateway run \
  --config /tmp/moltbot.json \
  --allow-unconfigured \
  --verbose
