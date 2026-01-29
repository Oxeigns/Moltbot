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

resolve_molt_cmd() {
  if command -v moltbot >/dev/null 2>&1; then
    MOLT_CMD=(moltbot)
    return 0
  fi

  if [[ -x "./node_modules/.bin/moltbot" ]]; then
    MOLT_CMD=(./node_modules/.bin/moltbot)
    return 0
  fi

  if [[ -f "./node_modules/moltbot/moltbot.mjs" ]]; then
    MOLT_CMD=(node ./node_modules/moltbot/moltbot.mjs)
    return 0
  fi

  return 1
}

if ! resolve_molt_cmd; then
  echo "moltbot executable not found. Installing dependencies..." >&2
  npm install --omit=dev
  resolve_molt_cmd || {
    echo "moltbot executable still missing after install." >&2
    exit 1
  }
fi

"${MOLT_CMD[@]}" --version
"${MOLT_CMD[@]}" gateway --config /tmp/moltbot.json --verbose
