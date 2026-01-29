#!/bin/bash
set -euo pipefail

echo "=== Starting Moltbot / Clawdbot Gateway ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

export NODE_ENV=production
export TERM=dumb

# ---- Memory protection ----
export NODE_OPTIONS="--max-old-space-size=256"
export UV_THREADPOOL_SIZE=2

# ---- Disable clipboard native crash ----
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

# ---- REAL CONFIG PATH (Clawdbot default) ----
CFG_DIR="/app/.config/clawdbot"
CFG_FILE="$CFG_DIR/config.json"

mkdir -p "$CFG_DIR"

cat > "$CFG_FILE" <<EOF
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

echo "Config written to: $CFG_FILE"

# ---- START GATEWAY (NO FLAGS) ----
exec node_modules/.bin/clawdbot gateway run
