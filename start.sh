#!/bin/bash
set -euo pipefail

echo "=== Starting Moltbot/Clawdbot Gateway ==="

# REQUIRED ENV
: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

export NODE_ENV=production
export TERM=dumb

# PATCH: disable clipboard native crash on Heroku
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

# IMPORTANT: write config to the path clawdbot expects
CFG="/tmp/moltbot.json"
cat > "$CFG" <<EOF
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
echo "Config written: $CFG"

# Force config path (different versions read different env names)
export MOLT_CONFIG_PATH="$CFG"
export MOLTBOT_CONFIG="$CFG"
export CLAWDBOT_CONFIG="$CFG"

APP_ROOT="$(pwd)"
BIN="$APP_ROOT/node_modules/.bin/clawdbot"

cd /tmp

# Try doctor auto-fix (ignore if unsupported)
"$BIN" doctor --fix >/dev/null 2>&1 || true

# Start gateway (no --config, no unsupported flags)
"$BIN" gateway run
