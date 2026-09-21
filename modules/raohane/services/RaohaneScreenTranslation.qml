pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Resident transaction backend for screen OCR + translation. The presentation
// may be destroyed while a capture is in progress; only this small service must
// survive from the capture request until the backend result is ready.
QtObject {
    id: root

    property string targetLanguage: "ru"
    property string sourceText: ""
    property string translatedText: ""
    property string errorText: ""
    property bool awaitingResult: false

    readonly property bool busy: captureDelay.running || translateProcess.running

    signal translationFinished()

    function toggleTargetLanguage(): void {
        root.targetLanguage = root.targetLanguage === "ru" ? "en" : "ru"
    }

    function start(): bool {
        if (root.busy)
            return false

        root.errorText = ""
        root.awaitingResult = true
        captureDelay.restart()
        return true
    }

    function finishWithError(message: string): void {
        root.sourceText = ""
        root.translatedText = ""
        root.errorText = String(message ?? qsTr("Translation failed."))
        root.awaitingResult = false
        root.translationFinished()
    }

    function applyResult(payload: string): void {
        let result
        try {
            result = JSON.parse(String(payload ?? ""))
        } catch (error) {
            root.finishWithError(qsTr("The translation backend returned invalid data."))
            return
        }

        root.targetLanguage = String(result?.target ?? root.targetLanguage)
        root.sourceText = String(result?.source ?? "")
        root.translatedText = String(result?.translation ?? "")
        root.errorText = result?.ok ? "" : String(result?.error ?? qsTr("Translation failed."))
        root.awaitingResult = false
        root.translationFinished()
    }

    Timer {
        id: captureDelay
        interval: 140
        repeat: false
        onTriggered: translateProcess.exec([
            Quickshell.shellPath("scripts/screen-translate.sh"),
            root.targetLanguage
        ])
    }

    Process {
        id: translateProcess

        stdout: StdioCollector {
            onStreamFinished: root.applyResult(text)
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.awaitingResult)
                root.finishWithError(qsTr("The screen translation process exited unexpectedly."))
        }
    }
}
