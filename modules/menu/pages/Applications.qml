pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../../config"
import "../../../helpers"
import ".."

FocusScope {
    id: root

    readonly property var applications: DesktopEntries.applications.values
    readonly property var filteredApplications: filterApplications(applications, page.query)

    signal closeRequested()

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

    function reset(): void {
        page.reset();
    }

    function activate(): void {
        page.activate();
    }

    function launch(entry: DesktopEntry): void {
        if (!entry)
            return;

        closeRequested();
        if (entry.runInTerminal) {
            Ghostty.launch(entry.command, {
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
    }

    MenuPage {
        id: page

        anchors.fill: parent
        searchObjectName: "applicationSearch"
        listView.objectName: "applications"
        placeholder: "Search applications…"
        model: root.filteredApplications
        emptyMessage: query.trim() ? "No matching applications" : "No applications found"
        onAccepted: root.launch(root.filteredApplications[listView.currentIndex] ?? null)

        delegate: Rectangle {
            id: row

            required property DesktopEntry modelData
            required property int index

            width: page.listView.width
            height: Theme.menu.rowHeight
            radius: Theme.menu.rowRadius
            color: ListView.isCurrentItem ? Theme.colors.menuSelection : Theme.colors.transparent

            Image {
                id: icon

                readonly property string iconName: row.modelData.icon || "application-x-executable"

                anchors.left: parent.left
                anchors.leftMargin: Theme.menu.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.menu.iconSize
                height: Theme.menu.iconSize
                // Use the installed PNG sizes to avoid Qt's SVG clipping limitations.
                sourceSize.width: iconName === "application-x-executable" ? 16 : 128
                sourceSize.height: iconName === "application-x-executable" ? 16 : 128
                source: Quickshell.iconPath(iconName, "application-x-executable")
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            Text {
                anchors.left: icon.right
                anchors.leftMargin: Theme.menu.rowPadding
                anchors.right: parent.right
                anchors.rightMargin: Theme.menu.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                textFormat: Text.PlainText
                color: Theme.colors.text
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.menuFontPointSize
                elide: Text.ElideRight
                renderType: Theme.typography.textRenderType
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    page.listView.currentIndex = row.index;
                    root.launch(row.modelData);
                }
            }
        }
    }
}
