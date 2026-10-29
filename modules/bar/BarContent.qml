pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../config"

Row {
    id: root

    required property ShellScreen screen
    required property real expansion

    readonly property bool volumeFeedback: volume.recentlyChanged || volume.muted
    readonly property bool expandedContentVisible: expansion > 0
    readonly property bool expandedContentInteractive: expansion === 1
    readonly property bool volumeVisible: expandedContentVisible || volumeFeedback
    readonly property bool volumeInteractive: expandedContentInteractive || volumeFeedback

    readonly property rect coreBounds: Qt.rect(core.x, core.y, core.width, core.height)
    readonly property list<rect> collapsedPills: {
        const pills = [
            Qt.rect(core.x + clock.x, core.y + clock.y, clock.width, clock.height),
            Qt.rect(core.x + workspaces.x, core.y + workspaces.y, workspaces.width, workspaces.height)
        ];
        if (root.volumeFeedback)
            pills.push(Qt.rect(volumeSlot.x, volumeSlot.y, volumeSlot.width, volumeSlot.height));
        return pills;
    }

    height: Theme.bar.widgetHeight
    spacing: Theme.bar.spacing

    // Slots retain their geometry while the surface reveals their content.
    Item {
        width: date.implicitWidth
        height: root.height

        DateDisplay {
            id: date

            color: Theme.colors.transparent
            visible: root.expandedContentVisible
            enabled: root.expandedContentInteractive
        }
    }

    Row {
        id: core

        spacing: Theme.bar.spacing

        Clock {
            id: clock
            color: Theme.colors.transparent
        }

        Workspaces {
            id: workspaces
            screen: root.screen
            color: Theme.colors.transparent
        }
    }

    Item {
        id: volumeSlot

        width: volume.implicitWidth
        height: root.height

        Volume {
            id: volume

            color: Theme.colors.transparent
            visible: root.volumeVisible
            enabled: root.volumeInteractive
            detailProgress: volume.muted ? root.expansion : 1
        }
    }

    Item {
        width: tray.implicitWidth
        height: root.height
        visible: tray.hasItems

        Tray {
            id: tray

            color: Theme.colors.transparent
            visible: root.expandedContentVisible
            enabled: root.expandedContentInteractive
        }
    }
}
