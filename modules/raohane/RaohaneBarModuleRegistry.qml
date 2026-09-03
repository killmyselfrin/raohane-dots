pragma Singleton

import QtQuick

// Declarative catalog for both Raohane bar orientations. Stable ids live here;
// rendering stays in RaohaneBarModule and each orientation persists its own
// left/center/right (start/center/end) composition in RaohaneConfig.
QtObject {
    id: root

    readonly property var moduleIds: [
        "launcher",
        "workspaces",
        "context",
        "tray",
        "system",
        "network",
        "bluetooth",
        "notifications",
        "clock",
        "audio",
        "control",
        "session",
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
            vertical: false
        },
        "network": {
            icon: "wifi",
            role: "system",
            preferredZone: "right",
            horizontal: false,
            vertical: true
        },
        "bluetooth": {
            icon: "bluetooth",
            role: "system",
            preferredZone: "right",
            horizontal: false,
            vertical: true
        },
        "notifications": {
            icon: "notifications",
            role: "system",
            preferredZone: "right",
            horizontal: false,
            vertical: true
        },
        "clock": {
            icon: "schedule",
            role: "clock",
            preferredZone: "right",
            horizontal: true,
            vertical: true
        },
        "audio": {
            icon: "volume_up",
            role: "system",
            preferredZone: "right",
            horizontal: false,
            vertical: true
        },
        "control": {
            icon: "tune",
            role: "action",
            preferredZone: "right",
            horizontal: true,
            vertical: true
        },
        "session": {
            icon: "power_settings_new",
            role: "action",
            preferredZone: "right",
            horizontal: false,
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

    readonly property var defaultVerticalLayout: ({
        left: ["launcher", "separator", "workspaces"],
        center: ["context"],
        right: ["network", "bluetooth", "notifications", "separator", "clock", "separator", "audio", "control", "session"]
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
        case "network": return qsTr("Network")
        case "bluetooth": return qsTr("Bluetooth")
        case "notifications": return qsTr("Notifications")
        case "clock": return qsTr("Clock")
        case "audio": return qsTr("Audio")
        case "control": return qsTr("Control Center")
        case "session": return qsTr("Session")
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
        case "network": return qsTr("Show network state and open Control Center")
        case "bluetooth": return qsTr("Show Bluetooth state and toggle the adapter")
        case "notifications": return qsTr("Show notification state and unread count")
        case "clock": return qsTr("Time and optional date")
        case "audio": return qsTr("Show volume state and toggle mute")
        case "control": return qsTr("Open the compact Control Center")
        case "session": return qsTr("Open session and power actions")
        case "separator": return qsTr("Visual spacing divider; can be added more than once")
        default: return ""
        }
    }

    function defaultLayoutFor(orientation: string): var {
        return orientation === "vertical" ? root.defaultVerticalLayout : root.defaultLayout
    }

    function cloneLayout(layout): var {
        return {
            left: Array.isArray(layout?.left) ? layout.left.slice() : [],
            center: Array.isArray(layout?.center) ? layout.center.slice() : [],
            right: Array.isArray(layout?.right) ? layout.right.slice() : []
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
        const defaults = root.defaultLayoutFor(orientation)
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

        // A completely empty saved composition makes the bar impossible to
        // recover from without editing native.json by hand. Treat that state
        // as corruption and restore the orientation defaults. Individual
        // zones may still be intentionally empty.
        if (result.left.length + result.center.length + result.right.length === 0)
            return root.cloneLayout(defaults)

        return result
    }

    function zone(layout, zone: string, orientation: string): var {
        const sanitized = root.sanitizeLayout(layout, orientation)
        return sanitized[zone] ?? []
    }
}
