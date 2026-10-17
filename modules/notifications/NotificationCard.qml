pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../../config"

Rectangle {
    id: root

    required property Notification notification
    property bool timeoutEnabled: true
    readonly property var actions: notification?.actions ?? []
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property int timeout: critical ? 0 : (notification?.expireTimeout < 0 ? Config.notificationTimeout : notification?.expireTimeout ?? 0)
    readonly property var buttons: actions.filter(action => action.identifier !== "default")

    implicitHeight: content.implicitHeight + Theme.notifications.padding * 2
    radius: Theme.notifications.radius
    color: Theme.colors.launcherBackground
    border.width: Theme.notifications.borderWidth
    border.color: critical ? Theme.colors.critical : Theme.colors.accent

    function activate(): void {
        const action = actions.find(action => action.identifier === "default");
        if (action)
            action.invoke();
        else
            notification?.dismiss();
    }

    function restartTimeout(): void {
        if (expiry.running)
            expiry.restart();
    }

    Timer {
        id: expiry

        interval: Math.max(1, root.timeout)
        running: root.visible && root.timeoutEnabled && root.timeout > 0 && !hover.hovered
        onTriggered: root.notification?.expire()
    }

    Connections {
        target: root.notification

        function onSummaryChanged() { root.restartTimeout(); }
        function onBodyChanged() { root.restartTimeout(); }
        function onImageChanged() { root.restartTimeout(); }
        function onAppIconChanged() { root.restartTimeout(); }
        function onActionsChanged() { root.restartTimeout(); }
        function onHintsChanged() { root.restartTimeout(); }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.activate();
            else
                root.notification?.dismiss();
        }
    }

    Column {
        id: content

        x: Theme.notifications.padding
        y: Theme.notifications.padding
        width: parent.width - Theme.notifications.padding * 2
        spacing: Theme.notifications.spacing

        Row {
            width: parent.width
            spacing: Theme.notifications.padding

            Image {
                id: icon

                readonly property string iconName: root.notification?.appIcon ?? ""
                readonly property string imagePath: root.notification?.image ?? ""

                width: Theme.notifications.iconSize
                height: width
                visible: source.toString().length > 0 && status !== Image.Error
                source: imagePath || (iconName ? (iconName.startsWith("/") || iconName.includes(":") ? iconName : Quickshell.iconPath(iconName)) : "")
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
            }

            Column {
                width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
                spacing: Theme.notifications.spacing

                Text {
                    width: parent.width
                    text: root.notification?.summary || root.notification?.appName || ""
                    textFormat: Text.PlainText
                    color: Theme.colors.text
                    font.family: Theme.typography.fontFamily
                    font.pointSize: Theme.typography.notificationFontPointSize
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    renderType: Theme.typography.textRenderType
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    color: Theme.colors.text
                    font.family: Theme.typography.fontFamily
                    font.pointSize: Theme.typography.notificationFontPointSize
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    renderType: Theme.typography.textRenderType
                }
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.notifications.spacing
            visible: root.buttons.length > 0

            Repeater {
                model: root.buttons

                delegate: Rectangle {
                    id: button

                    required property NotificationAction modelData

                    width: Math.min(content.width, label.implicitWidth + Theme.notifications.padding * 2)
                    height: label.implicitHeight + Theme.notifications.spacing * 2
                    radius: Theme.notifications.spacing
                    color: mouse.containsMouse ? Theme.colors.launcherSelection : Theme.colors.transparent
                    border.color: Theme.colors.accent

                    Connections {
                        target: button.modelData

                        function onTextChanged() { root.restartTimeout(); }
                    }

                    Text {
                        id: label

                        anchors.centerIn: parent
                        width: parent.width - Theme.notifications.padding * 2
                        text: button.modelData.text
                        textFormat: Text.PlainText
                        color: Theme.colors.text
                        font.family: Theme.typography.fontFamily
                        font.pointSize: Theme.typography.notificationFontPointSize
                        elide: Text.ElideRight
                        renderType: Theme.typography.textRenderType
                    }

                    MouseArea {
                        id: mouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: button.modelData.invoke()
                    }
                }
            }
        }
    }
}
