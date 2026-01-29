#!/bin/bash
set -euo pipefail

echo "=== Moltbot/Clawdbot starting ==="

# -------------------------
# REQUIRED ENV VARS
# -------------------------
: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

export NODE_ENV=production
export TERM=dumb

# -------------------------
# PATCH CLIPBOARD (HEROKU)
# -------------------------
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

# -------------------------
# WRITE CONFIG (NO ${...} PLACEHOLDERS)
# -------------------------
CFG="/tmp/clawdbot.json"
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

# -------------------------
# RUN (NO --config FLAG)
# -------------------------
APP_ROOT="$(pwd)"
cd /tmp

BIN="$APP_ROOT/node_modules/.bin/clawdbot"
if [ ! -x "$BIN" ]; then
  echo "ERROR: clawdbot binary not found at $BIN"
  exit 1
fi

echo "Starting gateway..."
if CLAWDBOT_CONFIG="$CFG" "$BIN" gateway run --allow-unconfigured 2>&1 | tee /tmp/clawdbot.log; then
  exit 0
else
  echo "Flag --allow-unconfigured not supported or failed, retrying without it..."
  CLAWDBOT_CONFIG="$CFG" "$BIN" gateway run
fi
