#!/usr/bin/env bash
# Send MμHerdr alerts on agent blocked/done. Optional Slack and Telegram.
set -u

CONF="${HERDR_CONFIG_PATH:-${HOME:-}/.config/herdr/config.toml}"
CONF_DIR=$(dirname "$CONF")
NOTIFY_TOML="$CONF_DIR/notify.toml"
HERDR_BIN=${HERDR_BIN_PATH:-herdr}

system=1
slack=0
telegram=0
slack_webhook_url=
telegram_bot_token=
telegram_chat_id=

load_notify() {
  [ -f "$NOTIFY_TOML" ] || return 0
  while IFS='=' read -r k v || [ -n "${k:-}" ]; do
    k=$(printf '%s' "$k" | tr -d '[:space:]')
    v=$(printf '%s' "$v" | tr -d '[:space:]' | tr -d '"')
    [ -z "$k" ] && continue
    case $k in
      \#*) continue ;;
      system) case $v in 1|true|on|yes) system=1 ;; *) system=0 ;; esac ;;
      slack) case $v in 1|true|on|yes) slack=1 ;; *) slack=0 ;; esac ;;
      telegram) case $v in 1|true|on|yes) telegram=1 ;; *) telegram=0 ;; esac ;;
      slack_webhook_url) slack_webhook_url=$v ;;
      telegram_bot_token) telegram_bot_token=$v ;;
      telegram_chat_id) telegram_chat_id=$v ;;
    esac
  done <"$NOTIFY_TOML"
}

[ -n "${SLACK_WEBHOOK_URL:-}" ] && slack_webhook_url=$SLACK_WEBHOOK_URL
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && telegram_bot_token=$TELEGRAM_BOT_TOKEN
[ -n "${TELEGRAM_CHAT_ID:-}" ] && telegram_chat_id=$TELEGRAM_CHAT_ID

load_notify
[ -n "${SLACK_WEBHOOK_URL:-}" ] && slack_webhook_url=$SLACK_WEBHOOK_URL
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && telegram_bot_token=$TELEGRAM_BOT_TOKEN
[ -n "${TELEGRAM_CHAT_ID:-}" ] && telegram_chat_id=$TELEGRAM_CHAT_ID

[ -n "$slack_webhook_url" ] && slack=1
[ -n "$telegram_bot_token" ] && [ -n "$telegram_chat_id" ] && telegram=1

if [ "${system:-0}" != 1 ] && [ "${slack:-0}" != 1 ] && [ "${telegram:-0}" != 1 ]; then
  exit 0
fi

json=${HERDR_PLUGIN_EVENT_JSON:-}
if [ -z "$json" ]; then
  exit 0
fi

eval "$(printf '%s' "$json" | python3 -c '
import json, os, sys, subprocess

raw = sys.stdin.read()
try:
    ev = json.loads(raw)
except Exception:
    sys.exit(0)
data = ev.get("data") or ev
status = (data.get("agent_status") or "").lower()
if status not in ("blocked", "done"):
    sys.exit(0)
agent = data.get("display_agent") or data.get("agent") or "agent"
ws_id = data.get("workspace_id") or ""
label = ws_id or "workspace"
bin = os.environ.get("HERDR_BIN_PATH", "herdr")
try:
    out = subprocess.check_output([bin, "workspace", "list"], text=True)
    tabs = json.loads(out).get("result", {}).get("workspaces") or []
    for w in tabs:
        if w.get("workspace_id") == ws_id:
            label = w.get("label") or label
            break
except Exception:
    pass
if status == "blocked":
    msg = "Workspace %s (%s) Need your attention" % (label, agent)
    sound = "request"
else:
    msg = "Workspace %s (%s) finished" % (label, agent)
    sound = "done"
def sh(s):
    return "'" + str(s).replace("'", "'\"'\"'") + "'"
print("status=%s" % sh(status))
print("msg=%s" % sh(msg))
print("sound=%s" % sh(sound))
')" || exit 0

[ -n "${msg:-}" ] || exit 0

send_system() {
  if command -v "$HERDR_BIN" >/dev/null 2>&1; then
    "$HERDR_BIN" notification show "MμHerdr" --body "$msg" --position top-right --sound "$sound" >/dev/null 2>&1 || true
  fi
  case "$(uname -s)" in
    Darwin)
      if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "MμHerdr" -message "$msg" >/dev/null 2>&1 || true
      else
        osascript -e "display notification \"$(printf '%s' "$msg" | sed 's/"/\\"/g')\" with title \"MμHerdr\"" >/dev/null 2>&1 || true
      fi
      ;;
    Linux)
      if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "MμHerdr" "MμHerdr" "$msg" >/dev/null 2>&1 || true
      elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session \
          --dest org.freedesktop.Notifications \
          --object-path /org/freedesktop/Notifications \
          --method org.freedesktop.Notifications.Notify \
          "MμHerdr" 0 "" "MμHerdr" "$msg" "[]" "{}" 8000 >/dev/null 2>&1 || true
      fi
      ;;
  esac
}

send_slack() {
  [ -n "$slack_webhook_url" ] || return 0
  python3 -c '
import json, os, sys, urllib.request
url = os.environ["SLACK_URL"]
msg = os.environ["MSG"]
req = urllib.request.Request(
    url,
    data=json.dumps({"text": "MμHerdr: " + msg}).encode(),
    headers={"Content-Type": "application/json"},
    method="POST",
)
urllib.request.urlopen(req, timeout=8).read()
' 2>/dev/null || true
}

send_telegram() {
  [ -n "$telegram_bot_token" ] && [ -n "$telegram_chat_id" ] || return 0
  python3 -c '
import json, os, urllib.request
token = os.environ["TG_TOKEN"]
chat = os.environ["TG_CHAT"]
msg = os.environ["MSG"]
url = "https://api.telegram.org/bot%s/sendMessage" % token
req = urllib.request.Request(
    url,
    data=json.dumps({"chat_id": chat, "text": msg}).encode(),
    headers={"Content-Type": "application/json"},
    method="POST",
)
urllib.request.urlopen(req, timeout=8).read()
' 2>/dev/null || true
}

export MSG="$msg"
if [ "$system" = 1 ]; then
  send_system
fi
if [ "$slack" = 1 ]; then
  SLACK_URL=$slack_webhook_url send_slack
fi
if [ "$telegram" = 1 ]; then
  TG_TOKEN=$telegram_bot_token TG_CHAT=$telegram_chat_id send_telegram
fi
