pragma Singleton

import QtQml
import Quickshell

QtObject {
    function launch(command: var, options: var): void {
        Quickshell.execDetached({
            command: ["ghostty"]
                .concat(options?.ghosttyArguments ?? [], ["-e"], command),
            workingDirectory: options?.workingDirectory ?? ""
        });
    }
}
