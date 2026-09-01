pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// One shared PipeWire registry watcher for Raohane. Audio and privacy used to
// keep separate pw-mon clients alive, which duplicated graph traffic and could
// amplify subprocess refreshes when PipeWire was busy.
Singleton {
    id: root

    property double ignoreEventsUntilMs: 0
    property bool monitorAvailable: true

    signal graphChanged()

    function suppressEventsFor(milliseconds: int): void {
        const duration = Math.max(0, Number(milliseconds) || 0)
        root.ignoreEventsUntilMs = Math.max(root.ignoreEventsUntilMs, Date.now() + duration)
    }

    Process {
        id: graphMonitor
        command: ["pw-mon", "--color=never"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0 || Date.now() < root.ignoreEventsUntilMs)
                    return
                graphDebounce.restart()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.monitorAvailable = false
            monitorRestart.restart()
        }
    }

    Timer {
        id: graphDebounce
        interval: 350
        repeat: false
        onTriggered: root.graphChanged()
    }

    Timer {
        id: monitorRestart
        interval: 3500
        repeat: false
        onTriggered: {
            root.monitorAvailable = true
            graphMonitor.running = true
        }
    }
}
