# MμHerdr

A [Herdr](https://herdr.dev) config that follows [MμVim](https://github.com/AndresMpa/mu-vim) maps, with a **different action key**.

MμVim leader is `Space`. Herdr prefix is `Ctrl-Space`, so Neovim still owns `Space`.

## Install

```
git clone https://github.com/AndresMpa/mu-herdr.git ~/.config/herdr
cd ~/.config/herdr
./install.sh
herdr
```

The installer puts Herdr on PATH (Homebrew or herdr.dev) and copies this config to `~/.config/herdr`. `Ctrl-Space ?` lists every binding.

## Uninstall

```
cd ~/.config/herdr
./delete.sh
```

Removes the config, state, and `old-herdr`. Leaves the herdr binary and package manager packages.

## Action key

| | MμVim | MμHerdr |
| --- | --- | --- |
| Action key | `Space` | `Ctrl-Space` then the letter |

Press `Ctrl-Space`, release, then the same letter you would use after Space in MμVim.

## Maps

| MμVim | MμHerdr | Herdr action |
| --- | --- | --- |
| `Space q` | `Ctrl-Space` `q` | Close pane |
| `Space h` | `Ctrl-Space` `Shift-h` | Close tab |
| `Space j` / `k` | `Ctrl-Space` `Shift-j` / `Shift-k` | Previous / next tab |
| `Space vv` | `Ctrl-Space` `vv` | Zoom (only this pane) |
| `Space vj` | `Ctrl-Space` `vj` | Split down |
| `Space vk` | `Ctrl-Space` `vk` | Split right |
| `Space n` | `Ctrl-Space` `n` | Sidebar (tree) |
| `Space gst` | `Ctrl-Space` `gst` | Lazygit |
| `Ctrl-t` (new terminal) | `Ctrl-Space` `t` | Split right (new pane) |
| `Ctrl-h/j/k/l` (windows) | `Ctrl-Space` `h/j/k/l` | Focus pane |

Resize is `Ctrl-Space` `Shift-h/j/k/l`.

Detach (leave Herdr running) is `Ctrl-Space` `d`, not `q`, so `q` can match Vim quit.

## Theme

UI colors follow Current **deep-ocean** (`#0F111A`, `#82AAFF`, `#C3E88D`, `#C792EA`).

## Reload

```
herdr server reload-config
```
