# luja-shell

Minimal-ish shell for Hyprland. Built with Quickshell.

## Requirements

- Quickshell, Hyprland and some basics e.g. PipeWire.

## Quick Start

Clone and launch inside Hyprland:

```sh
git clone https://github.com/luojam/luja-shell.git ~/.config/quickshell/luja-shell
quickshell -p ~/.config/quickshell/luja-shell
```

To start automatically, add to your `~/.config/hypr/hyprland.lua`

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell --config luja-shell --no-duplicate --daemonize")
end)
```

## Configuration

- Set `preferredOutput` in [config/Config.qml](config/Config.qml). Falls back to the first screen.
- Edit [config/Theme.qml](config/Theme.qml) for shell colors, typography, spacing, sizes, and animations.
