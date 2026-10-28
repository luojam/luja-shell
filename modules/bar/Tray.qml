pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../../config"

Rectangle {
    id: root

    readonly property bool hasItems: SystemTray.items.values.length > 0

    implicitWidth: trayRow.implicitWidth + Theme.bar.trayPadding * 2
    implicitHeight: Theme.bar.widgetHeight
    radius: Theme.bar.widgetRadius
    color: Theme.colors.barBackground

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: Theme.bar.spacing

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: Theme.bar.trayItemSize
                height: Theme.bar.trayItemSize

                Image {
                    anchors.centerIn: parent
                    width: Theme.bar.trayIconSize
                    height: Theme.bar.trayIconSize
                    source: trayItem.modelData.icon
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                }

                QsMenuAnchor {
                    id: menu

                    menu: trayItem.modelData.menu
                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                }

                ToolTip {
                    visible: mouse.containsMouse && !menu.visible && text.length > 0
                    delay: 500
                    text: trayItem.modelData.tooltipTitle || trayItem.modelData.title || trayItem.modelData.id
                    popupType: Popup.Window
                    palette.toolTipText: Theme.colors.tooltipText

                    background: Rectangle {
                        color: Theme.colors.tooltipBackground
                        border.color: Theme.colors.tooltipBorder
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && trayItem.modelData.onlyMenu)) {
                            if (trayItem.modelData.hasMenu)
                                menu.open();
                        } else if (event.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate();
                        } else {
                            trayItem.modelData.activate();
                        }
                    }
                    onWheel: event => {
                        if (event.angleDelta.y !== 0)
                            trayItem.modelData.scroll(event.angleDelta.y, false);
                        if (event.angleDelta.x !== 0)
                            trayItem.modelData.scroll(event.angleDelta.x, true);
                    }
                }
            }
        }
    }
}
