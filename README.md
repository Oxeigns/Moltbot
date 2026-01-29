# Moltbot on Heroku (Worker Only)

This repository runs the official Moltbot CLI via `pnpm dlx` on a Heroku worker dyno using Node 24.

## Requirements

- Node.js 24 (enforced via `engines`)
- Worker dyno only (no web dyno)

## Deploy

1. Create a Heroku app and set the config vars:
   - `TELEGRAM_BOT_TOKEN`
   - `OPENAI_API_KEY`
   - Optional: `MODEL`, `GROUP_REQUIRE_MENTION`, `LOG_LEVEL`
2. Deploy this repo to Heroku.
3. Scale dynos:

```bash
heroku ps:scale web=0 worker=1
```

## Environment Variables

- `TELEGRAM_BOT_TOKEN` (required): Telegram bot token from BotFather.
- `OPENAI_API_KEY` (required): OpenAI API key.
- `MODEL` (optional): OpenAI model name (defaults to `gpt-4o-mini`).
- `GROUP_REQUIRE_MENTION` (optional): Set `true` to require @mention in groups.
- `LOG_LEVEL` (optional): Logging level for Moltbot (`info`, `debug`, `warn`, `error`).

## Notes

- `start.sh` enables Corepack, validates required variables, writes `/tmp/moltbot.json`, and runs:
  `pnpm dlx moltbot gateway --config /tmp/moltbot.json --verbose`.
- Moltbot uses Telegram long polling mode by default in this gateway.
