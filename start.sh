#!/usr/bin/env bash
set -euo pipefail

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

moltbot --version
moltbot gateway --config /tmp/moltbot.json --verbose
