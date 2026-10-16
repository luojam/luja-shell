pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    implicitWidth: workspaceRow.implicitWidth + 16
    implicitHeight: 20
    radius: 10
    color: Qt.rgba(28 / 255, 28 / 255, 28 / 255, 0.75)

    Row {
        id: workspaceRow

        anchors.centerIn: parent

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: indicator

                required property HyprlandWorkspace modelData
                readonly property bool occupied: modelData.toplevels.values.length > 0

                width: 17
                height: 18
                visible: root.monitor !== null && modelData.monitor === root.monitor && !modelData.name.startsWith("special:")

                Rectangle {
                    anchors.centerIn: parent
                    width: indicator.modelData.active ? 16 : (indicator.occupied || indicator.modelData.urgent ? 8 : 6)
                    height: indicator.modelData.active ? 12 : (indicator.occupied || indicator.modelData.urgent ? 8 : 6)
                    radius: 9
                    color: indicator.modelData.active ? "#89b4fa" : indicator.modelData.urgent ? "#f38ba8" : indicator.occupied ? "#bac2de" : "#585b70"

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.25, 0.25, 0.75, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.25, 0.25, 0.75, 1, 1, 1]
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.25, 0.25, 0.75, 1, 1, 1]
                        }
                    }
                }
            }
        }
    }
}
