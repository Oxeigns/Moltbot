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

PYTHON_CMD=""
NODE_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
elif command -v node >/dev/null 2>&1; then
  NODE_CMD="node"
else
  echo "Error: python3 or node is required but was not found in PATH." >&2
  exit 127
fi

if [ -n "$PYTHON_CMD" ]; then
  $PYTHON_CMD - <<'PY'
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
else
  $NODE_CMD - <<'JS'
const fs = require("fs");

const parseBool = (value) => String(value).trim().toLowerCase().match(/^(1|true|yes|on)$/) !== null;

const parseIdList = (raw) => {
  const ids = [];
  for (const part of String(raw).split(",")) {
    const trimmed = part.trim();
    if (!trimmed) {
      continue;
    }
    if (!/^[-]?\d+$/.test(trimmed)) {
      throw new Error(`Invalid numeric ID: ${trimmed}`);
    }
    ids.push(Number.parseInt(trimmed, 10));
  }
  return ids;
};

const config = {
  agent: {
    workspace: process.env.WORKSPACE_PATH,
    disableDangerousTools: parseBool(process.env.DISABLE_DANGEROUS_TOOLS),
  },
  providers: {
    openai: {
      apiKey: process.env.OPENAI_API_KEY,
      model: process.env.MODEL,
    },
  },
  channels: {
    telegram: {
      botToken: process.env.TELEGRAM_BOT_TOKEN,
      dmPolicy: "pairing",
      requireMention: parseBool(process.env.GROUP_REQUIRE_MENTION),
    },
  },
};

if (process.env.ALLOWED_USER_IDS) {
  config.channels.telegram.allowedUserIds = parseIdList(process.env.ALLOWED_USER_IDS);
}

if (process.env.ALLOWED_GROUP_IDS) {
  config.channels.telegram.allowedGroupIds = parseIdList(process.env.ALLOWED_GROUP_IDS);
}

fs.writeFileSync(process.env.MOLT_CONFIG_PATH, `${JSON.stringify(config, null, 2)}\n`, "utf8");
JS
fi

echo "Starting Moltbot Gateway (Telegram long polling)..."
echo "Config: $MOLT_CONFIG_PATH"
echo "Workspace: $WORKSPACE_PATH"
echo "Log level: $LOG_LEVEL"

export LOG_LEVEL
exec pnpm moltbot gateway start --config "$MOLT_CONFIG_PATH"
