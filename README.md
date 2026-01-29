# Moltbot on Heroku (Worker Only)

This repository provides a Heroku worker wrapper that builds Moltbot from Git source with pnpm and runs the Telegram gateway via the built `dist` output.

## Requirements

- Node.js >= 22
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

## Notes

- The build step installs pnpm, clones the official Moltbot repo, and runs `pnpm build`.
- `start.sh` generates `/tmp/moltbot.json` and launches the gateway from the compiled `dist` entry.
- Group replies are mention-gated by default via `GROUP_REQUIRE_MENTION=true`.
