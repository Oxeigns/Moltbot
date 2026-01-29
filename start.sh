#!/bin/bash
set -euo pipefail

echo "=== Starting Clawdbot Gateway (Heroku) ==="

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${OPENAI_API_KEY:?Missing OPENAI_API_KEY}"
MODEL="${MODEL:-gpt-4o-mini}"

# ---- Heroku: make HOME writable so ~/.clawdbot exists ----
export HOME="/tmp"
export XDG_CONFIG_HOME="/tmp/.config"
export XDG_STATE_HOME="/tmp/.local/state"
mkdir -p "$HOME/.clawdbot" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"

# ---- Reduce memory (R14/R15) ----
export NODE_ENV=production
export TERM=dumb
export NODE_OPTIONS="--max-old-space-size=256"
export UV_THREADPOOL_SIZE=2

# ---- Clipboard native crash patch ----
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"
if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
fi

# ---- Write config into REAL expected places ----
CFG1="$HOME/.clawdbot/config.json"
CFG2="$HOME/.clawdbot/moltbot.json"
CFG3="/tmp/moltbot.json"

cat > "$CFG1" <<EOF
{
  "gateway": { "mode": "local" },
  "providers": {
    "openai": { "apiKey": "${OPENAI_API_KEY}", "model": "${MODEL}" }
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

cp "$CFG1" "$CFG2"
cp "$CFG1" "$CFG3"

echo "Config written:"
ls -la "$HOME/.clawdbot" || true

# ---- Start gateway (use allow-unconfigured to bypass setup wizard) ----
exec ./node_modules/.bin/clawdbot gateway run --allow-unconfigured
