# MμHerdr

A [Herdr](https://herdr.dev) config that follows [MμVim](https://github.com/AndresMpa/mu-vim) maps, with a **different action key**.

MμVim leader is `Space`. Herdr prefix is **Alt-Space** (Linux) or **Option-Space** (Mac). `./install.sh` picks the label from `uname`; the token in `config.toml` is always `alt+space` (Herdr's name for Option/Alt).

## Install

```
git clone https://github.com/AndresMpa/mu-herdr.git ~/.config/herdr
cd ~/.config/herdr
./install.sh
herdr
```

The installer puts Herdr on PATH (Homebrew or herdr.dev), copies this config to `~/.config/herdr`, and sets the prefix for this OS. `Alt-Space`/`Option-Space` then `?` lists every binding.

## Uninstall

```
cd ~/.config/herdr
./delete.sh
```

Removes the config, state, and `old-herdr`. Leaves the herdr binary and package manager packages.

## Action key

| | MμVim | MμHerdr |
| --- | --- | --- |
| Action key | `Space` | `Alt-Space` / `Option-Space` (Mac) then the letter |

Press Alt-Space (Option-Space on a Mac), release, then the same letter you would use after Space in MμVim.

## Maps

| MμVim | MμHerdr | Herdr action |
| --- | --- | --- |
| `Space q` | prefix `q` | Close pane |
| `Space h` | prefix `Shift-x` | Close tab |
| `Space j` / `k` | prefix `[` / `]` | Previous / next tab |
| `Space vv` | prefix `z` | Zoom (only this pane) |
| `Space vj` | prefix `-` | Split down |
| `Space vk` | prefix `v` | Split right |
| `Space n` | prefix `n` | Sidebar (tree) |
| `Space gst` | prefix `Shift-g` | Lazygit |
| `Ctrl-t` (new terminal) | prefix `t` | Split right (new pane) |
| `Ctrl-h/j/k/l` (windows) | prefix `h/j/k/l` | Focus pane |

Herdr only accepts **one key** after the prefix (like tmux), so `vv` / `vj` / `vk` / `gst` become `z` / `-` / `v` / `Shift-g`. Resize is prefix `Shift-h/j/k/l`. Prefix is Alt-Space, or Option-Space on a Mac.

Detach (leave Herdr running) is prefix `d`, not `q`, so `q` can match Vim quit.

On a Mac, set the terminal so Option is Alt (iTerm2: Profiles → Keys → Left Option key = Esc+).

## Theme

UI colors follow Current **deep-ocean** (`#0F111A`, `#82AAFF`, `#C3E88D`, `#C792EA`).

## Reload

```
herdr server reload-config
```
