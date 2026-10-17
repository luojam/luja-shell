import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"

PanelWindow {
    id: bar
    screen: Quickshell.screens.find(s => s.name === Config.preferredOutput) ?? Quickshell.screens[0]

    implicitHeight: Theme.bar.height
    color: Theme.colors.transparent
    WlrLayershell.namespace: 'luja-bar'

    anchors {
        top: true
        left: true
        right: true
    }

    /*Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.bar.edgeMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.bar.spacing

        Memory {}
    }*/

    Row {
        anchors.centerIn: parent
        spacing: Theme.bar.spacing

        Clock {}

        Workspaces {
            screen: bar.screen
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.bar.edgeMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.bar.spacing

        Tray {}
        DateDisplay {}
        Volume {}
        Memory {}
    }
}
