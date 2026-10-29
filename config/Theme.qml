pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property alias colors: colors

    QtObject {
        id: colors

        readonly property color transparent: "transparent"
        readonly property color text: "#cdd6f4"
        readonly property color mutedText: "#9399b2"
        readonly property color accent: "#89b4fa"
        readonly property color clipboardPinned: "#f9e2af"
        readonly property color critical: "#f38ba8"
        readonly property color workspaceSelected: "#a3d9bb" //"#8fd5c5"
        readonly property color workspaceUrgent: "#e7b38a"
        readonly property color workspaceOccupied: "#89b4fa"
        readonly property color workspaceEmpty: "#585b70"
        readonly property color menuBorder: "#45475a"
        readonly property real backgroundOpacity: 0.75
        readonly property color barBackground: Qt.rgba(28 / 255, 28 / 255, 28 / 255, backgroundOpacity)
        readonly property color menuBackground: Qt.rgba(30 / 255, 30 / 255, 46 / 255, backgroundOpacity)
        readonly property color menuSelection: Qt.alpha(accent, 0.18)
        readonly property color tooltipText: systemPalette.windowText
        readonly property color tooltipBackground: systemPalette.window
        readonly property color tooltipBorder: systemPalette.dark
    }

    property alias typography: typography

    QtObject {
        id: typography

        readonly property string fontFamily: "Adwaita Sans"
        readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
        readonly property string barFontStyle: "Bold"
        readonly property string iconFontStyle: "Regular"
        readonly property int barFontPixelSize: 13
        readonly property int volumeIconFontPixelSize: 15
        readonly property int menuFontPointSize: 14
        readonly property int notificationFontPointSize: 11
        readonly property int textRenderType: Text.NativeRendering
        readonly property int fontHintingPreference: Font.PreferVerticalHinting
        readonly property var fontFeatures: ({
                "tnum": 1
            })
    }

    property alias bar: bar

    QtObject {
        id: bar

        readonly property int height: 24
        readonly property int widgetHeight: 22
        readonly property int widgetRadius: 8
        readonly property int widgetPadding: 8
        readonly property int trayPadding: 5
        readonly property int spacing: 4
        readonly property int edgeMargin: 10
        readonly property int trayItemSize: 20
        readonly property int trayIconSize: 16
    }

    property alias workspaces: workspaces

    QtObject {
        id: workspaces

        readonly property int padding: 5
        readonly property int slotSize: 18
        readonly property int activeWidth: 16
        readonly property int activeHeight: 12
        readonly property int inactiveWidth: 6
        readonly property int indicatorRadius: 4
    }

    property alias menu: menu

    QtObject {
        id: menu

        readonly property int width: 580
        readonly property int visibleRows: 9
        readonly property int height: padding * 3 + tabDotSize + searchHeight + sectionSpacing
                                      + visibleRows * rowHeight + (visibleRows - 1) * rowSpacing
        readonly property int radius: 16
        readonly property int padding: 16
        readonly property int tabDotSize: 8
        readonly property int tabDotSpacing: 16
        readonly property int searchHeight: 44
        readonly property int sectionSpacing: 12
        readonly property int rowHeight: 44
        readonly property int rowSpacing: 2
        readonly property int rowRadius: 8
        readonly property int rowPadding: 12
        readonly property int iconSize: 28
    }

    property alias notifications: notifications

    QtObject {
        id: notifications

        readonly property int width: 350
        readonly property int radius: 10
        readonly property int borderWidth: 1
        readonly property int margin: 10
        readonly property int padding: 12
        readonly property int spacing: 6
        readonly property int iconSize: 48
    }

    property alias animations: animations

    QtObject {
        id: animations

        readonly property int barDuration: 250
        readonly property int workspaceDuration: 200
        readonly property int workspaceEasing: Easing.BezierSpline
        readonly property list<real> workspaceCurve: [0.16, 0.80, 0.20, 1, 1, 1]
        readonly property int menuHighlightDuration: 0
    }

    SystemPalette {
        id: systemPalette
    }
}
