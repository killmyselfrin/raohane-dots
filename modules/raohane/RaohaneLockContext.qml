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

    function clearText(): void {
        root.currentText = ""
    }

    function reset(): void {
        passwordClearTimer.stop()
        fingerRetry.stop()
        root.clearText()
        root.unlockInProgress = false
        root.showFailure = false
        root.stopFingerPam()
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
        running: true
        command: ["bash", "-lc", "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$(whoami)\" || true"]

        stdout: StdioCollector {
            id: fingerprintOutput
            onStreamFinished: root.fingerprintsConfigured = fingerprintOutput.text.includes("Fingerprints for user")
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
            } else if (result === PamResult.Error && RaohaneState.screenLocked) {
                // fprintd can time out while the lock screen stays active. A new
                // PAM transaction is cheaper and safer than keeping stale state.
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
}
