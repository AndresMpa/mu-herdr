#!/usr/bin/env bash
# Uninstall MμHerdr user data. Leaves the herdr binary (and package manager packages).
#
# Removes only paths that look like MμHerdr:
#   - ~/.config/herdr when it has this config (bin/chord or install.sh)
#   - this clone, if you ran ./delete.sh from elsewhere
#   - herdr state and cache for that install
#   - the old-herdr backup from install.sh
#
# Run: ./delete.sh
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOME_DIR=${HOME:-}
INSTALL_DIR="${HOME_DIR}/.config/herdr"
BACKUP_DIR="${HOME_DIR}/.config/old-herdr"
STATE_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/herdr"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME_DIR/.cache}/herdr"

cd "$HOME_DIR" || exit 1

looks_like_herdr() {
  local dir=$1
  [ -d "$dir" ] || [ -L "$dir" ] || return 1
  [ -f "$dir/config.toml" ] || return 1
  [ -f "$dir/bin/chord" ] || [ -f "$dir/bin/theme" ] || [ -f "$dir/install.sh" ] || [ -f "$dir/delete.sh" ]
}

remove_path() {
  local path=$1
  if [ -L "$path" ]; then
    echo "Removing symlink $path"
    rm -f "$path"
    return
  fi
  if [ -e "$path" ]; then
    echo "Removing $path"
    rm -rf "$path"
  fi
}

PATHS=()
WHYS=()

add_target() {
  PATHS+=("$1")
  WHYS+=("$2")
}

if looks_like_herdr "$INSTALL_DIR"; then
  add_target "$STATE_DIR" "Herdr state"
  add_target "$CACHE_DIR" "Herdr cache"
  add_target "$BACKUP_DIR" "Backup from install.sh"
  add_target "$INSTALL_DIR" "MμHerdr config (~/.config/herdr)"
  add_target "$HOME_DIR/.local/share/applications/muherdr.desktop" "Linux desktop entry"
  add_target "$HOME_DIR/.local/share/icons/hicolor/512x512/apps/muherdr.png" "Linux notification icon"
fi

if looks_like_herdr "$SCRIPT_DIR" \
  && [ "$SCRIPT_DIR" != "$INSTALL_DIR" ] \
  && [ "$SCRIPT_DIR" != "$HOME_DIR" ]; then
  add_target "$SCRIPT_DIR" "This MμHerdr clone"
fi

if [ "${#PATHS[@]}" -eq 0 ]; then
  echo "No MμHerdr install found in $INSTALL_DIR or $SCRIPT_DIR"
  exit 1
fi

echo "This removes MμHerdr config, state, and this clone if needed."
echo "The herdr binary is not uninstalled."
echo "A Herdr config without MμHerdr files is left alone."
echo

i=0
while [ "$i" -lt "${#PATHS[@]}" ]; do
  path=${PATHS[$i]}
  why=${WHYS[$i]}
  if [ -e "$path" ] || [ -L "$path" ]; then
    printf "  [*] %s\n      %s\n" "$path" "$why"
  else
    printf "  [ ] %s\n      %s\n" "$path" "$why"
  fi
  i=$((i + 1))
done

echo
printf "Delete the paths marked * ? [y/N]: "
read -r ok
if [ "${ok:-n}" != "y" ] && [ "${ok:-n}" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

if command -v herdr >/dev/null 2>&1; then
  herdr plugin unlink muherdr.notify >/dev/null 2>&1 || true
  if [ -S "$INSTALL_DIR/herdr.sock" ] || [ -S "$INSTALL_DIR/herdr-client.sock" ]; then
    herdr server stop >/dev/null 2>&1 || true
  fi
fi

i=0
while [ "$i" -lt "${#PATHS[@]}" ]; do
  remove_path "${PATHS[$i]}"
  i=$((i + 1))
done

echo "MμHerdr user data is gone. herdr is still installed."
