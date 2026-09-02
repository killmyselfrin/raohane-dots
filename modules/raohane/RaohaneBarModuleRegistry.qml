pragma Singleton

import QtQuick

// Declarative catalog for the composable Raohane bar. The registry owns stable
// module ids and validation only; rendering stays in RaohaneBarModule and the
// persisted layout stays in RaohaneConfig.
QtObject {
    id: root

    readonly property var moduleIds: [
        "launcher",
        "workspaces",
        "context",
        "tray",
        "system",
        "clock",
        "control",
        "separator"
    ]

    readonly property var definitions: ({
        "launcher": {
            icon: "apps",
            role: "action",
            preferredZone: "left",
            horizontal: true,
            vertical: true
        },
        "workspaces": {
            icon: "workspaces",
            role: "workspace",
            preferredZone: "left",
            horizontal: true,
            vertical: true
        },
        "context": {
            icon: "dynamic_feed",
            role: "context",
            preferredZone: "center",
            horizontal: true,
            vertical: true
        },
        "tray": {
            icon: "apps",
            role: "system",
            preferredZone: "right",
            horizontal: true,
            vertical: false
        },
        "system": {
            icon: "wifi",
            role: "system",
            preferredZone: "right",
            horizontal: true,
            vertical: true
        },
        "clock": {
            icon: "schedule",
            role: "clock",
            preferredZone: "right",
            horizontal: true,
            vertical: true
        },
        "control": {
            icon: "tune",
            role: "action",
            preferredZone: "right",
            horizontal: true,
            vertical: true
        },
        "separator": {
            icon: "horizontal_rule",
            role: "separator",
            preferredZone: "right",
            horizontal: true,
            vertical: true,
            repeatable: true
        }
    })

    readonly property var defaultLayout: ({
        left: ["launcher", "separator", "workspaces"],
        center: ["context"],
        right: ["tray", "system", "separator", "clock", "control"]
    })

    function definition(id: string): var {
        return root.definitions[String(id ?? "")] ?? null
    }

    function isKnown(id: string): bool {
        return root.definition(id) !== null
    }

    function supports(id: string, orientation: string): bool {
        const entry = root.definition(id)
        if (!entry)
            return false
        return orientation === "vertical" ? entry.vertical === true : entry.horizontal === true
    }

    function isRepeatable(id: string): bool {
        return root.definition(id)?.repeatable === true
    }

    function preferredZone(id: string): string {
        const requested = String(root.definition(id)?.preferredZone ?? "right")
        return ["left", "center", "right"].indexOf(requested) >= 0 ? requested : "right"
    }

    function label(id: string): string {
        switch (id) {
        case "launcher": return qsTr("Launcher")
        case "workspaces": return qsTr("Workspaces")
        case "context": return qsTr("Context Island")
        case "tray": return qsTr("System tray")
        case "system": return qsTr("System status")
        case "clock": return qsTr("Clock")
        case "control": return qsTr("Control Center")
        case "separator": return qsTr("Separator")
        default: return String(id ?? "")
        }
    }

    function description(id: string): string {
        switch (id) {
        case "launcher": return qsTr("Open the application launcher")
        case "workspaces": return qsTr("Show and switch Hyprland workspaces")
        case "context": return qsTr("Media, privacy and active-window context")
        case "tray": return qsTr("StatusNotifier system tray items")
        case "system": return qsTr("Network, Bluetooth, audio and notifications")
        case "clock": return qsTr("Time and optional date")
        case "control": return qsTr("Open the compact Control Center")
        case "separator": return qsTr("Visual spacing divider; can be added more than once")
        default: return ""
        }
    }

    function sanitizeZone(value, fallback, orientation: string): var {
        if (!Array.isArray(value))
            return fallback.slice()

        const result = []
        const seen = ({})
        for (let i = 0; i < value.length && result.length < 16; ++i) {
            const id = String(value[i] ?? "")
            if (!root.supports(id, orientation))
                continue
            if (!root.isRepeatable(id) && seen[id] === true)
                continue
            seen[id] = true
            result.push(id)
        }
        return result
    }

    function sanitizeLayout(value, orientation: string): var {
        const source = value && typeof value === "object" ? value : ({})
        const defaults = root.defaultLayout
        const zones = ["left", "center", "right"]
        const result = ({ left: [], center: [], right: [] })
        const seen = ({})

        for (let z = 0; z < zones.length; ++z) {
            const zone = zones[z]
            const fallback = defaults[zone] ?? []
            const raw = Array.isArray(source[zone]) ? source[zone] : fallback
            for (let i = 0; i < raw.length && result[zone].length < 16; ++i) {
                const id = String(raw[i] ?? "")
                if (!root.supports(id, orientation))
                    continue
                if (!root.isRepeatable(id) && seen[id] === true)
                    continue
                seen[id] = true
                result[zone].push(id)
            }
        }

        return result
    }

    function zone(layout, zone: string, orientation: string): var {
        const sanitized = root.sanitizeLayout(layout, orientation)
        return sanitized[zone] ?? []
    }
}
