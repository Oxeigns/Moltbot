#!/bin/bash
set -e

echo "Starting Moltbot Gateway..."

# Required env
: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
: "${MODEL:=gpt-4o-mini}"

# Disable clipboard native crash (Heroku)
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

export NODE_ENV=production
export TERM=dumb

# Write FINAL config with real values (no ${...} placeholders)
CONFIG_PATH="/tmp/clawdbot.json"
cat > "$CONFIG_PATH" <<EOF
{
  "gateway": { "mode": "local" },
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
      "groups": { "requireMention": true }
    }
  },
  "logLevel": "info",
  "agent": { "workspace": "/tmp" }
}
EOF

export CLAWDBOT_CONFIG="$CONFIG_PATH"

# Start gateway (NO FLAGS — your version rejects --config/--no-ui etc.)
APP_ROOT="$(pwd)"
cd /tmp
"$APP_ROOT/node_modules/.bin/clawdbot" gateway run
