import QtQuick
import Quickshell

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        implicitHeight: 32
        color: "#181825"

        anchors {
            top: true
            left: true
            right: true
        }

        Text {
            anchors.centerIn: parent
            text: "Luja"
            color: "#cdd6f4"
            font.pixelSize: 14
        }
    }
}
