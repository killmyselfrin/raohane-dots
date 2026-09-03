pragma Singleton

import QtQuick

// Raohane-owned cross-surface state. All ephemeral product state lives here;
// the active runtime has no legacy global-state bridge. Surface identity and
// exclusivity rules are described by RaohaneSurfaceRegistry rather than being
// repeated as switch tables across the shell.
QtObject {
    id: root

    property bool launcherOpen: false
    property bool mediaOverlayOpen: false
    property bool wallpaperSelectorOpen: false
    property string wallpaperSelectorTarget: "wallpaper"
    property bool overviewOpen: false

    property bool barOpen: true
    property bool controlCenterOpen: false
    property bool leftSidebarOpen: false
    property bool overlayOpen: false
    property bool regionSelectorOpen: false
    property bool screenTranslatorOpen: false
    property bool oskOpen: false
    property bool settingsOpen: false
    property bool displaySettingsOpen: false
    property bool welcomeOpen: false
    property bool sessionOpen: false
    property bool taskManagerOpen: false
    property bool osdOpen: false
    property bool screenLocked: false
    property bool superDown: false

    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0

    function surfaceOpen(name: string): bool {
        const stateProperty = RaohaneSurfaceRegistry.stateProperty(name)
        if (!stateProperty)
            return false
        return !!root[stateProperty]
    }

    function setSurfaceOpen(name: string, open: bool): void {
        const id = RaohaneSurfaceRegistry.normalizeId(name)
        const metadata = RaohaneSurfaceRegistry.definition(id)
        if (!metadata || !metadata.stateProperty) {
            console.warn("[RaohaneState] Unknown surface:", name)
            return
        }

        if (metadata.kind === "primary") {
            if (open)
                root.closePrimarySurfaces(id)
            root[metadata.stateProperty] = open
            return
        }

        if (metadata.kind === "transient") {
            if (open && metadata.closePrimaryOnOpen === true)
                root.closePrimarySurfaces("")
            root[metadata.stateProperty] = open
            return
        }

        console.warn("[RaohaneState] Surface has no state policy:", id)
    }

    function toggleSurface(name: string): void {
        const id = RaohaneSurfaceRegistry.normalizeId(name)
        if (!id) {
            console.warn("[RaohaneState] Unknown surface:", name)
            return
        }
        root.setSurfaceOpen(id, !root.surfaceOpen(id))
    }

    function primaryOpen(name: string): bool {
        if (!RaohaneSurfaceRegistry.isPrimary(name))
            return false
        return root.surfaceOpen(name)
    }

    function closePrimarySurfaces(except: string): void {
        const keep = RaohaneSurfaceRegistry.normalizeId(except)
        const ids = RaohaneSurfaceRegistry.primarySurfaceIds
        for (let i = 0; i < ids.length; ++i) {
            const id = ids[i]
            if (id === keep)
                continue
            const stateProperty = RaohaneSurfaceRegistry.stateProperty(id)
            if (stateProperty)
                root[stateProperty] = false
        }
    }

    function setPrimaryOpen(name: string, open: bool): void {
        const id = RaohaneSurfaceRegistry.normalizeId(name)
        if (!id || !RaohaneSurfaceRegistry.isPrimary(id)) {
            console.warn("[RaohaneState] Unknown primary surface:", name)
            return
        }
        root.setSurfaceOpen(id, open)
    }

    function togglePrimary(name: string): void {
        const id = RaohaneSurfaceRegistry.normalizeId(name)
        if (!id || !RaohaneSurfaceRegistry.isPrimary(id)) {
            console.warn("[RaohaneState] Unknown primary surface:", name)
            return
        }
        root.toggleSurface(id)
    }

    function toggleAction(name: string): void {
        if (!name || name === "none")
            return

        const id = RaohaneSurfaceRegistry.normalizeId(name)
        if (!id) {
            console.warn("[RaohaneState] Unknown transient action:", name)
            return
        }
        root.toggleSurface(id)
    }

    function closeTransientSurfaces(): void {
        root.closePrimarySurfaces("")

        const ids = RaohaneSurfaceRegistry.transientSurfaceIds
        for (let i = 0; i < ids.length; ++i) {
            const stateProperty = RaohaneSurfaceRegistry.stateProperty(ids[i])
            if (stateProperty)
                root[stateProperty] = false
        }
    }
}
