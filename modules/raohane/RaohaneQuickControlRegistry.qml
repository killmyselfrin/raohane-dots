pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var tileIds: [
        "network",
        "bluetooth",
        "nightLight",
        "gameMode",
        "keepAwake",
        "easyEffects"
    ]

    readonly property var defaultLayout: root.tileIds.slice()

    readonly property var definitions: ({
        network: {
            icon: "wifi",
            label: qsTr("Network"),
            description: qsTr("Wi-Fi status, network picker and radio toggle")
        },
        bluetooth: {
            icon: "bluetooth",
            label: qsTr("Bluetooth"),
            description: qsTr("Bluetooth power, connection state and manager")
        },
        nightLight: {
            icon: "bedtime",
            label: qsTr("Night Light"),
            description: qsTr("Color temperature and automatic night-light mode")
        },
        gameMode: {
            icon: "gamepad",
            label: qsTr("Game Mode"),
            description: qsTr("Low-latency Hyprland profile for games")
        },
        keepAwake: {
            icon: "coffee",
            label: qsTr("Keep Awake"),
            description: qsTr("Temporarily inhibit idle and sleep")
        },
        easyEffects: {
            icon: "instant_mix",
            label: qsTr("EasyEffects"),
            description: qsTr("Toggle audio processing and open EasyEffects")
        }
    })

    function definition(tileId: string): var {
        return root.definitions[String(tileId ?? "")] ?? null
    }

    function label(tileId: string): string {
        return root.definition(tileId)?.label ?? String(tileId ?? "")
    }

    function description(tileId: string): string {
        return root.definition(tileId)?.description ?? ""
    }

    function sanitizeLayout(value): var {
        const input = Array.isArray(value) ? value : root.defaultLayout
        const result = []
        for (let i = 0; i < input.length; ++i) {
            const id = String(input[i] ?? "").trim()
            if (root.tileIds.includes(id) && !result.includes(id))
                result.push(id)
        }
        return result.length > 0 ? result : root.defaultLayout.slice()
    }
}
