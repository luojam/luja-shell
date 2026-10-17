pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"

PanelWindow {
    id: root

    readonly property var applications: DesktopEntries.applications.values.slice().sort((a, b) => a.name.localeCompare(b.name))

    visible: false
    implicitWidth: 580
    implicitHeight: 452
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "luja-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }

        const monitorName = Hyprland.focusedMonitor?.name ?? Config.preferredOutput;
        screen = Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0];
        applicationsView.currentIndex = applicationsView.count > 0 ? 0 : -1;
        applicationsView.positionViewAtBeginning();
        visible = true;
        applicationsView.forceActiveFocus();
    }

    function launch(entry: DesktopEntry): void {
        if (!entry)
            return;

        visible = false;
        if (entry.runInTerminal) {
            Ghostty.launch(entry.command, {
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(30 / 255, 30 / 255, 46 / 255, 0.75)
        border.color: "#45475a"
        radius: 16

        ListView {
            id: applicationsView
            objectName: "applications"

            readonly property int rowHeight: 44
            readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing)))

            anchors.fill: parent
            anchors.margins: 20
            model: root.applications
            spacing: 2
            clip: true
            focus: true
            keyNavigationEnabled: true
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0

            function movePage(direction: int): void {
                if (count === 0)
                    return;

                currentIndex = Math.max(0, Math.min(count - 1, currentIndex + direction * pageSize));
                positionViewAtIndex(Math.floor(currentIndex / pageSize) * pageSize, ListView.Beginning);
            }

            Keys.onLeftPressed: movePage(-1)
            Keys.onRightPressed: movePage(1)
            Keys.onEscapePressed: root.visible = false
            Keys.onReturnPressed: root.launch(root.applications[currentIndex] ?? null)
            Keys.onEnterPressed: root.launch(root.applications[currentIndex] ?? null)

            delegate: Rectangle {
                id: row

                required property DesktopEntry modelData
                required property int index

                width: applicationsView.width
                height: applicationsView.rowHeight
                radius: 8
                color: ListView.isCurrentItem ? Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.18) : "transparent"

                Image {
                    id: icon

                    readonly property string iconName: row.modelData.icon || "application-x-executable"

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    // Use the installed PNG sizes to avoid Qt's SVG clipping limitations.
                    sourceSize.width: iconName === "application-x-executable" ? 16 : 128
                    sourceSize.height: iconName === "application-x-executable" ? 16 : 128
                    source: Quickshell.iconPath(iconName, "application-x-executable")
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                Text {
                    anchors.left: icon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    textFormat: Text.PlainText
                    color: "#cdd6f4"
                    font.family: "Adwaita Sans"
                    font.pointSize: 14
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        applicationsView.currentIndex = row.index;
                        root.launch(row.modelData);
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: applicationsView.count === 0
            text: "No applications found"
            color: "#9399b2"
            font.family: "Adwaita Sans"
            font.pointSize: 14
        }
    }
}
