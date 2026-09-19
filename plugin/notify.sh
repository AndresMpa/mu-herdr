#!/usr/bin/env bash
# Send MμHerdr alerts on agent blocked/done. Optional Slack and Telegram.
set -u

CONF="${HERDR_CONFIG_PATH:-${HOME:-}/.config/herdr/config.toml}"
CONF_DIR=$(dirname "$CONF")
NOTIFY_TOML="$CONF_DIR/notify.toml"
HERDR_BIN=${HERDR_BIN_PATH:-herdr}
HERE=$(cd "$(dirname "$0")" && pwd)
ICON="$HERE/herdr.png"
[ -f "$ICON" ] || ICON="$HERE/herdr.svg"

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

eval "$(
  HERDR_PLUGIN_EVENT_JSON="$json" python3 <<'PY'
import json, os, subprocess, sys

raw = os.environ.get("HERDR_PLUGIN_EVENT_JSON") or ""
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
    workspaces = json.loads(out).get("result", {}).get("workspaces") or []
    for w in workspaces:
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
print("status=%s" % json.dumps(status))
print("msg=%s" % json.dumps(msg))
print("sound=%s" % json.dumps(sound))
PY
)" || exit 0

[ -n "${msg:-}" ] || exit 0

png_to_icns() {
  local png=$1 dest=$2 set
  command -v sips >/dev/null 2>&1 || return 1
  command -v iconutil >/dev/null 2>&1 || return 1
  [ -f "$png" ] || return 1
  set="$HERE/.icon.iconset"
  rm -rf "$set"
  mkdir -p "$set"
  sips -z 16 16 "$png" --out "$set/icon_16x16.png" >/dev/null
  sips -z 32 32 "$png" --out "$set/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$png" --out "$set/icon_32x32.png" >/dev/null
  sips -z 64 64 "$png" --out "$set/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$png" --out "$set/icon_128x128.png" >/dev/null
  sips -z 256 256 "$png" --out "$set/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$png" --out "$set/icon_256x256.png" >/dev/null
  sips -z 512 512 "$png" --out "$set/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$png" --out "$set/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$png" --out "$set/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$set" -o "$dest" >/dev/null
  rm -rf "$set"
  [ -f "$dest" ]
}

# Notification Center shows the icon of the app that posted the banner.
# Copy Homebrew's terminal-notifier.app, swap in the ram, ad-hoc sign it.
ensure_darwin_notifier() {
  APP="$HERE/MuHerdr.app"
  BIN="$APP/Contents/MacOS/terminal-notifier"
  STAMP="$APP/.ram-icon"
  if [ -x "$BIN" ] && [ -f "$STAMP" ]; then
    return 0
  fi
  command -v terminal-notifier >/dev/null 2>&1 || return 1
  [ -f "$ICON" ] || return 1
  src=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$(command -v terminal-notifier)")
  src_app=${src%/Contents/MacOS/*}
  [ -d "$src_app/Contents/MacOS" ] || return 1
  rm -rf "$APP"
  cp -R "$src_app" "$APP"
  icns="$HERE/.herdr.icns"
  png_to_icns "$ICON" "$icns" || return 1
  find "$APP/Contents/Resources" -name '*.icns' -exec cp "$icns" {} \;
  cp "$icns" "$APP/Contents/Resources/AppIcon.icns"
  rm -f "$icns"
  if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.andresmpa.muherdr.notify' "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c 'Set :CFBundleName MμHerdr' "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName MμHerdr' "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
  fi
  codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
  LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  [ -x "$LSREG" ] && "$LSREG" -f "$APP" >/dev/null 2>&1 || true
  date > "$STAMP"
  [ -x "$BIN" ]
}

send_system() {
  local sent=0
  case "$(uname -s)" in
    Darwin)
      if ensure_darwin_notifier; then
        snd=default
        [ "$sound" = done ] && snd=Glass
        if "$HERE/MuHerdr.app/Contents/MacOS/terminal-notifier" \
          -title "MμHerdr" -message "$msg" -sound "$snd" \
          -appIcon "$ICON" -contentImage "$ICON" >/dev/null 2>&1; then
          sent=1
        fi
      elif command -v terminal-notifier >/dev/null 2>&1 && [ -f "$ICON" ]; then
        terminal-notifier -title "MμHerdr" -message "$msg" \
          -appIcon "$ICON" -contentImage "$ICON" >/dev/null 2>&1 && sent=1
      fi
      if [ "$sent" != 1 ]; then
        osascript -e "display notification \"$(printf '%s' "$msg" | sed 's/"/\\"/g')\" with title \"MμHerdr\"" >/dev/null 2>&1 || true
        sent=1
      fi
      ;;
    Linux)
      if command -v notify-send >/dev/null 2>&1; then
        if [ -f "$ICON" ]; then
          notify-send -a "MμHerdr" -i "$ICON" "MμHerdr" "$msg" >/dev/null 2>&1 && sent=1
        else
          notify-send -a "MμHerdr" "MμHerdr" "$msg" >/dev/null 2>&1 && sent=1
        fi
      fi
      if [ "$sent" != 1 ] && command -v gdbus >/dev/null 2>&1; then
        gdbus call --session \
          --dest org.freedesktop.Notifications \
          --object-path /org/freedesktop/Notifications \
          --method org.freedesktop.Notifications.Notify \
          "MμHerdr" 0 "${ICON:-}" "MμHerdr" "$msg" "[]" "{}" 8000 >/dev/null 2>&1 && sent=1
      fi
      ;;
  esac
  # Herdr's own banner cannot take a custom icon; only use it if native send failed.
  if [ "$sent" != 1 ] && command -v "$HERDR_BIN" >/dev/null 2>&1; then
    "$HERDR_BIN" notification show "MμHerdr" --body "$msg" --position top-right --sound "$sound" >/dev/null 2>&1 || true
  fi
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
    data=json.dumps({"chat_id": chat, "text": "MμHerdr: " + msg}).encode(),
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
