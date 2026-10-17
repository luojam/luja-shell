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
    readonly property string helperPath: Quickshell.shellPath("modules/clipboard/clipboard.sh")

    visible: false
    implicitWidth: Theme.launcher.width
    implicitHeight: Theme.launcher.height
    color: Theme.colors.transparent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "luja-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }

        const monitorName = Hyprland.focusedMonitor?.name ?? Config.preferredOutput;
        screen = Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0];
        entries = [];
        clipboardView.currentIndex = -1;
        visible = true;
        refresh();
        clipboardView.forceActiveFocus();
    }

    function refresh(): void {
        if (process.running)
            return;

        errorMessage = "";
        process.action = "list";
        process.exec(["bash", helperPath, "list"]);
    }

    function perform(action: string): void {
        const entry = entries[clipboardView.currentIndex];
        if (!entry || process.running || (action === "delete" && entry.pinned))
            return;

        errorMessage = "";
        process.action = action;
        process.exec(["bash", helperPath, action, entry.line]);
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
                return;
            }

            if (action === "list") {
                const index = clipboardView.currentIndex;
                root.entries = output.text.split("\n").filter(line => line.indexOf("\t") > 0).map(line => ({
                    line: line,
                    preview: line.slice(line.indexOf("\t") + 1),
                    pinned: line.startsWith("pin:")
                }));
                clipboardView.currentIndex = root.entries.length > 0 ? Math.max(0, Math.min(index, root.entries.length - 1)) : -1;
                clipboardView.positionViewAtIndex(clipboardView.currentIndex, ListView.Contain);
            } else if (action === "copy") {
                root.visible = false;
            } else if (root.visible) {
                Qt.callLater(root.refresh);
            }
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
            id: clipboardView
            objectName: "clipboardEntries"

            readonly property int rowHeight: Theme.launcher.rowHeight
            readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing)))

            anchors.fill: parent
            anchors.margins: Theme.launcher.padding
            model: root.entries
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
            Keys.onReturnPressed: root.perform("copy")
            Keys.onEnterPressed: root.perform("copy")
            Keys.onDeletePressed: root.perform("delete")
            Keys.onPressed: event => {
                if (event.key === Qt.Key_P && (event.modifiers & Qt.AltModifier)) {
                    root.perform("pin");
                    event.accepted = true;
                }
            }

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                width: clipboardView.width
                height: clipboardView.rowHeight
                radius: Theme.launcher.rowRadius
                color: ListView.isCurrentItem ? Theme.colors.launcherSelection : Theme.colors.transparent

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.launcher.rowPadding
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
            anchors.fill: parent
            anchors.margins: Theme.launcher.padding
            visible: root.errorMessage !== "" || clipboardView.count === 0
            color: Theme.colors.launcherBackground

            Text {
                anchors.centerIn: parent
                text: root.errorMessage || (process.running ? "Loading clipboard history…" : "Clipboard history is empty")
                color: Theme.colors.mutedText
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.launcherFontPointSize
            }
        }
    }
}
