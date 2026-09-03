pragma Singleton

import QtQuick

QtObject {
    id: root

    signal pageRequested(string pageKey, string controlKey)

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
        const resolved = RaohaneSettingsPageRegistry.resolveRoute(parsed.page, parsed.control)
        if (!resolved)
            return false

        const index = RaohaneSettingsPageRegistry.resolvePageIndex(resolved.page)
        if (index < 0)
            return false

        const page = RaohaneSettingsPageRegistry.pages[index]
        if (page?.externalSurface) {
            RaohaneState.setPrimaryOpen(page.externalSurface, true)
            return true
        }

        RaohaneState.setPrimaryOpen("settings", true)
        root.pageRequested(page.key, String(resolved.control ?? ""))
        return true
    }

    function requestSearch(section: string, key: string): bool {
        return root.request(section, key)
    }
}
