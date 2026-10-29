pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    default property alias contentData: content.data
    required property list<rect> collapsedPills
    property real collapsedHeight: height
    readonly property real contentOffset: height - collapsedHeight
    property real expansionOrigin: width / 2
    property real expansion: 0
    property real radius: 0
    property real shoulderRadius: 8
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

            Shape {
                id: expandedShape

                readonly property real cornerRadius: Math.min(root.radius, width / 2, height / 2)
                readonly property real topInset: cornerRadius * (1 - root.expansion) - root.shoulderRadius * root.expansion
                readonly property real topDepth: cornerRadius * (1 - root.expansion) + root.shoulderRadius * root.expansion

                anchors.bottom: parent.bottom
                x: root.expansionOrigin * (1 - root.expansion)
                width: root.width * root.expansion
                height: root.collapsedHeight + (root.height - root.collapsedHeight) * root.expansion
                visible: root.expansion > 0
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: Qt.alpha(root.color, 1)
                    startX: expandedShape.topInset
                    startY: 0

                    PathLine {
                        x: expandedShape.width - expandedShape.topInset
                        y: 0
                    }
                    PathQuad {
                        controlX: expandedShape.width
                        controlY: 0
                        x: expandedShape.width
                        y: expandedShape.topDepth
                    }
                    PathLine {
                        x: expandedShape.width
                        y: expandedShape.height - expandedShape.cornerRadius
                    }
                    PathArc {
                        x: expandedShape.width - expandedShape.cornerRadius
                        y: expandedShape.height
                        radiusX: expandedShape.cornerRadius
                        radiusY: expandedShape.cornerRadius
                    }
                    PathLine {
                        x: expandedShape.cornerRadius
                        y: expandedShape.height
                    }
                    PathArc {
                        x: 0
                        y: expandedShape.height - expandedShape.cornerRadius
                        radiusX: expandedShape.cornerRadius
                        radiusY: expandedShape.cornerRadius
                    }
                    PathLine {
                        x: 0
                        y: expandedShape.topDepth
                    }
                    PathQuad {
                        controlX: 0
                        controlY: 0
                        x: expandedShape.topInset
                        y: 0
                    }
                }
            }
        },
        ShaderEffectSource {
            id: mask

            x: -root.shoulderRadius - 1
            y: -1
            width: Math.ceil((root.width + 2 * (root.shoulderRadius + 1)) * Screen.devicePixelRatio) / Screen.devicePixelRatio
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
