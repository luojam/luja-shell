import QtQuick
import Quickshell.Services.Pipewire
import "../../helpers"
import "../../config"

Rectangle {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink?.ready ? sink.audio : null
    readonly property int percentage: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool recentlyChanged: feedbackTimer.running
    readonly property bool muted: audio?.muted ?? false
    property bool iconOnly: false
    readonly property string icon: {
        if (!audio || audio.muted)
            return "\u{f0581}";
        return percentage === 0 ? "\u{f057f}" : percentage < 50 ? "\u{f0580}" : "\u{f057e}";
    }

    implicitWidth: content.implicitWidth + Theme.bar.widgetPadding * 2
    implicitHeight: Theme.bar.widgetHeight
    radius: Theme.bar.widgetRadius
    color: Theme.colors.barBackground

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.audio

        function onVolumeChanged() {
            feedbackTimer.restart();
        }

        function onMutedChanged() {
            feedbackTimer.restart();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 2000
    }

    Row {
        id: content

        anchors.centerIn: parent
        height: parent.height
        spacing: Theme.bar.spacing

        Text {
            id: volumeIcon

            readonly property rect inkBounds: iconMetrics.tightBoundingRect(text)

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: height / 2 - baselineOffset - (inkBounds.y + inkBounds.height / 2)
            width: iconMetrics.slotWidth
            horizontalAlignment: Text.AlignLeft
            transform: Translate {
                x: -volumeIcon.inkBounds.x
            }
            text: root.icon
            color: Theme.colors.text
            renderType: Theme.typography.textRenderType
            font.family: Theme.typography.iconFontFamily
            font.styleName: Theme.typography.iconFontStyle
            font.pixelSize: Theme.typography.volumeIconFontPixelSize
            font.hintingPreference: Theme.typography.fontHintingPreference
        }

        Text {
            id: volumeText

            visible: !root.iconOnly
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(volumeMetrics.advanceWidth("99%"), volumeMetrics.advanceWidth("MAX"), volumeMetrics.advanceWidth(text))
            horizontalAlignment: Text.AlignRight
            text: !root.audio ? "—" : root.percentage === 100 ? "MAX" : root.percentage + "%"
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
        font: volumeIcon.font

        readonly property real slotWidth: Math.ceil(Math.max(tightBoundingRect("\u{f057f}").width, tightBoundingRect("\u{f0580}").width, tightBoundingRect("\u{f057e}").width, tightBoundingRect("\u{f0581}").width))
    }

    FontMetrics {
        id: volumeMetrics
        font: volumeText.font
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Ghostty.launch(["wiremix"], {
            ghosttyArguments: ["--gtk-single-instance=false", "--class=local.wiremix"]
        })
        onWheel: wheel => {
            if (!root.audio)
                return;
            const delta = wheel.angleDelta.y || wheel.angleDelta.x;
            if (delta !== 0)
                root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (delta > 0 ? 0.01 : -0.01)));
        }
    }
}
