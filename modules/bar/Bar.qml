pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"

Variants {
    model: {
        const screen = Quickshell.screens.find(s => s.name === Config.preferredOutput) ?? Quickshell.screens[0];
        return screen ? [screen] : [];
    }

    PanelWindow {
        id: bar
        required property ShellScreen modelData

        screen: modelData
        implicitHeight: Theme.bar.height
        color: Theme.colors.transparent
        WlrLayershell.namespace: 'luja-bar'

        anchors {
            top: true
            left: true
            right: true
        }

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
        }
    }
}
