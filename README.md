# MμHerdr

A [Herdr](https://herdr.dev) config. Prefix is **Ctrl-B**. The token in `config.toml` is `ctrl+b`. Option-Space cannot be the prefix on a Mac: it inserts a non-breaking space instead of a modifier chord.

## Install

```
git clone https://github.com/AndresMpa/mu-herdr.git ~/.config/herdr
cd ~/.config/herdr
./install.sh
herdr
```

The installer puts Herdr on PATH (Homebrew or herdr.dev), copies this config to `~/.config/herdr`, and sets the prefix. `Ctrl-B` then `?` lists every binding.

## Uninstall

```
cd ~/.config/herdr
./delete.sh
```

Removes the config, state, and `old-herdr`. Leaves the herdr binary and package manager packages.

## Prefix

| | MμHerdr |
| --- | --- |
| Action key | `Ctrl-B` then the map letters |

Press Ctrl-B, **release**, then immediately the map letters. Do not wait. `Ctrl-B` then `?` lists every binding.

Herdr prefix mode only takes **one** key (like tmux). For sequences of two or three letters (`vv`, `vj`, `vk`, `gst`, …) that first letter opens a small helper which reads the rest. The letters stay the same.

Command-B never reaches a Mac terminal. Option-Space inserts a non-breaking space and cannot enter prefix mode.

## Maps

| Space | MμHerdr | Herdr action |
| --- | --- | --- |
| `Space q` | prefix `q` | Close pane |
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

Detach (leave Herdr running) is prefix `d`, not `q`, so `q` can match Vim quit. Resize mode is prefix `r`. Esc cancels a chord.

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

Then, in Herdr: Ctrl-B, **release**, then `?` right away. Help overlay means the prefix reached Herdr. Sidebar (`n`) needs no helper; `vv` / `gst` need `bin/chord`. After a failed `v` or `g`, read `~/.config/herdr/chord.log`.

```
herdr config check
herdr server reload-config
```

For more Herdr log detail, restart with `HERDR_LOG=herdr=debug herdr`. Logs live next to `config.toml`.

## Reload

```
herdr server reload-config
```
