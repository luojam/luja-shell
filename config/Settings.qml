import QtQml
import Quickshell
import Quickshell.Io

FileView {
    id: root

    property bool initialized: false

    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/settings.json"
    blockLoading: true
    printErrors: false
    adapter: Config.persistentOptions

    Component.onCompleted: {
        root.text();
        root.initialized = true;
    }

    onAdapterUpdated: {
        if (root.initialized)
            root.writeAdapter();
    }

    onLoadFailed: error => {
        if (error !== FileViewError.FileNotFound)
            console.warn("Could not load settings:", FileViewError.toString(error));
    }
    onSaveFailed: error => console.warn("Could not save settings:", FileViewError.toString(error))
}
