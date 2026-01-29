#!/bin/bash
set -e

echo "=== Starting Clawdbot Gateway (FINAL FIX) ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"

MODEL="${MODEL:-gpt-4o-mini}"

# ---- Patch clipboard native crash ----
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard patched"
fi

export NODE_ENV=production
export TERM=dumb
export NODE_OPTIONS="--max-old-space-size=256"

# ---- Create OFFICIAL clawdbot config path ----
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

echo "Config written to $CFG_FILE"

# ---- Start gateway WITHOUT doctor check ----
exec node node_modules/clawdbot/dist/cli.js gateway run --allow-unconfigured
