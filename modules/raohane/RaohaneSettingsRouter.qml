pragma Singleton

import QtQuick

QtObject {
    id: root

    signal pageRequested(string pageKey, string controlKey)

    // Keep the last native Settings route outside the presentation lifetime.
    // This makes cold on-demand opens deterministic and lets Settings restore
    // the last page after its window has been destroyed. A deep-link control is
    // transient and is cleared once the current presentation acknowledges it.
    property string requestedPageKey: ""
    property string requestedControlKey: ""
    property int routeRevision: 0

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

    function rememberRoute(pageKey: string, controlKey: string): int {
        root.requestedPageKey = String(pageKey ?? "")
        root.requestedControlKey = String(controlKey ?? "")
        root.routeRevision += 1
        return root.routeRevision
    }

    function acknowledgeRoute(revision: int): void {
        if (revision !== root.routeRevision)
            return
        root.requestedControlKey = ""
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

        const controlKey = String(resolved.control ?? "")
        root.rememberRoute(page.key, controlKey)

        // Emit before opening. An already-instantiated Settings presentation
        // (including one held for exit motion) consumes this immediately. A
        // fully unloaded presentation instead restores the remembered route in
        // Component.onCompleted after setPrimaryOpen creates it.
        root.pageRequested(page.key, controlKey)
        RaohaneState.setPrimaryOpen("settings", true)
        return true
    }

    function requestSearch(section: string, key: string): bool {
        return root.request(section, key)
    }
}
