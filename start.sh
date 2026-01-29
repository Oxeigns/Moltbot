#!/usr/bin/env bash
set -euo pipefail

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

export MODEL="${MODEL:-gpt-4o-mini}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
export GROUP_REQUIRE_MENTION="${GROUP_REQUIRE_MENTION:-true}"
export MOLT_CONFIG_PATH="${MOLT_CONFIG_PATH:-/tmp/moltbot.json}"
export WORKSPACE_PATH="${WORKSPACE_PATH:-/tmp/moltbot-workspace}"
export DISABLE_DANGEROUS_TOOLS="${DISABLE_DANGEROUS_TOOLS:-true}"
export ALLOWED_USER_IDS="${ALLOWED_USER_IDS:-}"
export ALLOWED_GROUP_IDS="${ALLOWED_GROUP_IDS:-}"

mkdir -p "$WORKSPACE_PATH"
mkdir -p "$(dirname "$MOLT_CONFIG_PATH")"

python - <<'PY'
import json
import os
import sys

def parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}

def parse_id_list(raw: str):
    ids = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if not part.lstrip("-").isdigit():
            raise ValueError(f"Invalid numeric ID: {part}")
        ids.append(int(part))
    return ids

config = {
    "agent": {
        "workspace": os.environ["WORKSPACE_PATH"],
        "disableDangerousTools": parse_bool(os.environ["DISABLE_DANGEROUS_TOOLS"]),
    },
    "providers": {
        "openai": {
            "apiKey": os.environ["OPENAI_API_KEY"],
            "model": os.environ["MODEL"],
        }
    },
    "channels": {
        "telegram": {
            "botToken": os.environ["TELEGRAM_BOT_TOKEN"],
            "dmPolicy": "pairing",
            "requireMention": parse_bool(os.environ["GROUP_REQUIRE_MENTION"]),
        }
    },
}

if os.environ.get("ALLOWED_USER_IDS"):
    try:
        config["channels"]["telegram"]["allowedUserIds"] = parse_id_list(os.environ["ALLOWED_USER_IDS"])
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)

if os.environ.get("ALLOWED_GROUP_IDS"):
    try:
        config["channels"]["telegram"]["allowedGroupIds"] = parse_id_list(os.environ["ALLOWED_GROUP_IDS"])
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)

with open(os.environ["MOLT_CONFIG_PATH"], "w", encoding="utf-8") as handle:
    json.dump(config, handle, indent=2)
    handle.write("\n")
PY

echo "Starting Moltbot Gateway (Telegram long polling)..."
echo "Config: $MOLT_CONFIG_PATH"
echo "Workspace: $WORKSPACE_PATH"
echo "Log level: $LOG_LEVEL"

CLI=""
if [ -x "node_modules/.bin/moltbot" ]; then
  CLI="node_modules/.bin/moltbot"
elif [ -x "node_modules/.bin/clawdbot" ]; then
  CLI="node_modules/.bin/clawdbot"
else
  CLI="npx moltbot"
fi

export LOG_LEVEL
exec $CLI gateway --config "$MOLT_CONFIG_PATH"
