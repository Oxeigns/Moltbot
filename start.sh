#!/bin/bash
set -euo pipefail

echo "=== Starting Moltbot/Clawdbot Gateway ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# ---- Clipboard native crash patch (Heroku) ----
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

export NODE_ENV=production
export TERM=dumb

# ---- Memory limits (fix R14/R15) ----
export NODE_OPTIONS="--max-old-space-size=256"
export UV_THREADPOOL_SIZE=2

# ---- Generate runtime config (env injected) ----
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
echo "Config written: $CFG"

# ---- Force config path (different versions) ----
export MOLT_CONFIG_PATH="$CFG"
export MOLTBOT_CONFIG="$CFG"
export CLAWDBOT_CONFIG="$CFG"

# ---- Start ----
APP_ROOT="$(pwd)"
cd /tmp
exec "$APP_ROOT/node_modules/.bin/clawdbot" gateway run
