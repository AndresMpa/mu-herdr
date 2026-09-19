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

# macOS Notification Center uses the sending app's icon. -appIcon is ignored
# on recent macOS; a tiny .app with the ram as AppIcon.icns is what shows.
ensure_darwin_app() {
  APP="$HERE/MuHerdr.app"
  ICNS="$APP/Contents/Resources/AppIcon.icns"
  [ -f "$ICNS" ] && [ -f "$ICON" ] && return 0
  command -v sips >/dev/null 2>&1 || return 1
  command -v iconutil >/dev/null 2>&1 || return 1
  [ -f "$ICON" ] || return 1
  SET="$HERE/.icon.iconset"
  rm -rf "$SET" "$APP"
  mkdir -p "$SET" "$APP/Contents/MacOS" "$APP/Contents/Resources"
  sips -z 16 16 "$ICON" --out "$SET/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON" --out "$SET/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON" --out "$SET/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON" --out "$SET/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON" --out "$SET/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON" --out "$SET/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON" --out "$SET/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON" --out "$SET/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON" --out "$SET/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON" --out "$SET/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$SET" -o "$ICNS" >/dev/null
  rm -rf "$SET"
  printf '%s\n' '#!/bin/sh' 'exit 0' > "$APP/Contents/MacOS/MuHerdr"
  chmod +x "$APP/Contents/MacOS/MuHerdr"
  cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MuHerdr</string>
  <key>CFBundleIdentifier</key>
  <string>com.andresmpa.muherdr.notify</string>
  <key>CFBundleName</key>
  <string>MμHerdr</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
PLIST
  LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  if [ -x "$LSREG" ]; then
    "$LSREG" -f "$APP" >/dev/null 2>&1 || true
  fi
}

send_system() {
  local sent=0
  case "$(uname -s)" in
    Darwin)
      ensure_darwin_app || true
      if command -v terminal-notifier >/dev/null 2>&1; then
        set -- -title "MμHerdr" -message "$msg"
        [ "$sound" = done ] && set -- "$@" -sound Glass || set -- "$@" -sound default
        [ -f "$ICON" ] && set -- "$@" -appIcon "$ICON" -contentImage "$ICON"
        [ -d "$HERE/MuHerdr.app" ] && set -- "$@" -sender com.andresmpa.muherdr.notify
        if terminal-notifier "$@" >/dev/null 2>&1; then
          sent=1
        fi
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
