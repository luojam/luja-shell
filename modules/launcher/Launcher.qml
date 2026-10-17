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
    implicitWidth: Theme.launcher.width
    implicitHeight: Theme.launcher.height
    color: Theme.colors.transparent
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
        color: Theme.colors.launcherBackground
        border.color: Theme.colors.launcherBorder
        radius: Theme.launcher.radius

        ListView {
            id: applicationsView
            objectName: "applications"

            readonly property int rowHeight: Theme.launcher.rowHeight
            readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing)))

            anchors.fill: parent
            anchors.margins: Theme.launcher.padding
            model: root.applications
            spacing: Theme.launcher.rowSpacing
            clip: true
            focus: true
            keyNavigationEnabled: true
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.animations.launcherHighlightDuration

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
                radius: Theme.launcher.rowRadius
                color: ListView.isCurrentItem ? Theme.colors.launcherSelection : Theme.colors.transparent

                Image {
                    id: icon

                    readonly property string iconName: row.modelData.icon || "application-x-executable"

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.launcher.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.launcher.iconSize
                    height: Theme.launcher.iconSize
                    // Use the installed PNG sizes to avoid Qt's SVG clipping limitations.
                    sourceSize.width: iconName === "application-x-executable" ? 16 : 128
                    sourceSize.height: iconName === "application-x-executable" ? 16 : 128
                    source: Quickshell.iconPath(iconName, "application-x-executable")
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                Text {
                    anchors.left: icon.right
                    anchors.leftMargin: Theme.launcher.rowPadding
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.launcher.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    textFormat: Text.PlainText
                    color: Theme.colors.text
                    font.family: Theme.typography.fontFamily
                    font.pointSize: Theme.typography.launcherFontPointSize
                    elide: Text.ElideRight
                    renderType: Theme.typography.textRenderType
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
            color: Theme.colors.mutedText
            font.family: Theme.typography.fontFamily
            font.pointSize: Theme.typography.launcherFontPointSize
        }
    }
}
