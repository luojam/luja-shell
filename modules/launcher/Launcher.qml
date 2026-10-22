pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../helpers"

PanelWindow {
    id: root

    readonly property var applications: DesktopEntries.applications.values
    readonly property var filteredApplications: filterApplications(applications, searchInput.text)

    visible: false
    implicitWidth: Theme.launcher.width
    implicitHeight: Theme.launcher.height
    color: Theme.colors.transparent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "luja-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function filterApplications(entries: var, query: string): var {
        const term = query.trim().toLowerCase();
        return entries.map(entry => {
            const name = entry.name.toLowerCase();
            let rank = -1;
            if (!term || name === term)
                rank = 0;
            else if (name.startsWith(term))
                rank = 1;
            else if (name.includes(term))
                rank = 2;
            else if ((entry.genericName || "").toLowerCase().includes(term)
                     || (entry.keywords || []).some(keyword => keyword.toLowerCase().includes(term)))
                rank = 3;
            return { entry: entry, rank: rank };
        }).filter(match => match.rank >= 0)
          .sort((a, b) => a.rank - b.rank || a.entry.name.localeCompare(b.entry.name))
          .map(match => match.entry);
    }

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }

        const monitorName = Hyprland.focusedMonitor?.name ?? Config.preferredOutput;
        screen = Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0];
        searchInput.text = "";
        applicationsView.currentIndex = applicationsView.count > 0 ? 0 : -1;
        applicationsView.positionViewAtBeginning();
        visible = true;
        searchInput.forceActiveFocus();
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

        Rectangle {
            id: searchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.launcher.padding
            height: Theme.launcher.rowHeight
            radius: Theme.launcher.rowRadius
            color: Qt.alpha(Theme.colors.launcherBorder, 0.3)

            TextInput {
                id: searchInput
                objectName: "applicationSearch"

                anchors.fill: parent
                anchors.leftMargin: Theme.launcher.rowPadding
                anchors.rightMargin: Theme.launcher.rowPadding
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.colors.text
                selectionColor: Theme.colors.launcherSelection
                selectedTextColor: Theme.colors.text
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.launcherFontPointSize
                renderType: Theme.typography.textRenderType
                clip: true
                selectByMouse: true
                focus: true

                Keys.onUpPressed: applicationsView.moveSelection(-1)
                Keys.onDownPressed: applicationsView.moveSelection(1)
                Keys.onLeftPressed: event => {
                    if (text.length === 0)
                        applicationsView.movePage(-1);
                    else
                        event.accepted = false;
                }
                Keys.onRightPressed: event => {
                    if (text.length === 0)
                        applicationsView.movePage(1);
                    else
                        event.accepted = false;
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                        applicationsView.movePage(event.key === Qt.Key_PageUp ? -1 : 1);
                        event.accepted = true;
                    }
                }
                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.launch(root.filteredApplications[applicationsView.currentIndex] ?? null)
                Keys.onEnterPressed: root.launch(root.filteredApplications[applicationsView.currentIndex] ?? null)

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: searchInput.text.length === 0
                    text: "Search applications…"
                    color: Theme.colors.mutedText
                    font: searchInput.font
                    renderType: Theme.typography.textRenderType
                }
            }
        }

        ListView {
            id: applicationsView
            objectName: "applications"

            readonly property int rowHeight: Theme.launcher.rowHeight
            readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing)))

            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.launcher.padding
            anchors.topMargin: Theme.launcher.rowPadding
            model: root.filteredApplications
            spacing: Theme.launcher.rowSpacing
            clip: true
            keyNavigationEnabled: false
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.animations.launcherHighlightDuration

            onModelChanged: {
                currentIndex = root.filteredApplications.length > 0 ? 0 : -1;
                positionViewAtBeginning();
            }

            function moveSelection(direction: int): void {
                if (count === 0)
                    return;

                currentIndex = Math.max(0, Math.min(count - 1, currentIndex + direction));
                positionViewAtIndex(currentIndex, ListView.Contain);
            }

            function movePage(direction: int): void {
                if (count === 0)
                    return;

                currentIndex = Math.max(0, Math.min(count - 1, currentIndex + direction * pageSize));
                positionViewAtIndex(Math.floor(currentIndex / pageSize) * pageSize, ListView.Beginning);
            }

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
            anchors.centerIn: applicationsView
            visible: applicationsView.count === 0
            text: searchInput.text.trim() ? "No matching applications" : "No applications found"
            color: Theme.colors.mutedText
            font.family: Theme.typography.fontFamily
            font.pointSize: Theme.typography.launcherFontPointSize
            renderType: Theme.typography.textRenderType
        }
    }
}
