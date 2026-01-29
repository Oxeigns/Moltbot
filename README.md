# Moltbot on Heroku (Worker Only)

This repository runs the Clawdbot (Moltbot) gateway on a Heroku worker dyno using Node 24 and pnpm, installing dependencies at build time.

## Requirements

- Node.js 24 (enforced via `engines`)
- Worker dyno only (no web dyno)
- Buildpacks: `heroku-community/apt` (for `git`), `heroku/nodejs`

## Deploy

1. Create a Heroku app and set the config vars:
   - `TELEGRAM_BOT_TOKEN`
   - `OPENAI_API_KEY`
   - Optional: `MODEL`
2. Ensure buildpacks are set in this order:

```bash
heroku buildpacks:set heroku-community/apt
heroku buildpacks:add --index 2 heroku/nodejs
```

3. Deploy this repo to Heroku.
4. Scale dynos:

```bash
heroku ps:scale web=0 worker=1
```

## Environment Variables

- `TELEGRAM_BOT_TOKEN` (required): Telegram bot token from BotFather.
- `OPENAI_API_KEY` (required): OpenAI API key.
- `MODEL` (optional): OpenAI model name (defaults to `gpt-4o-mini`).

## Notes

- Build-time install: `pnpm add clawdbot@latest` runs during `heroku-postbuild`.
- Runtime: `start.sh` writes `/tmp/moltbot.json` and starts the gateway with the local binary using that config.
- Telegram uses long polling in this gateway configuration.
- Workspace is `/tmp` to keep runtime storage memory-light on Heroku.
