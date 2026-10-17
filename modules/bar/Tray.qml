pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    implicitWidth: trayRow.implicitWidth + 10
    implicitHeight: 20
    visible: SystemTray.items.values.length > 0
    radius: 10
    color: Qt.rgba(28 / 255, 28 / 255, 28 / 255, 0.75)

    SystemPalette {
        id: systemPalette
    }

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: 20
                height: 20

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
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
                    palette.toolTipText: systemPalette.windowText

                    background: Rectangle {
                        color: systemPalette.window
                        border.color: systemPalette.dark
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
