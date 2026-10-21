pragma Singleton

import QtQml
import Quickshell

QtObject {
    function launch(command: var, options: var): void {
        Quickshell.execDetached({
            command: ["env", "GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1", "ghostty"]
                .concat(options?.ghosttyArguments ?? [], ["-e"], command),
            workingDirectory: options?.workingDirectory ?? ""
        });
    }
}
