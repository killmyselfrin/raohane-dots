pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property string language: "en_US"
    property bool languageChosen: false
    property bool pickerOpen: false
    property bool restartAfterLocalization: false
    property int revision: 0
    property var english: ({})

    readonly property var supportedLanguages: [
        { code: "en_US", name: "English", nativeName: "English" },
        { code: "ru_RU", name: "Russian", nativeName: "Русский" }
    ]

    function parse(contents: string, fallback): var {
        try {
            const value = JSON.parse(contents)
            return value && typeof value === "object" ? value : fallback
        } catch (error) {
            console.warn("[RaohaneI18n] Invalid translation catalog:", error)
            return fallback
        }
    }

    function normalizeLanguage(value: string): string {
        const code = String(value ?? "").trim()
        return code === "ru_RU" || code.toLowerCase().startsWith("ru") ? "ru_RU" : "en_US"
    }

    function setLanguage(value: string): void {
        const code = root.normalizeLanguage(value)
        if (root.languageChosen && root.language === code) {
            root.pickerOpen = false
            return
        }
        root.language = code
        root.languageChosen = true
        root.pickerOpen = false
        root.restartAfterLocalization = true
        languageFile.setText(code + "\n")
        root.revision++
        Qt.uiLanguage = code
        if (!runtimeLocalizer.running)
            runtimeLocalizer.running = true
    }

    function openPicker(): void {
        root.pickerOpen = true
    }

    function closePicker(): void {
        if (root.languageChosen)
            root.pickerOpen = false
    }

    function tr(source: string): string {
        const dependency = root.revision
        const text = String(source ?? "")
        if (root.language !== "ru_RU")
            return root.english?.[text] ?? text
        return RaohaneLocale.tr(text)
    }

    function languageName(code: string): string {
        return root.normalizeLanguage(code) === "ru_RU" ? "Русский" : "English"
    }

    FileView {
        id: englishFile
        path: Quickshell.shellPath("translations/en_US.json")
        watchChanges: true
        onLoaded: {
            root.english = root.parse(englishFile.text(), ({}))
            root.revision++
        }
        onFileChanged: reload()
    }

    FileView {
        id: languageFile
        path: RaohanePaths.configDirectory + "/language"
        watchChanges: true
        onLoaded: {
            root.language = root.normalizeLanguage(languageFile.text())
            root.languageChosen = true
            Qt.uiLanguage = root.language
            root.revision++
        }
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.language = "en_US"
                root.languageChosen = false
                Qt.uiLanguage = root.language
                root.revision++
            }
        }
    }

    Process {
        id: runtimeLocalizer
        command: ["python3", Quickshell.shellPath("scripts/localize-runtime.py"), Quickshell.shellPath(".")]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 4) {
                root.restartAfterLocalization = false
                return
            }
            if (exitCode !== 0) {
                root.restartAfterLocalization = false
                console.warn("[RaohaneI18n] Runtime localization preparation failed")
                return
            }
            if (root.restartAfterLocalization) {
                root.restartAfterLocalization = false
                Quickshell.execDetached(["systemctl", "--user", "restart", "raohane.service"])
            }
        }
    }

    Component.onCompleted: {
        englishFile.reload()
        languageFile.reload()
        runtimeLocalizer.running = true
    }
}
