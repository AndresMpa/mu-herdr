# MμHerdr Notify

Herdr plugin: desktop banner (ram icon) when an agent is **blocked** or **done**. Optional Slack and Telegram.

## Install

The marketplace indexes public GitHub repos with topic `herdr-plugin` and a `herdr-plugin.toml` on the default branch. This plugin lives in `plugin/`:

```
herdr plugin install AndresMpa/mu-herdr/plugin
herdr plugin list
```

Local clone of MμHerdr:

```
herdr plugin link ~/.config/herdr/plugin --enabled
```

## Config

User config is `notify.toml` under `herdr plugin config-dir muherdr.notify` (not in the plugin source). Copy `notify.example`:

```
system = true
slack = false
telegram = false
slack_webhook_url =
telegram_bot_token =
telegram_chat_id =
```

Env: `SLACK_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.

## Test

```
HERDR_PLUGIN_EVENT_JSON='{"data":{"agent_status":"blocked","display_agent":"grok","workspace_id":"w1"}}' \
  bash notify.sh
```

Mac: `terminal-notifier`; allow **MμHerdr** in Notification Center. Linux: `notify-send` / `libnotify`.
