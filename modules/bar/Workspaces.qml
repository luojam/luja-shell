pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    implicitWidth: workspaceRow.implicitWidth + 10
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

                width: 18
                height: 18
                visible: root.monitor !== null && modelData.monitor === root.monitor && !modelData.name.startsWith("special:")

                Shape {
                    id: dot

                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    property real dotWidth: indicator.modelData.active ? 16 : (indicator.occupied || indicator.modelData.urgent ? 8 : 6)
                    property real dotHeight: indicator.modelData.active ? 12 : (indicator.occupied || indicator.modelData.urgent ? 8 : 6)
                    property color dotColor: indicator.modelData.active ? "#89b4fa" : indicator.modelData.urgent ? "#f38ba8" : indicator.occupied ? "#bac2de" : "#585b70"

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
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.25, 0.25, 0.75, 1, 1, 1]
                        }
                    }

                    Behavior on dotHeight {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.25, 0.25, 0.75, 1, 1, 1]
                        }
                    }

                    Behavior on dotColor {
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
