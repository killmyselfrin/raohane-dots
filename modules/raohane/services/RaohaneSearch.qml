pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""
    property string mathResult: ""
    property list<string> clipboardEntries: []

    readonly property var applications: Array.from(DesktopEntries.applications.values)
        .filter((entry, index, values) => index === values.findIndex(candidate => candidate.id === entry.id))

    readonly property var builtInActions: [
        { name: qsTr("Open Settings"), icon: "settings", command: ["raohane", "settings"], keywords: "preferences config settings" },
        { name: qsTr("Open Control Center"), icon: "tune", command: ["raohane", "control"], keywords: "quick settings wifi audio bluetooth" },
        { name: qsTr("Choose Wallpaper"), icon: "wallpaper", command: ["raohane", "wallpaper"], keywords: "background wallpaper image" },
        { name: qsTr("Random Wallpaper"), icon: "casino", command: ["raohane", "wallpaper", "random"], keywords: "background random wallpaper" },
        { name: qsTr("Session / Power"), icon: "power_settings_new", command: ["raohane", "session"], keywords: "logout reboot shutdown power" },
        { name: qsTr("Lock Session"), icon: "lock", command: ["qs", "-c", "raohane", "ipc", "call", "lock", "activate"], keywords: "lock screen security" },
        { name: qsTr("Restart Raohane"), icon: "restart_alt", command: ["raohane", "restart"], keywords: "reload restart shell" }
    ]

    readonly property var results: root.buildResults()

    onQueryChanged: {
        const trimmed = root.query.trim()
        if (trimmed.startsWith("="))
            calculatorDelay.restart()
        else
            root.mathResult = ""

        if (trimmed.startsWith(":"))
            clipboardDelay.restart()
        else
            root.clipboardEntries = []
    }

    function shellQuote(value): string {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function normalized(value): string {
        return String(value ?? "").toLowerCase().trim()
    }

    function applicationText(entry): string {
        return root.normalized([
            entry.name,
            entry.genericName,
            entry.comment,
            ...(entry.keywords ?? [])
        ].join(" "))
    }

    function scoreApplication(entry, needle: string): int {
        const name = root.normalized(entry.name)
        const haystack = root.applicationText(entry)
        if (name === needle)
            return 1000
        if (name.startsWith(needle))
            return 850
        if (name.split(/\s+/).some(word => word.startsWith(needle)))
            return 700
        if (name.includes(needle))
            return 600
        if (haystack.includes(needle))
            return 350

        const tokens = needle.split(/\s+/).filter(token => token.length > 0)
        if (tokens.length > 1 && tokens.every(token => haystack.includes(token)))
            return 250
        return 0
    }

    function executeApplication(entry): void {
        if (!entry)
            return
        if (!entry.runInTerminal) {
            entry.execute()
            return
        }

        const command = (entry.command ?? []).map(root.shellQuote).join(" ")
        Quickshell.execDetached([
            "bash", "-lc",
            `if command -v xdg-terminal-exec >/dev/null 2>&1; then xdg-terminal-exec ${command}; elif [ -n \"${"$"}{TERMINAL:-}\" ]; then \"${"$"}TERMINAL\" -e ${command}; elif command -v kitty >/dev/null 2>&1; then kitty -e ${command}; else foot -e ${command}; fi`
        ])
    }

    function appResults(needle: string): var {
        if (needle.length === 0)
            return []

        return root.applications
            .map(entry => ({ entry: entry, score: root.scoreApplication(entry, needle) }))
            .filter(candidate => candidate.score > 0)
            .sort((left, right) => right.score - left.score || root.normalized(left.entry.name).localeCompare(root.normalized(right.entry.name)))
            .slice(0, 30)
            .map(candidate => {
                const entry = candidate.entry
                return {
                    id: entry.id,
                    name: entry.name,
                    iconName: entry.icon || "application-x-executable",
                    iconType: "system",
                    verb: qsTr("OPEN"),
                    type: qsTr("App"),
                    comment: entry.comment || entry.genericName || "",
                    execute: () => root.executeApplication(entry)
                }
            })
    }

    function actionResults(needle: string): var {
        return root.builtInActions
            .filter(action => {
                const haystack = root.normalized(`${action.name} ${action.keywords}`)
                return needle.length === 0 || haystack.includes(needle)
            })
            .map(action => ({
                name: action.name,
                iconName: action.icon,
                iconType: "material",
                verb: qsTr("RUN"),
                type: qsTr("Raohane action"),
                comment: action.keywords,
                execute: () => Quickshell.execDetached(action.command)
            }))
    }

    function commandResult(command: string): var {
        if (command.length === 0)
            return []
        return [{
            name: command,
            iconName: "terminal",
            iconType: "material",
            verb: qsTr("RUN"),
            type: qsTr("Shell command"),
            comment: qsTr("Run through your login shell"),
            execute: () => Quickshell.execDetached(["bash", "-lc", command])
        }]
    }

    function calculatorResults(expression: string): var {
        if (expression.length === 0)
            return []
        return [{
            name: root.mathResult.length > 0 ? root.mathResult : qsTr("Calculating…"),
            iconName: "calculate",
            iconType: "material",
            verb: root.mathResult.length > 0 ? qsTr("COPY") : "",
            type: qsTr("Calculator"),
            comment: expression,
            execute: () => {
                if (root.mathResult.length > 0)
                    Quickshell.clipboardText = root.mathResult
            }
        }]
    }

    function clipboardResults(needle: string): var {
        return root.clipboardEntries
            .filter(entry => needle.length === 0 || root.normalized(entry).includes(needle))
            .slice(0, 20)
            .map(entry => ({
                name: entry.replace(/^\s*\d+\s+/, "").slice(0, 180),
                iconName: "content_paste",
                iconType: "material",
                verb: qsTr("COPY"),
                type: qsTr("Clipboard"),
                comment: entry.slice(0, 220),
                execute: () => {
                    const quoted = root.shellQuote(entry)
                    Quickshell.execDetached(["bash", "-lc", `printf '%s\\n' ${quoted} | cliphist decode | wl-copy`])
                }
            }))
    }

    function buildResults(): var {
        const raw = root.query.trim()
        if (raw.length === 0)
            return []

        if (raw.startsWith("/"))
            return root.actionResults(root.normalized(raw.slice(1)))
        if (raw.startsWith(">"))
            return root.commandResult(raw.slice(1).trim())
        if (raw.startsWith("="))
            return root.calculatorResults(raw.slice(1).trim())
        if (raw.startsWith(":"))
            return root.clipboardResults(root.normalized(raw.slice(1)))

        return root.appResults(root.normalized(raw))
    }

    Timer {
        id: calculatorDelay
        interval: 120
        repeat: false
        onTriggered: {
            const expression = root.query.trim().slice(1).trim()
            if (expression.length === 0) {
                root.mathResult = ""
                return
            }
            calculator.running = false
            calculator.command = ["qalc", "-t", expression]
            calculator.running = true
        }
    }

    Process {
        id: calculator
        stdout: StdioCollector {
            onStreamFinished: root.mathResult = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.mathResult = ""
        }
    }

    Timer {
        id: clipboardDelay
        interval: 90
        repeat: false
        onTriggered: {
            clipboardReader.running = false
            clipboardReader.command = ["bash", "-lc", "command -v cliphist >/dev/null 2>&1 && cliphist list | head -80 || true"]
            clipboardReader.running = true
        }
    }

    Process {
        id: clipboardReader
        stdout: StdioCollector {
            onStreamFinished: root.clipboardEntries = text.split("\n").filter(line => line.trim().length > 0)
        }
    }
}
