#!/usr/bin/env bash
set -euo pipefail

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

MODEL="${MODEL:-gpt-4o-mini}"
GROUP_REQUIRE_MENTION="${GROUP_REQUIRE_MENTION:-true}"
LOG_LEVEL="${LOG_LEVEL:-info}"

cat <<JSON > /tmp/moltbot.json
{
  "providers": {
    "openai": {
      "apiKey": "${OPENAI_API_KEY}",
      "model": "${MODEL}"
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "requireMention": ${GROUP_REQUIRE_MENTION}
    }
  },
  "logLevel": "${LOG_LEVEL}",
  "agent": {
    "workspace": "/tmp/moltbot-workspace"
  }
}
JSON

mkdir -p /tmp/moltbot-workspace

if command -v moltbot >/dev/null 2>&1; then
  MOLT_CMD=(moltbot)
elif [[ -x "./node_modules/.bin/moltbot" ]]; then
  MOLT_CMD=(./node_modules/.bin/moltbot)
elif [[ -f "./node_modules/moltbot/moltbot.mjs" ]]; then
  MOLT_CMD=(node ./node_modules/moltbot/moltbot.mjs)
else
  echo "moltbot executable not found. Ensure dependencies are installed." >&2
  exit 1
fi

"${MOLT_CMD[@]}" --version
"${MOLT_CMD[@]}" gateway --config /tmp/moltbot.json --verbose
