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

    // DesktopEntries can contain duplicate ids through aliases. Build one stable
    // application list when the source changes instead of running findIndex for
    // every entry. The normalized search index below is then reused for each
    // keystroke so launcher typing does not repeatedly lowercase comments and
    // keyword arrays for every installed application.
    readonly property var applications: {
        const values = Array.from(DesktopEntries.applications.values)
        const seen = new Set()
        const entries = []
        for (const entry of values) {
            if (!entry)
                continue
            const id = String(entry.id ?? "")
            if (id.length === 0 || seen.has(id))
                continue
            seen.add(id)
            entries.push(entry)
        }
        return entries
    }

    readonly property var indexedApplications: root.applications.map(entry => ({
        entry: entry,
        name: root.normalized(entry.name),
        haystack: root.applicationText(entry)
    }))

    readonly property var builtInActions: [
        { name: qsTr("Open Settings"), icon: "settings", command: ["raohane", "settings"], keywords: "preferences config settings" },
        { name: qsTr("Open Control Center"), icon: "tune", command: ["raohane", "control"], keywords: "quick settings wifi audio bluetooth" },
        { name: qsTr("Open Task Manager"), icon: "browse_activity", command: ["qs", "-c", "raohane", "ipc", "call", "taskManager", "open"], keywords: "processes cpu ram memory system monitor tasks" },
        { name: qsTr("Choose Wallpaper"), icon: "wallpaper", command: ["raohane", "wallpaper"], keywords: "background wallpaper image" },
        { name: qsTr("Random Wallpaper"), icon: "casino", command: ["raohane", "wallpaper", "random"], keywords: "background random wallpaper" },
        { name: qsTr("Session / Power"), icon: "power_settings_new", command: ["raohane", "session"], keywords: "logout reboot shutdown power" },
        { name: qsTr("Lock Session"), icon: "lock", command: ["qs", "-c", "raohane", "ipc", "call", "lock", "activate"], keywords: "lock screen security" },
        { name: qsTr("Restart Raohane"), icon: "restart_alt", command: ["raohane", "restart"], keywords: "reload restart shell" },
        {
            name: qsTr("Balanced Scene"),
            icon: "tune",
            keywords: "scene profile balanced normal default",
            active: RaohaneScenes.activeSceneId === "balanced",
            execute: () => RaohaneScenes.activate("balanced", "launcher")
        },
        {
            name: qsTr("Gaming Scene"),
            icon: "sports_esports",
            keywords: "scene profile gaming game performance dnd",
            active: RaohaneScenes.activeSceneId === "gaming",
            execute: () => RaohaneScenes.activate("gaming", "launcher")
        },
        {
            name: qsTr("Focus Scene"),
            icon: "center_focus_strong",
            keywords: "scene profile focus quiet dnd concentration",
            active: RaohaneScenes.activeSceneId === "focus",
            execute: () => RaohaneScenes.activate("focus", "launcher")
        },
        {
            name: qsTr("Work Scene"),
            icon: "work",
            keywords: "scene profile work productivity office development",
            active: RaohaneScenes.activeSceneId === "work",
            execute: () => RaohaneScenes.activate("work", "launcher")
        }
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

    function scoreIndexedApplication(candidate, needle: string): int {
        const name = candidate.name
        const haystack = candidate.haystack
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

        const matches = []
        for (const candidate of root.indexedApplications) {
            const score = root.scoreIndexedApplication(candidate, needle)
            if (score > 0)
                matches.push({ candidate: candidate, score: score })
        }

        matches.sort((left, right) => right.score - left.score
            || left.candidate.name.localeCompare(right.candidate.name))

        return matches.slice(0, 12).map(match => {
            const entry = match.candidate.entry
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

    function gamingActionResults(): var {
        if (RaohaneScenes.activeSceneId !== "gaming")
            return []

        const nextOutput = RaohaneAudio.nextOutputName()
        const outputDetail = nextOutput.length > 0 && nextOutput !== RaohaneAudio.sinkName
            ? qsTr("%1 → %2").arg(RaohaneAudio.sinkName || qsTr("Current output")).arg(nextOutput)
            : (RaohaneAudio.sinkName || qsTr("Audio output"))

        return [
            {
                name: qsTr("Microphone"),
                iconName: RaohaneAudio.microphoneMuted ? "mic_off" : "mic",
                iconType: "material",
                verb: RaohaneAudio.microphoneMuted ? qsTr("UNMUTE") : qsTr("MUTE"),
                type: qsTr("Gaming action"),
                comment: RaohaneAudio.sourceName || qsTr("Microphone input"),
                execute: () => RaohaneAudio.toggleMicrophoneMute()
            },
            {
                name: qsTr("Audio output"),
                iconName: "speaker",
                iconType: "material",
                verb: qsTr("SWITCH"),
                type: qsTr("Gaming action"),
                comment: outputDetail,
                execute: () => RaohaneAudio.cycleDefaultSink()
            },
            {
                name: RaohaneRecorder.recording ? qsTr("Stop recording") : qsTr("Record gameplay"),
                iconName: RaohaneRecorder.recording ? "stop_circle" : "fiber_manual_record",
                iconType: "material",
                verb: RaohaneRecorder.recording ? qsTr("STOP") : qsTr("RECORD"),
                type: qsTr("Gaming action"),
                comment: RaohaneRecorder.recording
                    ? qsTr("Recording · %1").arg(RaohaneRecorder.ownedRecording ? RaohaneRecorder.elapsedText : qsTr("active"))
                    : (RaohaneRecorder.available ? qsTr("Focused monitor with audio") : qsTr("wf-recorder unavailable")),
                execute: () => RaohaneRecorder.toggleFullscreen(true)
            },
            {
                name: qsTr("Game Mode"),
                iconName: "speed",
                iconType: "material",
                verb: RaohanePerformance.gameModeActive ? qsTr("DISABLE") : qsTr("ENABLE"),
                type: qsTr("Gaming action"),
                comment: qsTr("Performance profile"),
                execute: () => RaohanePerformance.toggleGameMode()
            },
            {
                name: qsTr("Do Not Disturb"),
                iconName: RaohaneNotifications.silent ? "notifications_off" : "notifications_active",
                iconType: "material",
                verb: RaohaneNotifications.silent ? qsTr("DISABLE") : qsTr("ENABLE"),
                type: qsTr("Gaming action"),
                comment: qsTr("Notification popups"),
                execute: () => RaohaneNotifications.silent = !RaohaneNotifications.silent
            },
            {
                name: qsTr("Media"),
                iconName: RaohaneMedia.isPlaying ? "pause" : "play_arrow",
                iconType: "material",
                verb: RaohaneMedia.available
                    ? (RaohaneMedia.isPlaying ? qsTr("PAUSE") : qsTr("PLAY"))
                    : qsTr("OPEN"),
                type: qsTr("Gaming action"),
                comment: RaohaneMedia.available && RaohaneMedia.title.length > 0
                    ? RaohaneMedia.title
                    : qsTr("Media overlay"),
                execute: () => {
                    if (RaohaneMedia.available)
                        RaohaneMedia.togglePlaying()
                    else
                        Quickshell.execDetached(["raohane", "media"])
                }
            }
        ]
    }

    function actionResults(needle: string): var {
        if (needle.length === 0) {
            const contextual = root.gamingActionResults()
            if (contextual.length > 0)
                return contextual
        }

        return root.builtInActions
            .filter(action => {
                const haystack = root.normalized(`${action.name} ${action.keywords}`)
                return needle.length === 0 || haystack.includes(needle)
            })
            .map(action => ({
                name: action.name,
                iconName: action.icon,
                iconType: "material",
                verb: action.active ? qsTr("ACTIVE") : (action.execute ? qsTr("APPLY") : qsTr("RUN")),
                type: action.execute ? qsTr("Raohane scene") : qsTr("Raohane action"),
                comment: action.active ? qsTr("Current scene") : action.keywords,
                execute: action.execute ? action.execute : () => Quickshell.execDetached(action.command)
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
