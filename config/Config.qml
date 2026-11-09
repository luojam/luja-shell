pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

QtObject {
    property string preferredOutput: "DP-3"
    property alias barStyle: persisted.barStyle
    property string wallpaperPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/wallpaper"
    property int notificationTimeout: 5000
    property int maxVisibleNotifications: 5

    readonly property JsonAdapter persistentOptions: JsonAdapter {
        id: persisted

        property string barStyle: "notch"

        onBarStyleChanged: {
            if (barStyle !== "pill" && barStyle !== "notch")
                barStyle = "notch";
        }
    }
}
