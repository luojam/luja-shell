pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import "../../config"

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    implicitWidth: workspaceRow.implicitWidth + Theme.workspaces.padding * 2
    implicitHeight: Theme.bar.widgetHeight
    radius: Theme.bar.widgetRadius
    color: Theme.colors.barBackground

    Row {
        id: workspaceRow

        anchors.centerIn: parent

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: indicator

                required property HyprlandWorkspace modelData
                readonly property bool occupied: modelData.toplevels.values.length > 0

                width: Theme.workspaces.slotSize
                height: Theme.workspaces.slotSize
                visible: root.monitor !== null && modelData.monitor === root.monitor && !modelData.name.startsWith("special:")

                Shape {
                    id: bar

                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    property real barWidth: indicator.modelData.active ? Theme.workspaces.activeWidth : Theme.workspaces.inactiveWidth
                    property color barColor: indicator.modelData.active ? Theme.colors.workspaceSelected : indicator.modelData.urgent ? Theme.colors.workspaceUrgent : indicator.occupied ? Theme.colors.workspaceOccupied : Theme.colors.workspaceEmpty

                    ShapePath {
                        strokeWidth: -1
                        fillColor: bar.barColor

                        PathRectangle {
                            x: (bar.width - width) / 2
                            y: (bar.height - height) / 2
                            width: bar.barWidth
                            height: Theme.workspaces.activeHeight
                            radius: Theme.workspaces.indicatorRadius
                        }
                    }

                    Behavior on barWidth {
                        NumberAnimation {
                            duration: Theme.animations.workspaceDuration
                            easing.type: Theme.animations.workspaceEasing
                            easing.bezierCurve: Theme.animations.workspaceCurve
                        }
                    }

                    Behavior on barColor {
                        ColorAnimation {
                            duration: Theme.animations.workspaceDuration
                            easing.type: Theme.animations.workspaceEasing
                            easing.bezierCurve: Theme.animations.workspaceCurve
                        }
                    }
                }
            }
        }
    }
}
