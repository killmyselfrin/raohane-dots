pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Shared authentication state for every WlSessionLockSurface. This deliberately
// owns PAM/fingerprint state instead of importing the inherited common lock
// framework, so all monitors observe one authentication transaction.
Scope {
    id: root

    signal shouldRefocus()
    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property int fingerprintRetryCount: 0
    readonly property int fingerprintRetryLimit: 3
    readonly property var fingerprintNames: [
        "left-thumb",
        "left-index-finger",
        "left-middle-finger",
        "left-ring-finger",
        "left-little-finger",
        "right-thumb",
        "right-index-finger",
        "right-middle-finger",
        "right-ring-finger",
        "right-little-finger"
    ]

    function clearText(): void {
        root.currentText = ""
    }

    function reset(): void {
        passwordClearTimer.stop()
        fingerRetry.stop()
        root.clearText()
        root.unlockInProgress = false
        root.showFailure = false
        root.fingerprintRetryCount = 0
        root.stopFingerPam()
    }

    function refreshFingerprints(): void {
        fingerprintCheck.running = false
        fingerprintCheck.running = true
    }

    function tryUnlock(): void {
        if (root.unlockInProgress || root.currentText.length === 0)
            return
        root.unlockInProgress = true
        root.showFailure = false
        passwordPam.start()
    }

    function tryFingerUnlock(): void {
        if (!RaohaneState.screenLocked || !root.fingerprintsConfigured || fingerprintPam.active)
            return
        fingerprintPam.start()
    }

    function stopFingerPam(): void {
        if (fingerprintPam.active)
            fingerprintPam.abort()
    }

    onCurrentTextChanged: {
        if (root.currentText.length > 0)
            root.showFailure = false
        passwordClearTimer.restart()
    }

    Timer {
        id: passwordClearTimer
        interval: 10000
        repeat: false
        onTriggered: root.reset()
    }

    Process {
        id: fingerprintCheck
        running: false
        command: ["bash", "-lc", "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$(whoami)\" || true"]

        stdout: StdioCollector {
            id: fingerprintOutput
            onStreamFinished: {
                const output = fingerprintOutput.text
                root.fingerprintsConfigured = root.fingerprintNames.some(name => output.includes(name))
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (RaohaneState.screenLocked && root.fingerprintsConfigured)
                root.tryFingerUnlock()
        }
    }

    PamContext {
        id: passwordPam

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.stopFingerPam()
                root.unlocked()
                return
            }

            root.clearText()
            root.unlockInProgress = false
            root.showFailure = true
            root.failed()
            root.shouldRefocus()
        }
    }

    PamContext {
        id: fingerprintPam
        configDirectory: "pam"
        config: "fprintd.conf"

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked()
            } else if (result === PamResult.Error
                    && RaohaneState.screenLocked
                    && root.fingerprintsConfigured
                    && root.fingerprintRetryCount + 1 < root.fingerprintRetryLimit) {
                // Retry a small number of transient fprintd/PAM errors. An
                // unavailable reader must never create an unbounded retry loop.
                root.fingerprintRetryCount += 1
                fingerRetry.restart()
            }
        }
    }

    Timer {
        id: fingerRetry
        interval: 900
        repeat: false
        onTriggered: root.tryFingerUnlock()
    }

    Component.onCompleted: root.refreshFingerprints()
}
