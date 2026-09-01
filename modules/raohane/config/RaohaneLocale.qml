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
    property var russianA: ({})
    property var russianGN: ({})
    property var russianOS: ({})
    property var russianTZ: ({})
    property var russianUI: ({})

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
        return root.russianUI?.[text]
            ?? root.russianTZ?.[text]
            ?? root.russianOS?.[text]
            ?? root.russianGN?.[text]
            ?? root.russianA?.[text]
            ?? root.russianBase?.[text]
            ?? text
    }

    FileView {
        id: baseFile
        path: Quickshell.shellPath("translations/ru_RU.json")
        watchChanges: true
        onLoaded: { root.russianBase = root.parse(baseFile.text()); root.revision++ }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeAFile
        path: Quickshell.shellPath("translations/raohane/ru_RU.json")
        watchChanges: true
        onLoaded: { root.russianA = root.parse(runtimeAFile.text()); root.revision++ }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeGNFile
        path: Quickshell.shellPath("translations/raohane/ru_RU_gn.json")
        watchChanges: true
        onLoaded: { root.russianGN = root.parse(runtimeGNFile.text()); root.revision++ }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeOSFile
        path: Quickshell.shellPath("translations/raohane/ru_RU_os.json")
        watchChanges: true
        onLoaded: { root.russianOS = root.parse(runtimeOSFile.text()); root.revision++ }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeTZFile
        path: Quickshell.shellPath("translations/raohane/ru_RU_tz.json")
        watchChanges: true
        onLoaded: { root.russianTZ = root.parse(runtimeTZFile.text()); root.revision++ }
        onFileChanged: reload()
    }

    FileView {
        id: runtimeUIFile
        path: Quickshell.shellPath("translations/raohane/ru_RU_ui.json")
        watchChanges: true
        onLoaded: { root.russianUI = root.parse(runtimeUIFile.text()); root.revision++ }
        onFileChanged: reload()
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
        runtimeAFile.reload()
        runtimeGNFile.reload()
        runtimeOSFile.reload()
        runtimeTZFile.reload()
        runtimeUIFile.reload()
        languageFile.reload()
    }
}