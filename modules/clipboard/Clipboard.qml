pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../config"

PanelWindow {
    id: root

    property var entries: []
    property string errorMessage: ""
    property string currentEntryId: ""
    property int currentRevision: 0
    readonly property var filteredEntries: filterEntries(entries, searchInput.text)
    readonly property string helperPath: Quickshell.shellPath("modules/clipboard/clipboard.sh")

    visible: false
    implicitWidth: Theme.launcher.width
    implicitHeight: Theme.launcher.height
    color: Theme.colors.transparent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "luja-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (!visible)
            invalidateCurrent();
    }

    function invalidateCurrent(): void {
        currentEntryId = "";
        currentRevision++;
    }

    function refreshCurrent(): void {
        if (!visible || process.running || currentProcess.running || entries.length === 0)
            return;

        currentProcess.revision = currentRevision;
        currentProcess.exec(["bash", helperPath, "current"]);
    }

    function filterEntries(history: var, query: string): var {
        const term = query.trim().toLowerCase();
        if (!term)
            return history;

        return history.filter(entry => entry.preview.toLowerCase().includes(term));
    }

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }

        const monitorName = Hyprland.focusedMonitor?.name ?? Config.preferredOutput;
        screen = Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0];
        entries = [];
        searchInput.text = "";
        clipboardView.currentIndex = -1;
        clipboardView.positionViewAtBeginning();
        visible = true;
        refresh();
        searchInput.forceActiveFocus();
    }

    function refresh(): void {
        if (process.running)
            return;

        errorMessage = "";
        invalidateCurrent();
        process.action = "list";
        process.exec(["bash", helperPath, "list"]);
    }

    function parseEntries(text: string): var {
        return text.split("\n").filter(line => line.indexOf("\t") > 0).map(line => {
            const separator = line.indexOf("\t");
            return {
                id: line.slice(0, separator),
                preview: line.slice(separator + 1),
                pinned: line.startsWith("pin:")
            };
        });
    }

    function updateEntries(text: string): void {
        const index = clipboardView.currentIndex;
        const selectedId = filteredEntries[index]?.id ?? "";
        entries = parseEntries(text);
        clipboardView.restoreSelection(selectedId, index);
    }

    function perform(action: string): void {
        const entry = filteredEntries[clipboardView.currentIndex];
        if (!entry || process.running || (action === "delete" && entry.pinned))
            return;

        errorMessage = "";
        invalidateCurrent();
        process.action = action;
        process.exec(["bash", helperPath, action, entry.id]);
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
    }

    Process {
        id: process

        property string action: ""

        stdout: StdioCollector {
            id: output
        }
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.errorMessage = action === "list" ? "Could not load clipboard history" : "Clipboard action failed";
                Qt.callLater(root.refreshCurrent);
                return;
            }

            if (action === "list") {
                root.updateEntries(output.text);
                Qt.callLater(root.refreshCurrent);
            } else if (action === "copy") {
                root.visible = false;
            } else if (root.visible) {
                Qt.callLater(root.refresh);
            }
        }
    }

    Process {
        id: currentProcess

        property int revision: -1

        stdout: StdioCollector {
            id: currentOutput
        }
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (revision !== root.currentRevision) {
                Qt.callLater(root.refreshCurrent);
                return;
            }

            if (root.visible && exitCode === 0 && exitStatus === 0)
                root.currentEntryId = currentOutput.text.trim();
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
                objectName: "clipboardSearch"

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

                Keys.onUpPressed: clipboardView.moveSelection(-1)
                Keys.onDownPressed: clipboardView.moveSelection(1)
                Keys.onLeftPressed: event => {
                    if (text.length === 0)
                        clipboardView.movePage(-1);
                    else
                        event.accepted = false;
                }
                Keys.onRightPressed: event => {
                    if (text.length === 0)
                        clipboardView.movePage(1);
                    else
                        event.accepted = false;
                }
                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.perform("copy")
                Keys.onEnterPressed: root.perform("copy")
                Keys.onDeletePressed: event => {
                    if (text.length === 0 || (event.modifiers & Qt.AltModifier))
                        root.perform("delete");
                    else
                        event.accepted = false;
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                        clipboardView.movePage(event.key === Qt.Key_PageUp ? -1 : 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_P && (event.modifiers & Qt.AltModifier)) {
                        root.perform("pin");
                        event.accepted = true;
                    }
                }

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: searchInput.text.length === 0
                    text: "Search clipboard history…"
                    color: Theme.colors.mutedText
                    font: searchInput.font
                    renderType: Theme.typography.textRenderType
                }
            }
        }

        ListView {
            id: clipboardView
            objectName: "clipboardEntries"

            readonly property int rowHeight: Theme.launcher.rowHeight
            readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing)))

            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.launcher.padding
            anchors.topMargin: Theme.launcher.rowPadding
            model: root.filteredEntries
            spacing: Theme.launcher.rowSpacing
            clip: true
            keyNavigationEnabled: false
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.animations.launcherHighlightDuration

            onModelChanged: {
                currentIndex = root.filteredEntries.length > 0 ? 0 : -1;
                positionViewAtBeginning();
            }

            function restoreSelection(id: string, previousIndex: int): void {
                if (count === 0) {
                    currentIndex = -1;
                    return;
                }

                const index = root.filteredEntries.findIndex(entry => entry.id === id);
                currentIndex = index >= 0 ? index : Math.max(0, Math.min(previousIndex, count - 1));
                positionViewAtIndex(currentIndex, ListView.Contain);
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

                required property var modelData
                required property int index

                width: clipboardView.width
                height: clipboardView.rowHeight
                radius: Theme.launcher.rowRadius
                color: ListView.isCurrentItem ? Theme.colors.launcherSelection : Theme.colors.transparent

                Row {
                    id: statusIcons

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.launcher.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        objectName: "clipboardCurrentIndicator"

                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.id === root.currentEntryId
                        text: "\uf0ea"
                        color: Theme.colors.accent
                        font.family: Theme.typography.iconFontFamily
                        font.pointSize: Theme.typography.launcherFontPointSize
                        renderType: Theme.typography.textRenderType
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.pinned
                        text: "★"
                        color: Theme.colors.clipboardPinned
                        font.family: Theme.typography.fontFamily
                        font.pointSize: Theme.typography.launcherFontPointSize
                        renderType: Theme.typography.textRenderType
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.launcher.rowPadding + (statusIcons.width > 0 ? statusIcons.width + 6 : 0)
                    anchors.rightMargin: Theme.launcher.rowPadding
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.preview
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
                        clipboardView.currentIndex = row.index;
                        root.perform("copy");
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: clipboardView
            visible: root.errorMessage !== "" || clipboardView.count === 0
            color: Theme.colors.launcherBackground

            Text {
                anchors.centerIn: parent
                text: {
                    if (root.errorMessage)
                        return root.errorMessage;
                    if (process.running)
                        return "Loading clipboard history…";
                    if (searchInput.text.trim())
                        return "No matching clipboard entries";
                    return "Clipboard history is empty";
                }
                color: Theme.colors.mutedText
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.launcherFontPointSize
            }
        }
    }
}
