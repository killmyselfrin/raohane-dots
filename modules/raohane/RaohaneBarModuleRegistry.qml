pragma Singleton

import QtQuick

// Declarative catalog for the composable Raohane bar. The registry owns stable
// module ids and validation only; rendering stays in RaohaneBarModule and the
// persisted layout stays in RaohaneConfig.
QtObject {
    id: root

    readonly property var definitions: ({
        "launcher": {
            icon: "apps",
            role: "action",
            horizontal: true,
            vertical: true
        },
        "workspaces": {
            icon: "workspaces",
            role: "workspace",
            horizontal: true,
            vertical: true
        },
        "context": {
            icon: "dynamic_feed",
            role: "context",
            horizontal: true,
            vertical: true
        },
        "tray": {
            icon: "apps",
            role: "system",
            horizontal: true,
            vertical: false
        },
        "system": {
            icon: "wifi",
            role: "system",
            horizontal: true,
            vertical: true
        },
        "clock": {
            icon: "schedule",
            role: "clock",
            horizontal: true,
            vertical: true
        },
        "control": {
            icon: "tune",
            role: "action",
            horizontal: true,
            vertical: true
        },
        "separator": {
            icon: "horizontal_rule",
            role: "separator",
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

    function sanitizeZone(value, fallback, orientation: string): var {
        if (!Array.isArray(value))
            return fallback.slice()

        const result = []
        for (let i = 0; i < value.length && result.length < 16; ++i) {
            const id = String(value[i] ?? "")
            if (root.supports(id, orientation))
                result.push(id)
        }
        return result
    }

    function sanitizeLayout(value, orientation: string): var {
        const source = value && typeof value === "object" ? value : ({})
        const defaults = root.defaultLayout
        return {
            left: root.sanitizeZone(source.left, defaults.left, orientation),
            center: root.sanitizeZone(source.center, defaults.center, orientation),
            right: root.sanitizeZone(source.right, defaults.right, orientation)
        }
    }

    function zone(layout, zone: string, orientation: string): var {
        const sanitized = root.sanitizeLayout(layout, orientation)
        return sanitized[zone] ?? []
    }
}
