export NODE_ENV=production
export TERM=dumb

./node_modules/.bin/clawdbot gateway run \
--config /tmp/moltbot.json \
--allow-unconfigured \
--no-ui \
--headless \
--log-level info
