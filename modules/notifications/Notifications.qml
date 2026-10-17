pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../config"

PanelWindow {
    id: root

    readonly property var notifications: server.trackedNotifications.values

    screen: Quickshell.screens.find(s => s.name === Config.preferredOutput) ?? Quickshell.screens[0]
    visible: notifications.length > 0
    implicitWidth: Theme.notifications.width
    implicitHeight: Math.min(stack.implicitHeight, Math.max(1, (screen?.height ?? 0) - Theme.bar.height - Theme.notifications.margin * 2))
    color: Theme.colors.transparent
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.notifications.margin
        right: Theme.notifications.margin
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: notification => notification.tracked = true
    }

    IpcHandler {
        target: "notifications"

        function dismiss(): void {
            root.notifications[0]?.dismiss();
        }

        function dismissAll(): void {
            for (const notification of root.notifications.slice())
                notification.dismiss();
        }
    }

    Flickable {
        id: viewport

        anchors.fill: parent
        contentHeight: stack.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        Column {
            id: stack

            width: viewport.width
            spacing: Theme.notifications.margin

            Repeater {
                model: server.trackedNotifications

                delegate: NotificationCard {
                    required property Notification modelData
                    required property int index

                    width: stack.width
                    visible: index < Config.maxVisibleNotifications
                    timeoutEnabled: height > viewport.height
                        ? y < viewport.contentY + viewport.height && y + height > viewport.contentY
                        : y >= viewport.contentY && y + height <= viewport.contentY + viewport.height
                    notification: modelData
                }
            }
        }
    }
}
