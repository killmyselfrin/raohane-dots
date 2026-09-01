pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string language: "en_US"
    property int revision: 0
    property var russianBase: ({})
    property var russianRuntime: ({})

    function parse(contents: string): var {
        try {
            const value = JSON.parse(contents)
            return value && typeof value === "object" ? value : ({})
        } catch (error) {
            console.warn("[RaohaneLocale] Invalid translation catalog:", error)
            return ({})
        }
    }

    function normalizeLanguage(value: string): string {
        const code = String(value ?? "").trim()
        return code === "ru_RU" || code.toLowerCase().startsWith("ru") ? "ru_RU" : "en_US"
    }

    function tr(source: string): string {
        const dependency = root.revision
        const text = String(source ?? "")
        if (root.language !== "ru_RU")
            return text
        return root.russianRuntime?.[text] ?? root.russianBase?.[text] ?? text
    }

    FileView {
        id: baseFile
        path: Quickshell.shellPath("translations/ru_RU.json")
        watchChanges: true
        onLoaded: {
            root.russianBase = root.parse(baseFile.text())
            root.revision++
        }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeFile
        path: Quickshell.shellPath("translations/raohane/ru_RU.json")
        watchChanges: true
        onLoaded: {
            root.russianRuntime = root.parse(runtimeFile.text())
            root.revision++
        }
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("[RaohaneLocale] Runtime Russian catalog unavailable:", error)
        }
    }

    FileView {
        id: languageFile
        path: RaohanePaths.configDirectory + "/language"
        watchChanges: true
        onLoaded: {
            root.language = root.normalizeLanguage(languageFile.text())
            root.revision++
        }
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.language = "en_US"
                root.revision++
            }
        }
    }

    Component.onCompleted: {
        baseFile.reload()
        runtimeFile.reload()
        languageFile.reload()
    }
}
