#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "node_modules/moltbot" ]; then
  echo "Error: node_modules/moltbot is missing. Run npm install first." >&2
  exit 1
fi

if [ -f "node_modules/moltbot/dist/entry.js" ]; then
  exit 0
fi

echo "Moltbot dist missing; building from source..."

if command -v corepack >/dev/null 2>&1; then
  corepack enable >/dev/null 2>&1 || true
  corepack prepare pnpm@10.23.0 --activate >/dev/null 2>&1 || true
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "Error: pnpm is required to build Moltbot but was not found." >&2
  exit 1
fi

NODE_ENV=development pnpm --dir node_modules/moltbot install --frozen-lockfile
pnpm --dir node_modules/moltbot build
