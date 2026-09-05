pragma Singleton

import QtQuick

// Registry for section-specific Settings extensions. Generic section rendering
// stays independent from concrete editors such as Bar and Quick Controls Studio.
QtObject {
    id: root

    readonly property var extensions: ({
        bar: {
            // Keep the editor source explicit as an architectural contract;
            // shellSource composes it with the native live preview.
            source: "RaohaneBarStudio.qml",
            shellSource: "RaohaneBarStudioShell.qml",
            controlKeys: ["barModuleLayout"]
        },
        quick: {
            source: "RaohaneQuickControlsStudio.qml",
            controlKeys: ["quickControlTiles"]
        },
        desktop: {
            previewSource: "RaohaneDesktopPreview.qml",
            controlKeys: []
        }
    })

    function extension(sectionKey: string): var {
        const normalized = String(sectionKey ?? "").trim().toLowerCase()
        return root.extensions[normalized] ?? null
    }

    function source(sectionKey: string): string {
        const entry = root.extension(sectionKey)
        return entry?.shellSource ?? entry?.source ?? ""
    }

    function ownsControl(sectionKey: string, controlKey: string): bool {
        const key = String(controlKey ?? "").trim()
        if (key === "")
            return false
        const keys = root.extension(sectionKey)?.controlKeys ?? []
        return keys.includes(key)
    }

    function previewSource(sectionKey: string): string {
        return root.extension(sectionKey)?.previewSource ?? ""
    }
}
