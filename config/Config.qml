pragma Singleton

import QtQml
import Quickshell

QtObject {
    property string preferredOutput: "DP-3"
    property string wallpaperPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/wallpaper"
    property int notificationTimeout: 10000
    property int maxVisibleNotifications: 5
}
