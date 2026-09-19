# MμHerdr

A [Herdr](https://herdr.dev) config. Prefix (command mode) is **Ctrl-Alt-Space** on Linux and **Control-Option-Space** on a Mac (`ctrl+alt+space` in `config.toml`). Same chord on both OS; not tied to one terminal.

## Install

```
git clone https://github.com/AndresMpa/mu-herdr.git ~/.config/herdr
cd ~/.config/herdr
./install.sh
herdr
```

The installer puts Herdr on PATH (Homebrew or herdr.dev), copies this config to `~/.config/herdr` (chord helper, palettes, debug script, notify plugin), and sets the command-mode prefix (**Ctrl-Alt-Space** / **Control-Option-Space**). It does not copy sockets, logs, or `themes/active`. On a Mac it installs `terminal-notifier` if needed and brands `plugin/MuHerdr.app` with the Herdr ram. On Linux it installs a desktop icon for `notify-send`. It links `muherdr.notify`. If you already cloned into `~/.config/herdr`, it chmods scripts, sets the prefix, and prepares notifiers.

## Uninstall

```
cd ~/.config/herdr
./delete.sh
```

Removes MμHerdr config, state, cache, `old-herdr`, the notify plugin link, and the Linux desktop icon when `~/.config/herdr` has this config. Leaves the herdr binary, package manager packages, and any Herdr config that is not MμHerdr.

## Prefix

| | MμHerdr |
| --- | --- |
| Action key | Ctrl-Alt-Space (Control-Option-Space on a Mac) then the map letters |

Hold Ctrl+Alt (Control+Option on a Mac) and Space, **release**, then the same letters as Space in MμVim. Do not wait. Prefix then `?` lists every binding. Ctrl-B is **not** a prefix.

Herdr prefix mode only takes **one** key (like tmux). For sequences of two or three letters (`vv`, `vj`, `vk`, `gst`, …) that first letter opens a small helper which reads the rest. The letters stay the same.

**Why this chord.** Space plus one modifier is not portable: Ctrl-Space is taken by the OS, Shift-Space is sent as Space, Option-Space inserts a non-breaking space on a Mac, Command-Space is Spotlight. Herdr’s keyboard guide maps Ghostty, Kitty, WezTerm, iTerm2, Alacritty, GNOME, and KDE: **Ctrl-Alt** is the family that still reaches the app. Token is always `ctrl+alt+space` (Option is Alt).

## Maps

| Space | MμHerdr | Herdr action |
| --- | --- | --- |
| `Space q` | prefix `q` | Detach (Herdr keeps running) |
| `Space h` | prefix `h` | Close tab |
| `Space j` / `k` | prefix `j` / `k` | Previous / next tab |
| `Space H` | prefix `H` | Close other tabs |
| `Space l` | prefix `l` | List tabs |
| `Space vv` | prefix `v` then `v` | Zoom (only this pane) |
| `Space vj` | prefix `v` then `j` | Split down |
| `Space vk` | prefix `v` then `k` | Split right |
| `Space n` | prefix `n` | Sidebar (tree) |
| `Space gst` | prefix `g` then `st` | Lazygit (`git status` if lazygit is missing) |
| `Space th` | prefix `t` then `h` | Theme picker |
| | prefix `e` | SSH keys and hosts |
| | prefix `p` | Docker/Podman containers |
| `Ctrl-t` (new terminal) | prefix `t` then `t` (or wait) | Split right (new pane) |
| `Ctrl-h/j/k/l` (windows) | `Ctrl-h/j/k/l` | Focus pane (no prefix) |

### Git (prefix `g`, then the same letters)

| Space | After prefix `g` | Action |
| --- | --- | --- |
| `Space gst` | `st` | Lazygit / `git status` |
| `Space gpl` | `pl` | `git pull` |
| `Space gps` | `ps` | `git push` |
| `Space gll` | `ll` | `git pull` current branch |
| `Space gpp` | `pp` | `git push` current branch |
| `Space gpx` | `px` | `git push -u` current branch |
| `Space gaa` | `aa` | `git add --all` |
| `Space gap` | `ap` | `git add -p` |
| `Space gbl` | `bl` | `git blame` |
| `Space gsh` | `sh` | `git show` |
| `Space gii` | `ii` | `git init` |
| `Space grv` | `rv` | `git remote -v` |
| `Space gc` | `c` | `git commit` (wait 1s; `co` / `cb` continue) |
| `Space gco` | `co` | `git checkout …` |
| `Space gcb` | `cb` | `git checkout -b …` |
| `Space gsw` | `sw` | `git switch …` |
| `Space ggg` | `gg` | `git …` |

Detach is prefix `d` or prefix `q`. Close the focused pane with prefix `x`. Resize is prefix `r`. Esc cancels a chord. Prefix `o` jumps to the pane that raised the last notification.

## Notifications

When an agent is **blocked** or **done**, MμHerdr sends a desktop banner (and a sound). Slack and Telegram stay off until you add a webhook or bot. `working` and `idle` do not notify.

| | |
| --- | --- |
| Title | `MμHerdr` |
| Body (blocked) | `Workspace {name} ({model}) Need your attention` |
| Body (done) | `Workspace {name} ({model}) finished` |
| Icon | Herdr ram, left side only (`plugin/herdr.png`) |
| Jump to pane | prefix `o` |

`./install.sh` links the plugin `muherdr.notify`. Check:

```
herdr plugin list
```

If the list is empty (wrong flag order used to eat the path):

```
herdr plugin link ~/.config/herdr/plugin --enabled
```

Do **not** test with `herdr notification show`. That API cannot set the ram icon. Test the plugin:

```
HERDR_PLUGIN_EVENT_JSON='{"data":{"agent_status":"blocked","display_agent":"grok","workspace_id":"w1"}}' \
  bash ~/.config/herdr/plugin/notify.sh
```

### Mac

`./install.sh` runs `brew install terminal-notifier` if needed, copies that `.app` to `plugin/MuHerdr.app`, and puts the ram in the bundle. Notification Center uses the **sending app** icon; `-appIcon` is ignored.

System Settings → Notifications → **MμHerdr** → Allow, banners. The first post may ask for permission. An old stub app without the ram: `rm -rf ~/.config/herdr/plugin/MuHerdr.app` then `./install.sh` again.

### Linux

`./install.sh` writes `~/.local/share/icons/hicolor/512x512/apps/muherdr.png` and `~/.local/share/applications/muherdr.desktop`. Alerts go through `notify-send -a MμHerdr -i` with the ram PNG. If nothing appears:

```
# Debian / Ubuntu
sudo apt install libnotify-bin

# Fedora
sudo dnf install libnotify

# Arch
sudo pacman -S libnotify
```

`./delete.sh` removes those two desktop files as well.

### Slack and Telegram (optional)

`notify.toml` next to `config.toml` is gitignored. Copy from `notify.example`:

```
system = true
slack = false
telegram = false
slack_webhook_url =
telegram_bot_token =
telegram_chat_id =
```

Set `slack = true` and an Incoming Webhooks URL, and/or `telegram = true` with a BotFather token and chat id. Env vars `SLACK_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN`, and `TELEGRAM_CHAT_ID` also work. Chat lines are prefixed `MμHerdr:`. `./delete.sh` unlinks the plugin and does not keep the secrets file in git.

## SSH

Prefix `e` opens a picker of **keys** (`~/.ssh/*.pub`) and **hosts** (`Host` lines in `~/.ssh/config`). Wildcards (`*` / `?`) are skipped. Chrome matches the theme picker: indented, `j`/`k`, Enter, Esc, `❯`.

| Row | What you see | Enter |
| --- | --- | --- |
| key | filename, `agent` if `ssh-add -l` has it, fingerprint | `ssh-add` that private key (uses Keychain on Mac). Marks it for the next host. |
| host | Host alias and `user@hostname` | `ssh` to that alias in the popup. Uses the marked key if you loaded one, otherwise the config `IdentityFile`. |

This is OpenSSH, not `herdr machine` (that is for a remote Herdr server). Passphrases are typed in the popup. Private key material is never printed.

```
Prefix, e
```

## Containers

Prefix `p` opens a **theme-style modal** of **containers only** (Docker, Podman, or nerdctl `ps -a`). `j`/`k` move, Enter **adds the container as a pane in the current workspace**, Esc cancels. Stopped containers are started first, then `exec -it` (bash or sh). The pane is renamed `docker:name` / `podman:name`.

```
Prefix, p
```

## Theme

MμHerdr palettes, applied to **all** Herdr UI tokens (sidebar, panels, keybind help, accents) plus OSC so the terminal cells follow.

Default is **deep-ocean**. Prefix `t` then `h` opens the picker. The header sits off the left edge. `j/k` (accent) moves and previews, Enter saves, `Esc` (red) restores, `❯` marks the current row. Names share one column width. Or:

```
~/.config/herdr/bin/theme list
~/.config/herdr/bin/theme apply gruvbox
herdr server reload-config
```

| Name |
| --- |
| `deep-ocean` (default) |
| `gruvbox` |
| `mini` |
| `oceanic` |
| `palenight` |
| `darker` |
| `nord` |
| `dracula` |
| `tokyonight` |
| `catppuccin` |
| `onedark` |

## Debug

If keys do nothing, run this **inside a Herdr pane**:

```
cd ~/.config/herdr
./debug.sh
```

Then, in Herdr: Ctrl-Alt-Space (Control-Option-Space on a Mac), **release**, then `?` right away. Help overlay means the prefix reached Herdr. Sidebar (`n`) needs no helper; `vv` / `gst` need `bin/chord`. After a failed `v` or `g`, read `~/.config/herdr/chord.log`.

```
herdr config check
herdr server reload-config
```

For more Herdr log detail, restart with `HERDR_LOG=herdr=debug herdr`. Logs live next to `config.toml`.

## Reload

```
herdr server reload-config
```
