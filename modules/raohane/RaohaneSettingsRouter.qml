pragma Singleton

import QtQuick

QtObject {
    id: root

    signal pageRequested(string pageKey, string controlKey)
    signal preferencesRequested(string section)
    signal backupRequested()
    signal languageRequested()

    readonly property var specialAliases: ({
        "keybinds": { kind: "preferences", target: "keybinds" },
        "shortcuts": { kind: "preferences", target: "keybinds" },
        "keyboard": { kind: "preferences", target: "keybinds" },
        "motion": { kind: "preferences", target: "motion" },
        "animations": { kind: "preferences", target: "motion" },
        "animation": { kind: "preferences", target: "motion" },
        "backup": { kind: "backup" },
        "restore": { kind: "backup" },
        "backup & restore": { kind: "backup" },
        "language": { kind: "language" },
        "locale": { kind: "language" }
    })

    function normalized(value: string): string {
        return String(value ?? "").trim().toLowerCase()
    }

    function splitRoute(route: string, control: string): var {
        const raw = String(route ?? "").trim()
        const explicitControl = String(control ?? "").trim()
        if (explicitControl !== "")
            return { page: raw, control: explicitControl }

        const separator = raw.indexOf(":")
        if (separator < 0)
            return { page: raw, control: "" }
        return {
            page: raw.slice(0, separator),
            control: raw.slice(separator + 1)
        }
    }

    function request(route: string, control: string): bool {
        const parsed = root.splitRoute(route, control)
        const requested = root.normalized(parsed.page)
        if (requested === "")
            return false

        const special = root.specialAliases[requested]
        if (special) {
            RaohaneState.setPrimaryOpen("settings", true)
            if (special.kind === "preferences")
                root.preferencesRequested(special.target)
            else if (special.kind === "backup")
                root.backupRequested()
            else if (special.kind === "language")
                root.languageRequested()
            return true
        }

        const index = RaohaneSettingsPageRegistry.resolvePageIndex(requested)
        if (index < 0)
            return false

        const page = RaohaneSettingsPageRegistry.pages[index]
        if (page?.externalSurface) {
            RaohaneState.setPrimaryOpen(page.externalSurface, true)
            return true
        }

        RaohaneState.setPrimaryOpen("settings", true)
        root.pageRequested(page.key, String(parsed.control ?? ""))
        return true
    }

    function requestSearch(section: string, key: string): bool {
        return root.request(section, key)
    }
}
