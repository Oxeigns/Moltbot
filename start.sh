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

# ---- Start Gateway (no unsupported flags) ----
./node_modules/.bin/clawdbot gateway run
