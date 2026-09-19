#!/usr/bin/env bash
# Install MμHerdr into ~/.config/herdr.
# Homebrew or herdr.dev for the binary. Never delete the directory we are running from.
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

prefix_label() {
  echo "Ctrl-B"
}

set_prefix() {
  local conf="$INSTALL_DIR/config.toml"
  local key="ctrl+b"
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

stop_herdr() {
  # Only stop a server whose socket lives in this install dir.
  if command_exists herdr && { [ -S "$INSTALL_DIR/herdr.sock" ] || [ -S "$INSTALL_DIR/herdr-client.sock" ]; }; then
    herdr server stop >/dev/null 2>&1 || true
  fi
}

chmod_scripts() {
  for f in \
    "$INSTALL_DIR/bin/chord" \
    "$INSTALL_DIR/bin/theme" \
    "$INSTALL_DIR/debug.sh" \
    "$INSTALL_DIR/install.sh" \
    "$INSTALL_DIR/delete.sh" \
    "$INSTALL_DIR/plugin/notify.sh"
  do
    if [ -f "$f" ]; then
      chmod +x "$f"
    fi
  done
}

copy_file() {
  local src=$1 dest=$2
  [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

place_config() {
  if [ "$SCRIPT_DIR" = "$INSTALL_DIR" ]; then
    echo "Already running from $INSTALL_DIR — nothing to copy."
    return 0
  fi

  mkdir -p "$(dirname "$INSTALL_DIR")"

  if [ -e "$INSTALL_DIR" ] || [ -L "$INSTALL_DIR" ]; then
    echo "A config already exists at $INSTALL_DIR."
    printf "Keep it as a backup at %s? [y/N]: " "$BACKUP_DIR"
    read -r keep
    stop_herdr
    if [ "${keep:-n}" = "y" ] || [ "${keep:-n}" = "Y" ]; then
      rm -rf "$BACKUP_DIR"
      mv "$INSTALL_DIR" "$BACKUP_DIR"
    else
      rm -rf "$INSTALL_DIR"
    fi
  fi

  mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/themes"
  copy_file "$SCRIPT_DIR/config.toml" "$INSTALL_DIR/config.toml"
  copy_file "$SCRIPT_DIR/bin/chord" "$INSTALL_DIR/bin/chord"
  copy_file "$SCRIPT_DIR/bin/theme" "$INSTALL_DIR/bin/theme"
  if [ -d "$SCRIPT_DIR/themes" ]; then
    for pal in "$SCRIPT_DIR"/themes/*.toml; do
      [ -f "$pal" ] || continue
      copy_file "$pal" "$INSTALL_DIR/themes/$(basename "$pal")"
    done
  fi
  for f in install.sh delete.sh debug.sh README.md .gitignore notify.example; do
    copy_file "$SCRIPT_DIR/$f" "$INSTALL_DIR/$f"
  done
  if [ -d "$SCRIPT_DIR/plugin" ]; then
    mkdir -p "$INSTALL_DIR/plugin"
    copy_file "$SCRIPT_DIR/plugin/herdr-plugin.toml" "$INSTALL_DIR/plugin/herdr-plugin.toml"
    copy_file "$SCRIPT_DIR/plugin/notify.sh" "$INSTALL_DIR/plugin/notify.sh"
    copy_file "$SCRIPT_DIR/plugin/herdr.png" "$INSTALL_DIR/plugin/herdr.png"
    copy_file "$SCRIPT_DIR/plugin/herdr.svg" "$INSTALL_DIR/plugin/herdr.svg"
  fi
  if [ ! -f "$INSTALL_DIR/notify.toml" ] && [ -f "$SCRIPT_DIR/notify.example" ]; then
    copy_file "$SCRIPT_DIR/notify.example" "$INSTALL_DIR/notify.toml"
  fi
  echo "Copied MμHerdr to $INSTALL_DIR"
}

verify_install() {
  local missing=0
  for f in \
    "$INSTALL_DIR/config.toml" \
    "$INSTALL_DIR/bin/chord" \
    "$INSTALL_DIR/bin/theme" \
    "$INSTALL_DIR/themes/deep-ocean.toml" \
    "$INSTALL_DIR/delete.sh" \
    "$INSTALL_DIR/plugin/notify.sh" \
    "$INSTALL_DIR/plugin/herdr-plugin.toml"
  do
    if [ ! -f "$f" ]; then
      echo "Missing $f"
      missing=1
    fi
  done
  [ "$missing" = 0 ]
}

install_herdr || echo "Could not install herdr. Install it from https://herdr.dev then re-run."
place_config
if [ ! -f "$INSTALL_DIR/notify.toml" ]; then
  if [ -f "$INSTALL_DIR/notify.example" ]; then
    cp "$INSTALL_DIR/notify.example" "$INSTALL_DIR/notify.toml"
  elif [ -f "$SCRIPT_DIR/notify.example" ]; then
    cp "$SCRIPT_DIR/notify.example" "$INSTALL_DIR/notify.toml"
  fi
fi
chmod_scripts
set_prefix

if ! verify_install; then
  echo "Install did not land the required MμHerdr files."
  exit 1
fi

link_notify_plugin() {
  command_exists herdr || return 0
  [ -f "$INSTALL_DIR/plugin/herdr-plugin.toml" ] || return 0
  herdr plugin unlink muherdr.notify >/dev/null 2>&1 || true
  if herdr plugin link "$INSTALL_DIR/plugin" --enabled; then
    echo "Linked notify plugin muherdr.notify"
  else
    echo "Could not link the notify plugin. From a Herdr pane run:"
    echo "  herdr plugin link $INSTALL_DIR/plugin --enabled"
  fi
}

if command_exists herdr; then
  HERDR_CONFIG_PATH="$INSTALL_DIR/config.toml" herdr config check || true
  link_notify_plugin
  herdr server reload-config >/dev/null 2>&1 || true
fi

LABEL=$(prefix_label)

cat <<EOF

MμHerdr is in place at:
  $INSTALL_DIR

Open a new terminal, then:

  herdr

Action key is $LABEL.
$LABEL then ? lists binds.
EOF

cat <<EOF

Edit the config with:

  nvim $INSTALL_DIR/config.toml
EOF
