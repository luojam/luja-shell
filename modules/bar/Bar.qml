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
        property bool expanded: false

        screen: modelData
        implicitHeight: Theme.bar.height
        color: Theme.colors.transparent
        WlrLayershell.namespace: 'luja-bar'

        anchors {
            top: true
            left: true
            right: true
        }

        DateDisplay {
            anchors.right: core.left
            anchors.rightMargin: Theme.bar.spacing
            anchors.verticalCenter: core.verticalCenter
            visible: bar.expanded
        }

        Row {
            id: core

            anchors.centerIn: parent
            spacing: Theme.bar.spacing

            Clock {
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.expanded = !bar.expanded
                }
            }

            Workspaces {
                screen: bar.screen
            }
        }

        Row {
            anchors.left: core.right
            anchors.leftMargin: Theme.bar.spacing
            anchors.verticalCenter: core.verticalCenter
            spacing: Theme.bar.spacing

            Volume {
                visible: bar.expanded
            }

            Tray {}
        }
    }
}
