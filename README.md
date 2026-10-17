# luja-shell

Minimal-ish shell for Hyprland. Built with Quickshell.

## Requirements

- Quickshell, Hyprland and some basics e.g. PipeWire.
- `cliphist`, `wl-clipboard` and `coreutils`.

## Quick Start

Clone repo and launch inside Hyprland:

```sh
git clone https://github.com/luojam/luja-shell.git ~/.config/quickshell/luja-shell
quickshell -p ~/.config/quickshell/luja-shell
```

## Configuration

- Set `preferredOutput` in [config/Config.qml](config/Config.qml). Falls back to the first screen.
- Edit [config/Theme.qml](config/Theme.qml) for shell colors, typography, spacing, sizes, and animations.

### Startup

Start the shell and clipboard history recording automatically by adding these to `hyprland.start` in `~/.config/hypr/hyprland.lua`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell --config luja-shell --no-duplicate --daemonize")
    hl.exec_cmd("wl-paste --type text/plain --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
```

### Shortcuts

Bind your application launcher and clipboard history shortcuts:

```sh
quickshell ipc --config luja-shell call launcher toggle
quickshell ipc --config luja-shell call clipboard toggle
```
