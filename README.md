# Moltbot on Heroku (Worker Only)

This repository runs the official Clawdbot (Moltbot) CLI via `pnpm dlx` on a Heroku worker dyno using Node 24.

## Requirements

- Node.js 24 (enforced via `engines`)
- Worker dyno only (no web dyno)

## Deploy

1. Create a Heroku app and set the config vars:
   - `TELEGRAM_BOT_TOKEN`
   - `OPENAI_API_KEY`
   - Optional: `MODEL`, `LOG_LEVEL`
2. Deploy this repo to Heroku.
3. Scale dynos:

```bash
heroku ps:scale web=0 worker=1
```

## Environment Variables

- `TELEGRAM_BOT_TOKEN` (required): Telegram bot token from BotFather.
- `OPENAI_API_KEY` (required): OpenAI API key.
- `MODEL` (optional): OpenAI model name (defaults to `gpt-4o-mini`).
- `LOG_LEVEL` (optional): Logging level for the gateway (`info`, `debug`, `warn`, `error`).

## Notes

- `start.sh` enables Corepack, validates required variables, writes `/tmp/moltbot.json`, and runs:
  `pnpm dlx clawdbot@latest gateway run --config /tmp/moltbot.json --allow-unconfigured --verbose`.
- Clawdbot uses Telegram long polling mode by default in this gateway.
