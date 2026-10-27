<div align="center">

# luja-shell

**My desktop shell for Hyprland. Built with Quickshell.**

</div>

## Requirements

Install the required packages. Not all are necessary, such as [wiremix](https://github.com/tsowell/wiremix) or [ghostty](https://github.com/ghostty-org/ghostty) if you prefer a different terminal.

```bash
sudo pacman -Syu --needed \
    hyprland \
    quickshell \
    cliphist \
    diffutils \
    ghostty \
    wiremix \
    pipewire-audio \
    wireplumber \
    ttf-jetbrains-mono-nerd \
    git
```

## Quick Start

Clone repo and test inside Hyprland.

```sh
git clone https://github.com/luojam/luja-shell.git ~/.config/quickshell/luja-shell
quickshell -p ~/.config/quickshell/luja-shell
```

### Hyprland Startup

Add these to `hyprland.start` in `~/.config/hypr/hyprland.lua` to automatically launch quickshell and set up clipboard history.

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell --config luja-shell --no-duplicate --daemonize")
    hl.exec_cmd("wl-paste --type text/plain --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
```

### Top bar

Click the time to expand or collapse the top bar.

## Configuration

- [config/Config.qml](config/Config.qml)
- [config/Theme.qml](config/Theme.qml)

### Wallpaper

Set the wallpaper for all monitors:

```sh
ln -sfn ~/Pictures/your-wallpaper.png "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/wallpaper"
quickshell ipc --config luja-shell call wallpaper reload
```

### Keybinds

You can (and should) bind commands from this section to keys of your choice in `~/.config/hypr/hyprland.lua` or your separate keybinds module.

**Example binding**

```lua
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("quickshell ipc --config luja-shell call launcher toggle"), { release = true }) -- App launcher - !important BIND this
hl.bind("SUPER + V", hl.dsp.exec_cmd("quickshell ipc --config luja-shell call clipboard toggle"))                          -- Clipboard history
```

**Commands to bind**

```sh
quickshell ipc --config luja-shell call launcher toggle             # App launcher - !important BIND this
quickshell ipc --config luja-shell call clipboard toggle            # Clipboard history
quickshell ipc --config luja-shell call notifications dismiss       # <Optional> dismiss a notification
quickshell ipc --config luja-shell call notifications dismissAll    # <Optional> dismiss all notifications
```
