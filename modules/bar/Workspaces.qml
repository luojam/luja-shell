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
                    id: dot

                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    property real dotWidth: indicator.modelData.active ? Theme.workspaces.activeWidth : (indicator.occupied || indicator.modelData.urgent ? Theme.workspaces.occupiedSize : Theme.workspaces.emptySize)
                    property real dotHeight: indicator.modelData.active ? Theme.workspaces.activeHeight : (indicator.occupied || indicator.modelData.urgent ? Theme.workspaces.occupiedSize : Theme.workspaces.emptySize)
                    property color dotColor: indicator.modelData.active ? Theme.colors.accent : indicator.modelData.urgent ? Theme.colors.workspaceUrgent : indicator.occupied ? Theme.colors.workspaceOccupied : Theme.colors.workspaceEmpty

                    ShapePath {
                        strokeWidth: -1
                        fillColor: dot.dotColor

                        PathRectangle {
                            x: (dot.width - width) / 2
                            y: (dot.height - height) / 2
                            width: dot.dotWidth
                            height: dot.dotHeight
                            radius: Math.min(width, height) / 2
                        }
                    }

                    Behavior on dotWidth {
                        NumberAnimation {
                            duration: Theme.animations.workspaceDuration
                            easing.type: Theme.animations.workspaceEasing
                            easing.bezierCurve: Theme.animations.workspaceCurve
                        }
                    }

                    Behavior on dotHeight {
                        NumberAnimation {
                            duration: Theme.animations.workspaceDuration
                            easing.type: Theme.animations.workspaceEasing
                            easing.bezierCurve: Theme.animations.workspaceCurve
                        }
                    }

                    Behavior on dotColor {
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
