pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    // The mask only controls rendering; content owns visibility and input policy.
    default property alias contentData: content.data
    required property list<rect> collapsedPills
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
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    radius: root.radius
                    color: Qt.alpha(root.color, 1)
                    visible: root.expansion < 1
                }
            }

            Rectangle {
                x: root.expansionOrigin * (1 - root.expansion)
                width: root.width * root.expansion
                height: root.height
                radius: root.radius
                color: Qt.alpha(root.color, 1)
            }
        },
        ShaderEffectSource {
            id: mask

            // Keep the antialiased fringe inside the texture instead of cutting it off.
            x: -1
            y: -1
            width: root.width + 2
            height: root.height + 2
            sourceRect: Qt.rect(-1, -1, width, height)
            sourceItem: silhouette
            hideSource: true
            // Keep the content mask independent of background opacity.
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
