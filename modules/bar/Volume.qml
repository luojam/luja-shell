import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink?.ready ? sink.audio : null
    readonly property int percentage: audio ? Math.round(audio.volume * 100) : 0
    readonly property string icon: {
        if (!audio || audio.muted)
            return "\u{f0581}";
        return percentage === 0 ? "\u{f057f}" : percentage < 50 ? "\u{f0580}" : "\u{f057e}";
    }

    implicitWidth: content.implicitWidth + 20
    implicitHeight: 20
    radius: 10
    color: Qt.rgba(28 / 255, 28 / 255, 28 / 255, 0.75)

    PwObjectTracker {
        objects: [root.sink]
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 4

        Text {
            id: volumeIcon

            readonly property rect inkBounds: iconMetrics.tightBoundingRect(text)

            anchors.baseline: volumeText.baseline
            anchors.baselineOffset: Math.round(volumeMetrics.inkCenter - (inkBounds.y + inkBounds.height / 2))
            width: iconMetrics.slotWidth
            horizontalAlignment: Text.AlignLeft
            transform: Translate {
                x: -volumeIcon.inkBounds.x
            }
            text: root.icon
            color: "#cdd6f4"
            renderType: Text.NativeRendering
            font.family: "JetBrainsMono Nerd Font"
            font.styleName: "Regular"
            font.pixelSize: 15
            font.hintingPreference: Font.PreferVerticalHinting
        }

        Text {
            id: volumeText

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(volumeMetrics.advanceWidth("99%"), volumeMetrics.advanceWidth("MAX"), volumeMetrics.advanceWidth(text))
            horizontalAlignment: Text.AlignRight
            text: !root.audio ? "—" : root.percentage === 100 ? "MAX" : root.percentage + "%"
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
        font: volumeIcon.font

        readonly property real slotWidth: Math.ceil(Math.max(
            tightBoundingRect("\u{f057f}").width, tightBoundingRect("\u{f0580}").width,
            tightBoundingRect("\u{f057e}").width, tightBoundingRect("\u{f0581}").width
        ))
    }

    FontMetrics {
        id: volumeMetrics
        font: volumeText.font

        readonly property rect inkBounds: tightBoundingRect(volumeText.text)
        readonly property real inkCenter: inkBounds.y + inkBounds.height / 2
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([
            "env", "GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1",
            "ghostty", "--gtk-single-instance=false", "--class=local.wiremix", "-e", "wiremix"
        ])
        onWheel: wheel => {
            if (!root.audio)
                return;
            const delta = wheel.angleDelta.y || wheel.angleDelta.x;
            if (delta !== 0)
                root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (delta > 0 ? 0.01 : -0.01)));
        }
    }
}
