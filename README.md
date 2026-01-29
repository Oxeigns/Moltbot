# Moltbot on Heroku (Telegram Worker)

This is a Heroku worker wrapper for the Moltbot (formerly Clawdbot) gateway using Telegram long polling. It runs as a worker dyno and is configured for safe defaults in DMs and groups.

## Deploy

1. Fork or clone this repository.
2. Create a Heroku app.
3. Set the required Config Vars (below).
4. Deploy with the Heroku Node.js buildpack and scale the worker dyno.

## Required Config Vars

- `TELEGRAM_BOT_TOKEN`
- `OPENAI_API_KEY`

## Optional Config Vars

- `MODEL` (default: `gpt-4o-mini`)
- `LOG_LEVEL` (default: `info`)
- `GROUP_REQUIRE_MENTION` (default: `true`)
- `MOLT_CONFIG_PATH` (default: `/tmp/moltbot.json`)
- `ALLOWED_USER_IDS` (comma-separated Telegram user IDs)
- `ALLOWED_GROUP_IDS` (comma-separated Telegram group chat IDs)
- `WORKSPACE_PATH` (default: `/tmp/moltbot-workspace`)
- `DISABLE_DANGEROUS_TOOLS` (default: `true`)

## DM Pairing (Secure-by-Default)

DMs use `dmPolicy = pairing` by default. When a user DMs the bot, they receive a pairing code that must be approved:

```bash
moltbot pairing list telegram
moltbot pairing approve telegram <CODE>
```

Pairing codes expire (see official docs for details).

## Group Behavior (Mention-Gated)

By default, `GROUP_REQUIRE_MENTION=true` so the bot only responds in groups when mentioned (or when replying to its message if supported by Moltbot’s Telegram schema). This helps prevent spam in busy groups.

**Telegram privacy mode:** In group chats, you may need to disable privacy mode in BotFather or ensure the bot can see messages, or it will miss non-command messages.

## Security Notes

- Dangerous tools and skills are disabled by default.
- The workspace path is under `/tmp` to match Heroku’s ephemeral filesystem.
- Treat prompts as untrusted input; prompt injection is possible. Review any tool-enabling changes carefully.

## Troubleshooting

- Check logs with `heroku logs --tail`.
- Ensure Node.js >= 22 (as specified in `package.json`).
- If the bot doesn’t respond in groups, check Telegram privacy mode and confirm the bot has access to messages.
