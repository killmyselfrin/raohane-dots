pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool microphoneActive: false
    property bool cameraActive: false
    property bool recordingActive: false
    property bool unclassifiedVideoCaptureActive: false

    property string microphoneApp: ""
    property string cameraApp: ""
    property string recordingApp: ""

    function stringProp(props, key): string {
        return String(props?.[key] ?? "")
    }

    function applicationName(props): string {
        return root.stringProp(props, "application.name")
            || root.stringProp(props, "node.description")
            || root.stringProp(props, "node.name")
    }

    function reset(): void {
        root.microphoneActive = false
        root.cameraActive = false
        root.recordingActive = false
        root.unclassifiedVideoCaptureActive = false
        root.microphoneApp = ""
        root.cameraApp = ""
        root.recordingApp = ""
    }

    function applyDump(text): void {
        let document
        try {
            document = JSON.parse(String(text ?? "[]"))
        } catch (error) {
            root.reset()
            return
        }

        if (!Array.isArray(document)) {
            root.reset()
            return
        }

        let microphoneActive = false
        let cameraActive = false
        let recordingActive = false
        let unclassifiedVideo = false
        let microphoneApp = ""
        let cameraApp = ""
        let recordingApp = ""

        for (const object of document) {
            if (String(object?.type ?? "") !== "PipeWire:Interface:Node")
                continue

            const info = object?.info ?? {}
            if (String(info?.state ?? "").toLowerCase() !== "running")
                continue

            const props = info?.props ?? {}
            const mediaClass = root.stringProp(props, "media.class")
            const mediaCategory = root.stringProp(props, "media.category")
            const mediaRole = root.stringProp(props, "media.role")
            const capture = mediaClass.startsWith("Stream/Input/") || mediaCategory === "Capture"
            if (!capture)
                continue

            const app = root.applicationName(props)
            if (mediaClass.includes("Audio")) {
                microphoneActive = true
                if (!microphoneApp.length)
                    microphoneApp = app
                continue
            }

            if (!mediaClass.includes("Video"))
                continue

            if (mediaRole === "Camera") {
                cameraActive = true
                if (!cameraApp.length)
                    cameraApp = app
            } else if (mediaRole === "Screen" || mediaRole === "Screencast") {
                recordingActive = true
                if (!recordingApp.length)
                    recordingApp = app
            } else {
                unclassifiedVideo = true
            }
        }

        root.microphoneActive = microphoneActive
        root.cameraActive = cameraActive
        root.recordingActive = recordingActive
        root.unclassifiedVideoCaptureActive = unclassifiedVideo
        root.microphoneApp = microphoneApp
        root.cameraApp = cameraApp
        root.recordingApp = recordingApp
    }

    function refresh(): void {
        if (!graphProbe.running)
            graphProbe.exec(["bash", "-lc", "command -v pw-dump >/dev/null 2>&1 && pw-dump || printf '[]'"])
    }

    // pw-mon stays attached to the PipeWire registry and emits only when the
    // graph changes. Debouncing those events avoids spawning pw-dump every
    // second for the entire desktop session while keeping privacy indicators
    // responsive when capture streams appear or disappear.
    Process {
        id: graphMonitor
        command: ["pw-mon", "--color=never"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    graphChangeDebounce.restart()
            }
        }

        onExited: monitorRestart.restart()
    }

    Timer {
        id: graphChangeDebounce
        interval: 140
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: monitorRestart
        interval: 2500
        repeat: false
        onTriggered: graphMonitor.running = true
    }

    // Fallback health refresh is deliberately slow. It covers a crashed monitor
    // or unusual PipeWire implementation without restoring the old 1.2s poll.
    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: graphProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applyDump(text)
        }
    }

    Component.onCompleted: root.refresh()
}
