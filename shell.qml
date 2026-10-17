//@ pragma UseQApplication
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = gtk3

import Quickshell
import "modules/bar"
import "modules/clipboard"
import "modules/launcher"

ShellRoot {
    Bar {}
    Clipboard {}
    Launcher {}
}
