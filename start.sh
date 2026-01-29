#!/bin/bash
set -euo pipefail

echo "=== Starting Clawdbot Gateway ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# ---------- Required paths (FIXES Missing config) ----------
export HOME="/app"
export XDG_CONFIG_HOME="/app/.config"

# ---------- Env ----------
export NODE_ENV=production
export TERM=dumb
export NODE_OPTIONS="--max-old-space-size=256"
export UV_THREADPOOL_SIZE=2

# ---------- Clipboard native crash patch ----------
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard patched"
fi

# ---------- Create OFFICIAL config path ----------
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

echo "Config ready"

# ---------- Auto fix doctor warning ----------
node_modules/.bin/clawdbot doctor --fix || true

# ---------- Start gateway ----------
exec node_modules/.bin/clawdbot gateway run
