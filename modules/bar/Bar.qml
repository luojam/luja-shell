import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    screen: Quickshell.screens.find(s => s.name === "DP-3") ?? Quickshell.screens[0]

    implicitHeight: 24
    color: 'transparent'
    WlrLayershell.namespace: 'luja-bar'

    anchors {
        top: true
        left: true
        right: true
    }

    Workspaces {
        anchors.centerIn: parent
        screen: bar.screen
    }
}
