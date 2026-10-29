pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
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
        property real expansion: expanded ? 1 : 0

        Behavior on expansion {
            NumberAnimation {
                duration: Theme.animations.barDuration
                easing.type: Easing.InOutCubic
            }
        }

        screen: modelData
        implicitHeight: Theme.bar.height
        color: Theme.colors.transparent
        WlrLayershell.namespace: 'luja-bar'

        anchors {
            top: true
            left: true
            right: true
        }

        IpcHandler {
            target: "bar"

            function toggle(): void {
                bar.expanded = !bar.expanded;
            }
        }

        BarSurface {
            id: surface

            x: (parent.width - content.coreBounds.width) / 2 - content.coreBounds.x
            anchors.verticalCenter: parent.verticalCenter
            width: content.width
            height: bar.height
            collapsedHeight: content.height
            radius: Theme.bar.widgetRadius
            color: Theme.colors.barBackground
            expansion: bar.expansion
            collapsedPills: content.collapsedPills
            expansionOrigin: content.coreBounds.x + content.coreBounds.width / 2

            BarContent {
                id: content

                y: surface.contentOffset
                screen: bar.screen
                expansion: bar.expansion
            }
        }
    }
}
