import QtQuick
import Quickshell

Rectangle {
    implicitWidth: dateText.implicitWidth + 20
    implicitHeight: 20
    radius: 10
    color: Qt.rgba(28 / 255, 28 / 255, 28 / 255, 0.75)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: dateText

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM")
        color: "#cdd6f4"
        renderType: Text.NativeRendering
        font.family: "Adwaita Sans"
        font.styleName: "Bold"
        font.pixelSize: 13
        font.hintingPreference: Font.PreferVerticalHinting
        font.features: {
            "tnum": 1
        }
    }
}
