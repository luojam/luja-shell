import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"

PanelWindow {
    id: bar
    screen: Quickshell.screens.find(s => s.name === Config.preferredOutput) ?? Quickshell.screens[0]

    implicitHeight: 24
    color: 'transparent'
    WlrLayershell.namespace: 'luja-bar'

    anchors {
        top: true
        left: true
        right: true
    }

    /*Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Memory {}
    }*/

    Row {
        anchors.centerIn: parent
        spacing: 4

        Clock {}

        Workspaces {
            screen: bar.screen
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Tray {}
        DateDisplay {}
        Volume {}
        Memory {}
    }
}
