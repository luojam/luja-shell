import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    property real totalKiB: 0
    property real usedKiB: 0
    readonly property string usage: totalKiB > 0 ? (usedKiB / 1048576).toFixed(1) + " / " + (totalKiB / 1048576).toFixed(1) + " GiB" : "—"

    implicitWidth: content.implicitWidth + 16
    implicitHeight: 20
    radius: 10
    color: Qt.rgba(28 / 255, 28 / 255, 28 / 255, 0.75)

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
        spacing: 4

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
            color: "#cdd6f4"
            renderType: Text.NativeRendering
            font.family: "JetBrainsMono Nerd Font"
            font.styleName: "Regular"
            font.pixelSize: 13
            font.hintingPreference: Font.PreferVerticalHinting
        }

        Text {
            id: memoryText
            anchors.verticalCenter: parent.verticalCenter
            text: root.usage
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
