#!/usr/bin/env bash
# Uninstall MμHerdr user data. Leaves the herdr binary (and package manager packages).
#
# Removes:
#   - the herdr config directory
#   - this clone, if you ran ./delete.sh from mu-herdr
#   - herdr state
#   - the old-herdr backup from install.sh
#
# Run: ./delete.sh
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOME_DIR=${HOME:-}
INSTALL_DIR="${HOME_DIR}/.config/herdr"
BACKUP_DIR="${HOME_DIR}/.config/old-herdr"
STATE_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/herdr"

cd "$HOME_DIR" || exit 1

looks_like_herdr() {
  local dir=$1
  [ -f "$dir/config.toml" ] && { [ -f "$dir/install.sh" ] || [ -f "$dir/delete.sh" ]; }
}

if ! looks_like_herdr "$INSTALL_DIR" && ! looks_like_herdr "$SCRIPT_DIR"; then
  echo "No MμHerdr install found in $INSTALL_DIR or $SCRIPT_DIR"
  exit 1
fi

PATHS=()
WHYS=()

add_target() {
  PATHS+=("$1")
  WHYS+=("$2")
}

add_target "$STATE_DIR" "Herdr state"
add_target "$BACKUP_DIR" "Backup from install.sh"
add_target "$INSTALL_DIR" "MμHerdr config (~/.config/herdr)"

if looks_like_herdr "$SCRIPT_DIR" \
  && [ "$SCRIPT_DIR" != "$INSTALL_DIR" ] \
  && [ "$SCRIPT_DIR" != "$HOME_DIR" ]; then
  add_target "$SCRIPT_DIR" "This MμHerdr clone"
fi

echo "This removes MμHerdr config, state, and this clone if needed."
echo "The herdr binary is not uninstalled."
echo

i=0
while [ "$i" -lt "${#PATHS[@]}" ]; do
  path=${PATHS[$i]}
  why=${WHYS[$i]}
  if [ -e "$path" ]; then
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
  herdr server stop >/dev/null 2>&1 || true
fi

i=0
while [ "$i" -lt "${#PATHS[@]}" ]; do
  path=${PATHS[$i]}
  if [ -e "$path" ]; then
    echo "Removing $path"
    rm -rf "$path"
  fi
  i=$((i + 1))
done

echo "MμHerdr user data is gone. herdr is still installed."
