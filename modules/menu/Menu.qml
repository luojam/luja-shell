pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "pages"

PanelWindow {
    id: root

    readonly property var tabs: [
        { id: "launcher", title: "Applications", component: applicationsTab },
        { id: "clipboard", title: "Clipboard", component: clipboardTab }
    ]
    property int currentIndex: 0

    visible: false
    implicitWidth: Theme.menu.width
    implicitHeight: Theme.menu.height
    color: Theme.colors.transparent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "luja-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function pageAt(index: int): var {
        const loader = pages.itemAt(index) as Loader;
        return loader?.item;
    }

    function selectTab(index: int): void {
        currentIndex = index;
        pageAt(index)?.activate();
    }

    function cycleTab(direction: int): void {
        selectTab((currentIndex + direction + tabs.length) % tabs.length);
    }

    function toggle(tabId: string): void {
        const index = tabs.findIndex(tab => tab.id === tabId);
        if (index < 0)
            return;

        if (visible) {
            if (currentIndex === index)
                visible = false;
            else
                selectTab(index);
            return;
        }

        const monitorName = Hyprland.focusedMonitor?.name ?? Config.preferredOutput;
        screen = Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0];
        for (let i = 0; i < pages.count; i++)
            pageAt(i)?.reset();
        currentIndex = index;
        visible = true;
        selectTab(index);
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle("launcher");
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle("clipboard");
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.visible = false
    }

    Shortcut {
        sequence: "Tab"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.cycleTab(1)
    }

    Shortcut {
        sequence: "Shift+Tab"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.cycleTab(-1)
    }

    Component {
        id: applicationsTab
        Applications {}
    }

    Component {
        id: clipboardTab
        Clipboard {}
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.menuBackground
        border.color: Theme.colors.menuBorder
        radius: Theme.menu.radius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menu.padding
            spacing: Theme.menu.padding

            Row {
                objectName: "menuTabs"

                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.menu.tabDotSpacing

                Repeater {
                    model: root.tabs

                    Rectangle {
                        required property var modelData
                        required property int index

                        objectName: modelData.id + "Tab"
                        width: Theme.menu.tabDotSize
                        height: width
                        radius: width / 2
                        color: root.currentIndex === index ? Theme.colors.accent : Theme.colors.mutedText
                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.title
                        Accessible.selected: root.currentIndex === index
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Repeater {
                    id: pages
                    model: root.tabs

                    Loader {
                        id: page

                        required property var modelData
                        required property int index

                        anchors.fill: parent
                        sourceComponent: modelData.component
                        visible: root.visible && root.currentIndex === index
                        focus: visible

                        Connections {
                            target: page.item
                            function onCloseRequested(): void {
                                if (page.visible)
                                    root.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
