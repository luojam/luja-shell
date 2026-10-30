import QtQuick
import Quickshell.Io

Item {
    id: root

    property string expression: ""
    property bool active: true
    property string result: ""
    property string errorMessage: ""
    property string warningMessage: ""
    property bool approximate: false
    property int revision: 0

    onExpressionChanged: refresh()
    onActiveChanged: {
        refresh();
        if (!active && process.running)
            process.signal(9);
    }

    function refresh(): void {
        revision++;
        result = "";
        errorMessage = "";
        warningMessage = "";
        approximate = false;
        debounce.stop();
        if (active && expression.trim())
            debounce.restart();
    }

    function resultSeparator(text: string): int {
        let depth = 0;
        let quote = "";
        for (let i = 0; i < text.length; i++) {
            const character = text[i];
            if (quote) {
                if (character === quote)
                    quote = "";
            } else if (character === '"' || character === "'") {
                quote = character;
            } else if ("([{".indexOf(character) !== -1) {
                depth++;
            } else if (")]}".indexOf(character) !== -1) {
                depth--;
            } else if (depth === 0 && text.slice(i, i + 3) === " = ") {
                return i;
            }
        }
        return -1;
    }

    function calculate(): void {
        if (!active || !expression.trim() || process.running)
            return;

        debounce.stop();
        process.revision = revision;
        // Keep diagnostics: qalc's terse mode silently drops invalid operators.
        process.exec([
            "env", "LC_ALL=C", "qalc", "--defaults", "--nocurrencies", "--time", "1000",
            "--set", "color 0", "--set", "unicode off",
            "--set", "approximation approximate",
            "--set", "fractions off", "--", expression.trim()
        ]);
        watchdog.restart();
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: root.calculate()
    }

    Timer {
        id: watchdog
        interval: 2000
        onTriggered: {
            if (process.revision === root.revision)
                root.errorMessage = "Calculation took too long. Try a simpler expression.";
            process.signal(9);
        }
    }

    Process {
        id: process

        property int revision: -1

        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }

        onExited: (exitCode, exitStatus) => {
            watchdog.stop();
            if (revision !== root.revision) {
                if (!debounce.running)
                    Qt.callLater(root.calculate);
                return;
            }
            if (!root.active || root.errorMessage)
                return;

            if (exitCode === 127) {
                root.errorMessage = "Install libqalculate to use the calculator.";
                return;
            }

            const lines = [];
            const warnings = [];
            for (const line of output.text.trim().split("\n")) {
                const diagnostic = line.match(/^(error|warning):\s*(.*)$/i);
                if (!diagnostic) {
                    lines.push(line);
                    continue;
                }
                // Only known usable-result warnings may pass; input repairs still fail.
                const usable = diagnostic[2] === "log() with a single argument is considered ambiguous. Please use ln() or log10() instead.";
                if (diagnostic[1].toLowerCase() !== "warning" || !usable) {
                    root.errorMessage = diagnostic[2];
                    return;
                }
                warnings.push(diagnostic[2]);
            }
            const text = lines.join("\n").trim();
            const lineBreak = text.indexOf("\n");
            const separator = lineBreak >= 0 ? lineBreak : root.resultSeparator(text);
            const resultText = separator < 0 ? "" : text.slice(separator + (lineBreak >= 0 ? 1 : 3));
            const match = resultText.match(/^(approx\. )?([\s\S]+)$/);
            if (exitCode !== 0 || exitStatus !== 0 || errors.text.trim() || !match) {
                root.errorMessage = "Could not calculate this expression.";
                return;
            }
            root.approximate = !!match[1];
            root.warningMessage = warnings.join("\n");
            root.result = match[2].trim();
        }
    }
}
