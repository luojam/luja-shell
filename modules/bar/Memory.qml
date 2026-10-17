import QtQuick
import Quickshell.Io
import "../../config"

Rectangle {
    id: root

    property real totalKiB: 0
    property real usedKiB: 0
    readonly property string usage: totalKiB > 0 ? (usedKiB / 1048576).toFixed(1) + " / " + (totalKiB / 1048576).toFixed(1) + " GiB" : "—"

    implicitWidth: content.implicitWidth + Theme.bar.widgetPadding * 2
    implicitHeight: Theme.bar.widgetHeight
    radius: Theme.bar.widgetRadius
    color: Theme.colors.barBackground

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const total = /^MemTotal:\s+(\d+)/m.exec(data);
            const available = /^MemAvailable:\s+(\d+)/m.exec(data);
            root.totalKiB = total && available ? Number(total[1]) : 0;
            root.usedKiB = total && available ? Math.max(0, root.totalKiB - Number(available[1])) : 0;
        }
        onLoadFailed: root.totalKiB = 0
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: meminfo.reload()
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.bar.spacing

        Text {
            id: memoryIcon

            readonly property rect inkBounds: iconMetrics.tightBoundingRect(text)

            anchors.baseline: memoryText.baseline
            anchors.baselineOffset: Math.round(textMetrics.inkCenter - (inkBounds.y + inkBounds.height / 2))
            width: Math.ceil(inkBounds.width)
            transform: Translate {
                x: -memoryIcon.inkBounds.x
            }
            text: "\uefc5"
            color: Theme.colors.text
            renderType: Theme.typography.textRenderType
            font.family: Theme.typography.iconFontFamily
            font.styleName: Theme.typography.iconFontStyle
            font.pixelSize: Theme.typography.barFontPixelSize
            font.hintingPreference: Theme.typography.fontHintingPreference
        }

        Text {
            id: memoryText
            anchors.verticalCenter: parent.verticalCenter
            text: root.usage
            color: Theme.colors.text
            renderType: Theme.typography.textRenderType
            font.family: Theme.typography.fontFamily
            font.styleName: Theme.typography.barFontStyle
            font.pixelSize: Theme.typography.barFontPixelSize
            font.hintingPreference: Theme.typography.fontHintingPreference
            font.features: Theme.typography.fontFeatures
        }
    }

    FontMetrics {
        id: iconMetrics
        font: memoryIcon.font
    }

    FontMetrics {
        id: textMetrics
        font: memoryText.font

        readonly property rect inkBounds: tightBoundingRect(memoryText.text)
        readonly property real inkCenter: inkBounds.y + inkBounds.height / 2
    }
}
