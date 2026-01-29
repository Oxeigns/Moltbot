#!/bin/bash
set -e

echo "Starting Moltbot Gateway..."

# ---- Disable clipboard native crash ----
CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"

if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > "$CLIP_PATH"
  echo "Clipboard module patched"
fi

# ---- Environment ----
export NODE_ENV=production
export TERM=dumb

# ---- Config ----
CONFIG_SOURCE="moltbot.json"
if [ ! -f "$CONFIG_SOURCE" ]; then
  CONFIG_SOURCE="config.template.json"
fi

CONFIG_PATH="/tmp/clawdbot.json"
cp "$CONFIG_SOURCE" "$CONFIG_PATH"
export CLAWDBOT_CONFIG="$CONFIG_PATH"

# ---- Start Gateway ----
APP_ROOT="$(pwd)"
cd /tmp
"$APP_ROOT/node_modules/.bin/clawdbot" gateway run
