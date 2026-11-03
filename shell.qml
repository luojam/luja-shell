//@ pragma UseQApplication
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = gtk3

import Quickshell
import "config"
import "modules/bar"
import "modules/menu"
import "modules/notifications"
import "modules/wallpaper"

ShellRoot {
    Settings {}
    Wallpaper {}
    Bar {}
    Menu {}
    Notifications {}
}
