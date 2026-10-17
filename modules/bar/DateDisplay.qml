import QtQuick
import Quickshell
import "../../config"

Rectangle {
    implicitWidth: dateText.implicitWidth + Theme.bar.widgetPadding * 2
    implicitHeight: Theme.bar.widgetHeight
    radius: Theme.bar.widgetRadius
    color: Theme.colors.barBackground

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: dateText

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM")
        color: Theme.colors.text
        renderType: Theme.typography.textRenderType
        font.family: Theme.typography.fontFamily
        font.styleName: Theme.typography.barFontStyle
        font.pixelSize: Theme.typography.barFontPixelSize
        font.hintingPreference: Theme.typography.fontHintingPreference
        font.features: Theme.typography.fontFeatures
    }
}
