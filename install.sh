#!/usr/bin/env bash
# Install MμHerdr the same way Mini does, in shell:
# Homebrew or herdr.dev. Never delete the directory we are running from.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOME_DIR=${HOME:-}
INSTALL_DIR="${HOME_DIR}/.config/herdr"
BACKUP_DIR="${HOME_DIR}/.config/old-herdr"

cd "$HOME_DIR" || exit 1

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_herdr() {
  if command_exists herdr; then
    echo "herdr is already on PATH: $(command -v herdr)"
    return 0
  fi
  if command_exists brew; then
    echo "Installing herdr with Homebrew."
    brew install herdr
    return
  fi
  echo "Installing herdr with https://herdr.dev/install.sh"
  curl -fsSL https://herdr.dev/install.sh | sh
}

# Herdr's key token is cmd+b (Command-B).
prefix_label() {
  echo "Command-B"
}

set_prefix() {
  local conf="$INSTALL_DIR/config.toml"
  local key="cmd+b"
  local label
  label=$(prefix_label)
  [ -f "$conf" ] || return 0
  tmp=$(mktemp)
  awk -v key="$key" '
    /^prefix = / { print "prefix = \"" key "\""; next }
    { print }
  ' "$conf" > "$tmp" && mv "$tmp" "$conf"
  echo "Prefix set to $label ($key) on $(uname -s)."
}

place_config() {
  if [ "$SCRIPT_DIR" = "$INSTALL_DIR" ]; then
    echo "Already running from $INSTALL_DIR — nothing to copy."
    return 0
  fi

  mkdir -p "$(dirname "$INSTALL_DIR")"

  if [ -e "$INSTALL_DIR" ]; then
    echo "A config already exists at $INSTALL_DIR."
    printf "Keep it as a backup at %s? [y/N]: " "$BACKUP_DIR"
    read -r keep
    if [ "${keep:-n}" = "y" ] || [ "${keep:-n}" = "Y" ]; then
      rm -rf "$BACKUP_DIR"
      mv "$INSTALL_DIR" "$BACKUP_DIR"
    else
      rm -rf "$INSTALL_DIR"
    fi
  fi

  mkdir -p "$INSTALL_DIR"
  cp -R "$SCRIPT_DIR"/. "$INSTALL_DIR"/
  echo "Copied MμHerdr to $INSTALL_DIR"
}

chmod_chord() {
  if [ -f "$INSTALL_DIR/bin/chord" ]; then
    chmod +x "$INSTALL_DIR/bin/chord"
  fi
}

printf "Use a custom config directory? (default %s) [y/N]: " "$INSTALL_DIR"
read -r custom
if [ "${custom:-n}" = "y" ] || [ "${custom:-n}" = "Y" ]; then
  printf "Enter the path: "
  read -r custom_path
  if [ -n "${custom_path:-}" ]; then
    case "$custom_path" in
      ~*) INSTALL_DIR="${HOME_DIR}${custom_path#\~}" ;;
      *) INSTALL_DIR=$custom_path ;;
    esac
  fi
fi

install_herdr || echo "Could not install herdr. Install it from https://herdr.dev then re-run."
place_config
chmod_chord
set_prefix

if command_exists herdr; then
  herdr server reload-config >/dev/null 2>&1 || true
fi

LABEL=$(prefix_label)

cat <<EOF

MμHerdr is in place at:
  $INSTALL_DIR

Open a new terminal, then:

  herdr

Action key is $LABEL (MμVim leader stays Space).
$LABEL then ? lists binds.
EOF

cat <<EOF

Edit the config with:

  nvim $INSTALL_DIR/config.toml
EOF
