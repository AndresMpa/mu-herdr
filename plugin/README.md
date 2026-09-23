# MμHerdr Notify

Herdr plugin that alerts you when an agent **needs attention** or **finishes**.

| Event | When |
| --- | --- |
| **blocked** | Agent is waiting on you (approval, question, etc.) |
| **done** | Agent finished a turn |

Does **not** fire on `working` or `idle`.

## What you get

### 1. System desktop notifications (default on)

- **macOS:** branded **MμHerdr** banner via `terminal-notifier` / bundled `MuHerdr.app` (ram icon), with sound (`request` / `Glass` for done). Falls back to `osascript` if needed.
- **Linux:** `notify-send` (or `gdbus`) with the Herdr ram icon (`muherdr.png`).

### 2. Slack (optional)

Posts `MμHerdr: …` to an **Incoming Webhook** when blocked/done.

### 3. Telegram (optional)

Sends `MμHerdr: …` via Bot API (`sendMessage`) when blocked/done.

Outbound only — there is no Telegram → agent reply path in this plugin.

### Message content

- Workspace **label** (resolved from `workspace_id` when possible)
- **Agent** name (`display_agent` / `agent`)
- Wording:
  - blocked → `Workspace {label} ({agent}) Need your attention`
  - done → `Workspace {label} ({agent}) finished`

## Install

Marketplace indexes public GitHub repos with topic `herdr-plugin` and a `herdr-plugin.toml` on the default branch. This plugin lives in `plugin/`:

```bash
herdr plugin install AndresMpa/mu-herdr/plugin
herdr plugin list
```

Local MμHerdr tree:

```bash
herdr plugin link ~/.config/herdr/plugin --enabled
```

If `herdr plugin list` is empty, notifications will not run until the plugin is linked again.

## Config

User config is **not** in the plugin source. Use:

- `~/.config/herdr/notify.toml` (gitignored), or
- `$(herdr plugin config-dir muherdr.notify)/notify.toml`

Copy from `notify.example`:

```toml
system = true
slack = false
telegram = false

# Slack app → Incoming Webhooks
slack_webhook_url =

# @BotFather token + chat/group id
telegram_bot_token =
telegram_chat_id =
```

| Key | Effect |
| --- | --- |
| `system = true` | Desktop OS banner (ram icon) |
| `slack = true` + `slack_webhook_url` | Slack webhook post |
| `telegram = true` + token + chat id | Telegram message |

Environment overrides (also force-enable that channel when set):

- `SLACK_WEBHOOK_URL`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

### Recommended Herdr toast setting

In `config.toml`:

```toml
[ui.toast]
delivery = "herdr"   # in-app toast only
delay_seconds = 1
```

Use **`herdr`**, not **`system`**, so you do not get a second generic OS banner without the ram. This plugin owns the desktop notification.

## Platforms

- `macos`
- `linux`

## Test

```bash
HERDR_PLUGIN_EVENT_JSON='{"data":{"agent_status":"blocked","display_agent":"grok","workspace_id":"w1"}}' \
  HERDR_PLUGIN_ROOT="$PWD" \
  bash notify.sh
```

Try `agent_status` = `done` as well.

**macOS:** System Settings → Notifications → allow **MμHerdr**.  
**Linux:** `libnotify` / `notify-send` installed.

## Branding helpers

```bash
bash notify.sh --brand-only
```

Prepares the Mac notifier app / Linux desktop icon without sending an alert.

## Manifest

See `herdr-plugin.toml` (`id = muherdr.notify`, event `pane.agent_status_changed` → `notify.sh`).
