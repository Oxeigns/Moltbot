#!/usr/bin/env bash
set -euo pipefail

corepack enable

node -v
pnpm -v

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

MODEL="${MODEL:-gpt-4o-mini}"
GROUP_REQUIRE_MENTION="${GROUP_REQUIRE_MENTION:-true}"
LOG_LEVEL="${LOG_LEVEL:-info}"

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
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "requireMention": ${GROUP_REQUIRE_MENTION}
    }
  },
  "logLevel": "${LOG_LEVEL}",
  "agent": {
    "workspace": "/tmp/moltbot-workspace"
  }
}
JSON

mkdir -p /tmp/moltbot-workspace

echo "Starting Moltbot Telegram Gateway (long polling)"
echo "Workspace: /tmp/moltbot-workspace"
echo "Config: /tmp/moltbot.json"

pnpm dlx moltbot gateway --config /tmp/moltbot.json --verbose
