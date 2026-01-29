#!/bin/bash
set -euo pipefail

echo "=== Starting Clawdbot Gateway ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# Paths so config location is stable
export HOME="/app"
export XDG_CONFIG_HOME="/app/.config"

# Env
export NODE_ENV=production
export TERM=dumb
export NODE_OPTIONS="--max-old-space-size=256"
export UV_THREADPOOL_SIZE=2

# Clipboard patch
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
fi

# Write config to default clawdbot location
CFG_DIR="/app/.config/clawdbot"
CFG_FILE="$CFG_DIR/config.json"
mkdir -p "$CFG_DIR"

cat > "$CFG_FILE" <<EOF
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

echo "Config OK: $CFG_FILE"

# ✅ IMPORTANT: run the bin, not a guessed dist path
exec ./node_modules/.bin/clawdbot gateway run --allow-unconfigured
