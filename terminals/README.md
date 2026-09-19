# Terminals

MμHerdr prefix is **Shift-Space** in Herdr itself (`prefix = "shift+space"`). Do **not** remap that chord in the terminal to Ctrl-B or anything else — Ctrl-B must not be the prefix.

Herdr opts into the Kitty keyboard protocol. Any terminal that implements it can send Shift-Space as a different event from Space: **Kitty**, **Ghostty**, **WezTerm**, and others. No extra `keybind` is required for that.

**iTerm2** (and many GTK terminals) send Shift-Space as Space. That is a terminal limit, not an MμHerdr setting. Use a protocol-capable terminal if you want this prefix.

Do not add:

```
keybind = shift+space=text:\x02
```

That makes Ctrl-B and Shift-Space the same prefix.
