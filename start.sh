#!/bin/bash
set -e

echo "=== Starting Clawdbot Gateway (Heroku Fixed) ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# ---------- Heroku paths ----------
export HOME="/app"
export XDG_CONFIG_HOME="/app/.config"

# ---------- Memory protection ----------
export NODE_ENV=production
export TERM=dumb
export NODE_OPTIONS="--max-old-space-size=192"
export UV_THREADPOOL_SIZE=2

# ---------- Clipboard native crash patch ----------
CLIP="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP" ]; then
  echo "module.exports={writeSync(){},readSync(){return ''}}" > "$CLIP"
fi

# ---------- Create official config ----------
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

echo "Config OK"

# ---------- START WITHOUT DOCTOR ----------
exec node_modules/.bin/clawdbot gateway run --allow-unconfigured
