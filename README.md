# Moltbot on Heroku (Worker Only)

This repository provides a minimal Heroku wrapper for Moltbot that installs the CLI globally during the build and starts the gateway via the CLI only.

## Requirements

- Node.js >= 22
- Heroku worker dyno only (no web dyno)

## Deploy

1. Create a Heroku app and set the config vars:
   - `TELEGRAM_BOT_TOKEN`
   - `OPENAI_API_KEY`
   - Optional: `MODEL`, `GROUP_REQUIRE_MENTION`, `LOG_LEVEL`
2. Deploy this repo.
3. Scale dynos:

```bash
heroku ps:scale web=0 worker=1
```

## Notes

- The build installs Moltbot globally with `npm i -g moltbot@latest`.
- Startup uses `moltbot gateway --config /tmp/moltbot.json --verbose`.
- The config is generated at runtime in `start.sh`.
