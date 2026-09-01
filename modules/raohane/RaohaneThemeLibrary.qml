pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property var bundledPresets: []
    property var userPresets: []
    readonly property var presets: root.mergeCatalogs(root.bundledPresets, root.userPresets)

    readonly property var requiredTokens: [
        "background", "backgroundElevated", "surface", "surfaceRaised", "surfaceDeep",
        "surfaceSubtle", "surfaceHover", "surfacePressed", "border", "borderStrong",
        "borderFaint", "highlight", "text", "textMuted", "textFaint", "accent",
        "accentSecondary", "accentBlue", "success", "warning", "critical", "info"
    ]

    function isColor(value): bool {
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(String(value ?? ""))
    }

    function sanitizePreset(raw): var {
        if (!raw || typeof raw !== "object")
            return null
        const id = String(raw.id ?? "").trim()
        const name = String(raw.name ?? "").trim()
        if (!/^[a-z0-9][a-z0-9-]*$/.test(id) || name.length === 0)
            return null
        for (const token of root.requiredTokens) {
            if (!root.isColor(raw[token]))
                return null
        }

        const preset = {
            id: id,
            name: name,
            description: String(raw.description ?? qsTr("Imported Raohane theme")),
            tone: String(raw.tone ?? qsTr("Custom")),
            dark: Boolean(raw.dark),
            source: String(raw.source ?? "user")
        }
        for (const token of root.requiredTokens)
            preset[token] = String(raw[token])
        return preset
    }

    function parseCatalog(contents: string, label: string): var {
        try {
            const document = JSON.parse(contents)
            if (!document || Number(document.schemaVersion) !== 1 || !Array.isArray(document.presets))
                throw new Error("expected theme catalog schema v1")
            const accepted = []
            for (const raw of document.presets) {
                const preset = root.sanitizePreset(raw)
                if (preset)
                    accepted.push(preset)
                else
                    console.warn("[RaohaneThemeLibrary] Ignoring invalid preset in", label)
            }
            return accepted
        } catch (error) {
            console.warn("[RaohaneThemeLibrary] Could not load", label + ":", error)
            return []
        }
    }

    function mergeCatalogs(bundled, user): var {
        const result = []
        const positions = {}
        for (const preset of (bundled ?? [])) {
            positions[preset.id] = result.length
            result.push(preset)
        }
        for (const preset of (user ?? [])) {
            if (positions[preset.id] !== undefined)
                result[positions[preset.id]] = preset
            else {
                positions[preset.id] = result.length
                result.push(preset)
            }
        }
        return result
    }

    function refresh(): void {
        bundledCatalog.reload()
        userCatalog.reload()
    }

    FileView {
        id: bundledCatalog
        path: Quickshell.shellPath("defaults/themes/serpantinum.json")
        watchChanges: true
        onLoaded: root.bundledPresets = root.parseCatalog(bundledCatalog.text(), "bundled Serpantinum themes")
        onFileChanged: reload()
        onLoadFailed: error => console.warn("[RaohaneThemeLibrary] Bundled catalog unavailable:", error)
    }

    FileView {
        id: userCatalog
        path: RaohanePaths.themeCatalogFile
        watchChanges: true
        onLoaded: root.userPresets = root.parseCatalog(userCatalog.text(), "user theme catalog")
        onFileChanged: reload()
        onLoadFailed: error => {
            root.userPresets = []
            if (error !== FileViewError.FileNotFound)
                console.warn("[RaohaneThemeLibrary] User catalog unavailable:", error)
        }
    }

    Component.onCompleted: root.refresh()
}
