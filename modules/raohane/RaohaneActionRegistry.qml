pragma Singleton

import QtQuick

import qs.modules.raohane.services

// Declarative registry for user-selectable shell actions. Stateful surfaces
// remain owned by RaohaneSurfaceRegistry/RaohaneState; service-backed actions
// such as DropShelf are dispatched here without pretending to be surfaces.
QtObject {
    id: root

    readonly property var actionIds: [
        "none",
        "leftSidebar",
        "controlCenter",
        "overview",
        "launcher",
        "wallpaper",
        "dropShelf",
        "session"
    ]

    readonly property var definitions: ({
        none: {
            id: "none",
            label: qsTr("None"),
            icon: "block",
            aliases: []
        },
        leftSidebar: {
            id: "leftSidebar",
            label: qsTr("Left sidebar"),
            icon: "left_panel_open",
            surface: "leftSidebar",
            aliases: ["sidebarLeftOpen"]
        },
        controlCenter: {
            id: "controlCenter",
            label: qsTr("Control Center"),
            icon: "tune",
            surface: "controlCenter",
            aliases: ["sidebarRightOpen"]
        },
        overview: {
            id: "overview",
            label: qsTr("Overview"),
            icon: "space_dashboard",
            surface: "overview",
            aliases: ["overviewOpen"]
        },
        launcher: {
            id: "launcher",
            label: qsTr("Launcher"),
            icon: "search",
            surface: "launcher",
            aliases: []
        },
        wallpaper: {
            id: "wallpaper",
            label: qsTr("Wallpaper"),
            icon: "wallpaper",
            surface: "wallpaper",
            aliases: ["wallpaperSelectorOpen"]
        },
        dropShelf: {
            id: "dropShelf",
            label: qsTr("Drop Shelf"),
            icon: "shelves",
            serviceAction: "dropShelf",
            aliases: ["dropShelfOpen"]
        },
        session: {
            id: "session",
            label: qsTr("Session"),
            icon: "power_settings_new",
            surface: "session",
            aliases: ["sessionOpen"]
        }
    })

    function definition(value: string): var {
        const id = root.normalize(value)
        return id.length > 0 ? root.definitions[id] ?? null : null
    }

    function normalize(value: string): string {
        const requested = String(value ?? "").trim()
        if (root.definitions[requested] !== undefined)
            return requested
        for (let i = 0; i < root.actionIds.length; ++i) {
            const id = root.actionIds[i]
            if ((root.definitions[id]?.aliases ?? []).includes(requested))
                return id
        }
        return ""
    }

    function label(value: string): string {
        return root.definition(value)?.label ?? qsTr("None")
    }

    function icon(value: string): string {
        return root.definition(value)?.icon ?? "block"
    }

    function hotCornerOptions(): var {
        return root.actionIds.map(id => {
            const definition = root.definitions[id]
            return {
                value: id,
                label: definition.label,
                icon: definition.icon,
                aliases: definition.aliases ?? []
            }
        })
    }

    function trigger(value: string, screen): void {
        const definition = root.definition(value)
        if (!definition || definition.id === "none")
            return

        if (definition.surface) {
            RaohaneState.toggleSurface(definition.surface)
            return
        }

        if (definition.serviceAction === "dropShelf") {
            const targetScreen = screen ?? null
            const width = Number(targetScreen?.width ?? 1920)
            const height = Number(targetScreen?.height ?? 1080)
            RaohaneDropShelf.showOnScreen([], width / 2, Math.max(80, height - 28), String(targetScreen?.name ?? ""))
        }
    }
}
