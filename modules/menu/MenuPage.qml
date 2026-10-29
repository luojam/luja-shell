pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"

FocusScope {
    id: root

    property alias query: searchInput.text
    property alias searchObjectName: searchInput.objectName
    property alias listView: results
    property alias model: results.model
    property alias delegate: results.delegate
    property string placeholder: ""
    property string emptyMessage: ""
    property string errorMessage: ""

    signal accepted()
    signal searchKeyPressed(var event)

    function reset(): void {
        query = "";
        results.currentIndex = results.count > 0 ? 0 : -1;
        results.positionViewAtBeginning();
    }

    function activate(): void {
        searchInput.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.menu.sectionSpacing

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.menu.searchHeight
            radius: Theme.menu.rowRadius
            color: Qt.alpha(Theme.colors.menuBorder, 0.3)

            TextInput {
                id: searchInput

                anchors.fill: parent
                anchors.leftMargin: Theme.menu.rowPadding
                anchors.rightMargin: Theme.menu.rowPadding
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.colors.text
                selectionColor: Theme.colors.menuSelection
                selectedTextColor: Theme.colors.text
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.menuFontPointSize
                renderType: Theme.typography.textRenderType
                clip: true
                selectByMouse: true
                focus: true

                Keys.onUpPressed: results.moveSelection(-1)
                Keys.onDownPressed: results.moveSelection(1)
                Keys.onLeftPressed: event => {
                    if (text.length === 0)
                        results.movePage(-1);
                    else
                        event.accepted = false;
                }
                Keys.onRightPressed: event => {
                    if (text.length === 0)
                        results.movePage(1);
                    else
                        event.accepted = false;
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                        results.movePage(event.key === Qt.Key_PageUp ? -1 : 1);
                        event.accepted = true;
                    } else {
                        root.searchKeyPressed(event);
                    }
                }
                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: searchInput.text.length === 0
                    text: root.placeholder
                    color: Theme.colors.mutedText
                    font: searchInput.font
                    renderType: Theme.typography.textRenderType
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: results

                readonly property int pageSize: Math.max(1, Math.floor((height + spacing) / (Theme.menu.rowHeight + spacing)))

                anchors.fill: parent
                visible: root.errorMessage === ""
                spacing: Theme.menu.rowSpacing
                clip: true
                keyNavigationEnabled: false
                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.animations.menuHighlightDuration

                onModelChanged: {
                    currentIndex = count > 0 ? 0 : -1;
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
            }

            Text {
                anchors.centerIn: parent
                visible: root.errorMessage !== "" || results.count === 0
                text: root.errorMessage || root.emptyMessage
                color: Theme.colors.mutedText
                font.family: Theme.typography.fontFamily
                font.pointSize: Theme.typography.menuFontPointSize
                renderType: Theme.typography.textRenderType
            }
        }
    }
}
