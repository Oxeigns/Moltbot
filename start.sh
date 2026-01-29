#!/usr/bin/env bash
export CLI_DISABLE_UI=1
export NO_CLIPBOARD=1
export TERM=dumb
export NODE_ENV=production

set -euo pipefail

export CLIPBOARD_DISABLE=1
export DISABLE_UI=1

export NODE_OPTIONS="--max-old-space-size=256"

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

MODEL="${MODEL:-gpt-4o-mini}"

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
  "logLevel": "info",
  "agent": {
    "workspace": "/tmp"
  }
}
JSON

echo "Starting Moltbot Telegram Gateway (long polling)"
echo "Workspace: /tmp"
echo "Config: /tmp/moltbot.json"

./node_modules/.bin/clawdbot gateway run \
  --config /tmp/moltbot.json \
  --allow-unconfigured \
  --no-ui \
  --log-level info \
  --headless
