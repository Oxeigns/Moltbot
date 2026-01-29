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

DIST_DIR="./moltbot-src/dist"
if [[ ! -d "${DIST_DIR}" ]]; then
  echo "Moltbot dist directory is missing. Ensure heroku-postbuild ran successfully." >&2
  exit 1
fi

resolve_entry() {
  if [[ -f "${DIST_DIR}/entry.js" ]]; then
    echo "${DIST_DIR}/entry.js"
    return 0
  fi

  if [[ -f "${DIST_DIR}/index.js" ]]; then
    echo "${DIST_DIR}/index.js"
    return 0
  fi

  local pkg_json="./moltbot-src/package.json"
  if [[ ! -f "${pkg_json}" ]]; then
    return 1
  fi

  node -e '
    const fs = require("fs");
    const path = require("path");
    const pkgPath = process.argv[1];
    const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
    let target = "";
    if (typeof pkg.main === "string") {
      target = pkg.main;
    } else if (pkg.exports) {
      if (typeof pkg.exports === "string") {
        target = pkg.exports;
      } else if (pkg.exports["."] ) {
        const exp = pkg.exports["."];
        if (typeof exp === "string") {
          target = exp;
        } else if (exp.import) {
          target = exp.import;
        } else if (exp.default) {
          target = exp.default;
        } else if (exp.require) {
          target = exp.require;
        }
      }
    }
    if (!target) {
      process.exit(2);
    }
    console.log(path.resolve(path.dirname(pkgPath), target));
  ' "${pkg_json}"
}

ENTRY_FILE="$(resolve_entry || true)"
if [[ -z "${ENTRY_FILE}" || ! -f "${ENTRY_FILE}" ]]; then
  echo "Unable to locate Moltbot entry file in dist output." >&2
  exit 1
fi

echo "Starting Moltbot Telegram Gateway (long polling)"
echo "Workspace: /tmp/moltbot-workspace"
echo "Config: /tmp/moltbot.json"
echo "Entry: ${ENTRY_FILE}"

node "${ENTRY_FILE}" gateway --config /tmp/moltbot.json --verbose
