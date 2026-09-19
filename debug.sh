#!/usr/bin/env bash
# Print what Herdr is actually using. Run this inside a Herdr pane.
set -u

HOME_DIR=${HOME:-}
CONF="${HERDR_CONFIG_PATH:-$HOME_DIR/.config/herdr/config.toml}"
DIR=$(dirname "$CONF")
CHORD="$DIR/bin/chord"

echo "== herdr =="
if command -v herdr >/dev/null 2>&1; then
  herdr -V
  herdr status
else
  echo "herdr is not on PATH"
fi

echo
echo "== config =="
echo "HERDR_ENV=${HERDR_ENV:-}"
echo "HERDR_CONFIG_PATH=${HERDR_CONFIG_PATH:-}"
echo "file: $CONF"
if [ -f "$CONF" ]; then
  echo "prefix line:"
  grep -E '^prefix = ' "$CONF" || echo "(none — Herdr default is ctrl+b)"
  echo "chord commands:"
  grep -E 'bin/chord|keys.command' "$CONF" || echo "(no chord commands)"
else
  echo "missing — Herdr is not using MμHerdr"
fi

echo
echo "== chord =="
if [ -x "$CHORD" ]; then
  echo "ok $CHORD"
elif [ -f "$CHORD" ]; then
  echo "not executable: $CHORD"
else
  echo "missing: $CHORD"
  echo "Install with ./install.sh from the clone, or copy bin/chord next to config.toml"
fi

echo
echo "== config check =="
if command -v herdr >/dev/null 2>&1; then
  herdr config check
fi

echo
echo "== logs (last 15 lines) =="
for f in herdr-client.log herdr-server.log herdr.log chord.log; do
  path="$DIR/$f"
  if [ -f "$path" ]; then
    echo "--- $f ---"
    tail -n 15 "$path"
  fi
done

cat <<'EOF'

== what to try in Herdr ==

1. Prefix, release, then ? right away — help overlay.
   Prefix is Option-Esc (Mac) / Alt-Esc (alt+esc). Press it, let go, then ? with no pause.
   Waiting does nothing. Option-Space inserts a NBSP on Mac and
   never enters prefix mode.

2. Prefix, release, then n  — sidebar. No chord helper needed.

3. Prefix, release, then v, then v  — zoom via bin/chord.
   Help works but this does not → chord path or popup failed.
   Check chord.log after the attempt.

Reload after edits:

  herdr server reload-config

More log detail (restart Herdr after):

  HERDR_LOG=herdr=debug herdr
EOF
