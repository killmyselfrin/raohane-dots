pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool started: false
    property bool running: runner.running
    property int lastExitCode: 0

    function runOnce(): void {
        if (root.started || runner.running)
            return
        root.started = true
        runner.exec([
            "bash",
            Quickshell.shellPath("scripts/autostart.sh"),
            "run"
        ])
    }

    function rerun(): void {
        if (runner.running)
            return
        root.started = true
        runner.exec([
            "bash",
            Quickshell.shellPath("scripts/autostart.sh"),
            "rerun"
        ])
    }

    Process {
        id: runner
        onExited: (exitCode, exitStatus) => root.lastExitCode = exitCode
    }
}
