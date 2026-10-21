pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"

Scope {
    id: root

    property bool reloading: false

    IpcHandler {
        target: "wallpaper"

        function reload(): void {
            root.reloading = true;
            Qt.callLater(() => root.reloading = false);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            color: "#000000"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.namespace: "luja-wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                anchors.fill: parent
                source: root.reloading ? "" : Qt.resolvedUrl(Config.wallpaperPath)
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                asynchronous: true
                cache: false
            }
        }
    }
}
