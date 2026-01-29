#!/bin/bash

CLIP_PATH="node_modules/@mariozechner/clipboard/index.js"

if [ -f "$CLIP_PATH" ]; then
  echo "module.exports = { writeSync(){}, readSync(){ return '' } }" > $CLIP_PATH
fi

export NODE_ENV=production
export TERM=dumb

./node_modules/.bin/clawdbot gateway run \
--config /tmp/moltbot.json \
--allow-unconfigured \
--no-ui \
--headless \
--log-level info
