pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../config"

FocusScope {
    id: root

    readonly property bool copied: copiedTimer.running

    signal closeRequested

    function reset(): void {
        input.clear();
        copiedTimer.stop();
    }

    function activate(): void {
        input.forceActiveFocus();
    }

    function copyResult(): void {
        if (engine.result) {
            Quickshell.clipboardText = engine.result;
            copiedTimer.restart();
        }
    }

    onVisibleChanged: copiedTimer.stop()

    CalculatorEngine {
        id: engine
        active: root.visible
        expression: input.text
    }

    Timer {
        id: copiedTimer
        interval: 2000
    }

    Shortcut {
        sequence: "Ctrl+L"
        enabled: root.visible
        onActivated: {
            root.reset();
            root.activate();
        }
    }

    component Label: Text {
        color: Theme.colors.text
        font.family: Theme.typography.fontFamily
        font.pointSize: Theme.typography.menuFontPointSize
        textFormat: Text.PlainText
        renderType: Theme.typography.textRenderType
    }

    component Keycap: Rectangle {
        property alias text: keyLabel.text

        implicitWidth: keyLabel.implicitWidth + 12
        implicitHeight: keyLabel.implicitHeight + 6
        radius: 4
        color: Qt.alpha(Theme.colors.menuBorder, 0.15)
        border.color: Theme.colors.menuBorder

        Label {
            id: keyLabel
            anchors.centerIn: parent
            font.pointSize: 10
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.menu.padding

        RowLayout {
            spacing: Theme.menu.rowPadding
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            Layout.bottomMargin: 8

            Label {
                text: "\uf1ec"
                font.family: Theme.typography.iconFontFamily
                font.pointSize: 20
                color: Theme.colors.mutedText
                Accessible.ignored: true
            }

            Label {
                text: "Calculator"
                font.pointSize: 22
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.menu.searchHeight + 8
            radius: Theme.menu.rowRadius
            color: Qt.alpha(Theme.colors.menuBorder, 0.3)
            border.color: input.activeFocus ? Qt.alpha(Theme.colors.accent, 0.65) : Theme.colors.menuBorder

            TextInput {
                id: input

                objectName: "calculatorInput"
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
                selectByMouse: true
                clip: true
                focus: true
                maximumLength: 2048
                Accessible.name: "Calculation"

                onTextChanged: copiedTimer.stop()
                Keys.onReturnPressed: root.copyResult()
                Keys.onEnterPressed: root.copyResult()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 100
            radius: Theme.menu.rowRadius
            color: Qt.alpha(Theme.colors.menuBorder, 0.3)
            border.color: Theme.colors.menuBorder

            Label {
                objectName: "calculatorResult"
                anchors.fill: parent
                anchors.margins: 20
                text: engine.errorMessage || (engine.result ? (engine.approximate ? "≈ " : "") + engine.result : "")
                color: engine.errorMessage ? Theme.colors.critical : Theme.colors.text
                font.pointSize: engine.errorMessage ? 14 : 28
                fontSizeMode: Text.Fit
                minimumPointSize: 12
                wrapMode: Text.WrapAnywhere
                verticalAlignment: Text.AlignVCenter
                clip: true
                Accessible.name: "Result"
            }
        }

        Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: engine.warningMessage
            color: Theme.colors.workspaceUrgent
            font.pointSize: 10
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            RowLayout {
                spacing: 8

                Keycap {
                    text: "Enter"
                }

                Label {
                    id: copyHintLabel
                    Layout.preferredWidth: copyHintMetrics.width
                    text: root.copied ? "Copied" : "Copy result"
                    color: Theme.colors.mutedText
                    font.pointSize: 10

                    TextMetrics {
                        id: copyHintMetrics
                        font: copyHintLabel.font
                        text: "Copy result"
                    }
                }
            }

            RowLayout {
                spacing: 8

                Keycap {
                    text: "Ctrl+L"
                }

                Label {
                    text: "Clear"
                    color: Theme.colors.mutedText
                    font.pointSize: 10
                }
            }
        }
    }
}
