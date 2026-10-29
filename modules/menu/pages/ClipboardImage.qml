pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../../config"

Item {
    id: root

    required property string entryId
    required property string helperPath
    property bool failed: false
    readonly property real previewWidth: image.status === Image.Ready ? image.paintedWidth : width

    Image {
        id: image

        anchors.fill: parent
        asynchronous: true
        cache: false
        autoTransform: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignLeft
        sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: root.failed || image.status === Image.Error ? "Preview unavailable" : "Loading preview…"
        color: Theme.colors.mutedText
        font.family: Theme.typography.fontFamily
        font.pointSize: Theme.typography.menuFontPointSize
        renderType: Theme.typography.textRenderType
    }

    Process {
        command: ["bash", root.helperPath, "image", root.entryId]
        running: true
        stdout: StdioCollector {
            id: output
            waitForEnd: true
        }
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            root.failed = exitCode !== 0 || exitStatus !== 0 || output.text.length === 0;
            if (!root.failed)
                image.source = "data:application/octet-stream;base64," + output.text;
        }
    }
}
