#!/bin/bash
set -euo pipefail

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# clipboard crash patch
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
fi

export NODE_ENV=production
export TERM=dumb

CFG="/tmp/moltbot.json"
cat > "$CFG" <<EOF
{
  "gateway": { "mode": "local" },
  "providers": { "openai": { "apiKey": "${OPENAI_API_KEY}", "model": "${MODEL}" } },
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

export MOLT_CONFIG_PATH="$CFG"
export MOLTBOT_CONFIG="$CFG"
export CLAWDBOT_CONFIG="$CFG"

APP_ROOT="$(pwd)"
cd /tmp
"$APP_ROOT/node_modules/.bin/clawdbot" gateway run
