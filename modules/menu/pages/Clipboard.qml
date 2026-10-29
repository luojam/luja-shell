pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"
import ".."

FocusScope {
    id: root

    property var entries: []
    property string errorMessage: ""
    property string currentEntryId: ""
    property int currentRevision: 0
    readonly property var filteredEntries: filterEntries(entries, page.query)
    readonly property string helperPath: Quickshell.shellPath("modules/menu/pages/clipboard.sh")

    signal closeRequested()

    // Prevent a pending copy from closing a later page activation.
    property int openRevision: 0

    onVisibleChanged: {
        if (!visible) {
            openRevision++;
            invalidateCurrent();
        }
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

    function reset(): void {
        openRevision++;
        entries = [];
        page.reset();
    }

    function activate(): void {
        refresh();
        page.activate();
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
            const preview = line.slice(separator + 1);
            const image = /^\[\[ binary data (.+) (png|jpeg|gif|bmp|tiff|webp) (\d+)x(\d+) \]\]$/.exec(preview);
            return {
                id: line.slice(0, separator),
                preview: preview,
                image: image ? { size: image[1], format: image[2], width: image[3], height: image[4] } : null,
                pinned: line.startsWith("pin:")
            };
        });
    }

    function updateEntries(text: string): void {
        const previousIndex = page.listView.currentIndex;
        const selectedId = filteredEntries[previousIndex]?.id ?? "";
        entries = parseEntries(text);
        if (filteredEntries.length === 0) {
            page.listView.currentIndex = -1;
            return;
        }

        const index = filteredEntries.findIndex(entry => entry.id === selectedId);
        page.listView.currentIndex = index >= 0 ? index : Math.max(0, Math.min(previousIndex, filteredEntries.length - 1));
        page.listView.positionViewAtIndex(page.listView.currentIndex, ListView.Contain);
    }

    function perform(action: string): void {
        const entry = filteredEntries[page.listView.currentIndex];
        if (!entry || errorMessage !== "" || process.running || (action === "delete" && entry.pinned))
            return;

        errorMessage = "";
        invalidateCurrent();
        process.action = action;
        process.openRevision = openRevision;
        process.exec(["bash", helperPath, action, entry.id]);
    }

    Process {
        id: process

        property string action: ""
        property int openRevision: -1

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
            } else if (action === "copy" && root.visible && openRevision === root.openRevision) {
                root.closeRequested();
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

    MenuPage {
        id: page

        anchors.fill: parent
        searchObjectName: "clipboardSearch"
        listView.objectName: "clipboardEntries"
        placeholder: "Search clipboard history…"
        model: root.filteredEntries
        entryHeight: index => root.filteredEntries[index]?.image ? Theme.menu.clipboardImageRowHeight : Theme.menu.rowHeight
        errorMessage: root.errorMessage
        emptyMessage: {
            if (process.running)
                return "Loading clipboard history…";
            if (query.trim())
                return "No matching clipboard entries";
            return "Clipboard history is empty";
        }
        onAccepted: root.perform("copy")
        onSearchKeyPressed: event => {
            if (event.key === Qt.Key_Delete && (query.length === 0 || (event.modifiers & Qt.AltModifier))) {
                root.perform("delete");
                event.accepted = true;
            } else if (event.key === Qt.Key_P && (event.modifiers & Qt.AltModifier)) {
                root.perform("pin");
                event.accepted = true;
            }
        }

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            width: page.listView.width
            height: page.entryHeight(index)
            radius: Theme.menu.rowRadius
            color: ListView.isCurrentItem ? Theme.colors.menuSelection : Theme.colors.transparent

            Row {
                id: statusIcons

                anchors.left: parent.left
                anchors.leftMargin: Theme.menu.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    objectName: "clipboardCurrentIndicator"

                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.id === root.currentEntryId
                    text: "\uf0ea"
                    color: Theme.colors.accent
                    font.family: Theme.typography.iconFontFamily
                    font.pointSize: Theme.typography.menuFontPointSize
                    renderType: Theme.typography.textRenderType
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.pinned
                    text: "★"
                    color: Theme.colors.clipboardPinned
                    font.family: Theme.typography.fontFamily
                    font.pointSize: Theme.typography.menuFontPointSize
                    renderType: Theme.typography.textRenderType
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: Theme.menu.rowPadding + (statusIcons.width > 0 ? statusIcons.width + 6 : 0)
                anchors.rightMargin: Theme.menu.rowPadding

                Loader {
                    id: imagePreview

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Theme.menu.rowPadding
                    anchors.bottomMargin: Theme.menu.rowPadding
                    width: parent.width * 0.6
                    active: root.visible && row.modelData.image !== null
                    sourceComponent: ClipboardImage {
                        entryId: row.modelData.id
                        helperPath: root.helperPath
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: row.modelData.image ? (imagePreview.item?.previewWidth ?? imagePreview.width) + Theme.menu.rowPadding : 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    verticalAlignment: Text.AlignVCenter
                    text: {
                        const image = row.modelData.image;
                        return image ? image.format.toUpperCase() + " · " + image.width + " × " + image.height + " · " + image.size : row.modelData.preview;
                    }
                    textFormat: Text.PlainText
                    color: Theme.colors.text
                    font.family: Theme.typography.fontFamily
                    font.pointSize: Theme.typography.menuFontPointSize
                    elide: Text.ElideRight
                    renderType: Theme.typography.textRenderType
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    page.listView.currentIndex = row.index;
                    root.perform("copy");
                }
            }
        }
    }
}
