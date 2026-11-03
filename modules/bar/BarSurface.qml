pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    default property alias contentData: content.data
    required property list<rect> collapsedPills
    property real collapsedHeight: height
    readonly property real contentOffset: height - collapsedHeight
    property real expansionOrigin: width / 2
    property real expansion: 0
    property real radius: 0
    property color color: "black"

    data: [
        Item {
            id: silhouette

            anchors.fill: parent

            Repeater {
                model: root.collapsedPills

                delegate: Rectangle {
                    required property rect modelData

                    x: modelData.x
                    y: modelData.y + root.contentOffset
                    width: modelData.width
                    height: modelData.height
                    radius: root.radius
                    color: Qt.alpha(root.color, 1)
                    visible: root.expansion < 1
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                x: root.expansionOrigin * (1 - root.expansion)
                width: root.width * root.expansion
                height: root.collapsedHeight
                radius: root.radius
                color: Qt.alpha(root.color, 1)
                visible: root.expansion > 0
            }
        },
        ShaderEffectSource {
            id: mask

            x: -1
            y: -1
            width: Math.ceil((root.width + 2) * Screen.devicePixelRatio) / Screen.devicePixelRatio
            height: Math.ceil((root.height + 2) * Screen.devicePixelRatio) / Screen.devicePixelRatio
            sourceRect: Qt.rect(x, y, width, height)
            sourceItem: silhouette
            hideSource: true
            opacity: root.color.a
        },
        Item {
            x: mask.x
            y: mask.y
            width: mask.width
            height: mask.height
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
                autoPaddingEnabled: false
            }

            Item {
                id: content

                x: -mask.x
                y: -mask.y
                width: root.width
                height: root.height
            }
        }
    ]
}
