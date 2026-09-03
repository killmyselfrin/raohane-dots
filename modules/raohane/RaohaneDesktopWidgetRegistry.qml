pragma Singleton

import QtQuick

// Declarative metadata for Raohane desktop widgets. Runtime state and
// persistence stay owned by RaohaneDesktopWidgets and RaohaneConfig.
QtObject {
    id: root

    readonly property var widgetIds: ["clock", "context", "system", "motto"]

    readonly property var widgets: ({
        clock: {
            id: "clock",
            key: "desktopWidgetClock",
            icon: "schedule",
            title: qsTr("Clock and date"),
            detail: qsTr("Large time with a restrained Japanese label"),
            preferredZone: "primary"
        },
        context: {
            id: "context",
            key: "desktopWidgetContext",
            icon: "music_note",
            title: qsTr("Media and live context"),
            detail: qsTr("Album art, track progress, privacy and active-window state"),
            preferredZone: "primary"
        },
        system: {
            id: "system",
            key: "desktopWidgetSystem",
            icon: "monitor_heart",
            title: qsTr("System status"),
            detail: qsTr("Network, audio level and host status"),
            preferredZone: "secondary"
        },
        motto: {
            id: "motto",
            key: "desktopWidgetMotto",
            icon: "spa",
            title: qsTr("Quiet motto"),
            detail: qsTr("A small ambient Japanese-inspired card"),
            preferredZone: "secondary"
        }
    })

    readonly property var layouts: [
        { key: "balanced", icon: "space_dashboard", title: qsTr("Balanced"), detail: qsTr("Clock left, status right") },
        { key: "left", icon: "align_horizontal_left", title: qsTr("Left rail"), detail: qsTr("Keep the composition together on the left") },
        { key: "right", icon: "align_horizontal_right", title: qsTr("Right rail"), detail: qsTr("Keep the composition together on the right") }
    ]

    function definition(id: string): var {
        const normalized = String(id ?? "").trim()
        return root.widgets[normalized] ?? null
    }

    function definitions(): var {
        return root.widgetIds.map(id => root.widgets[id])
    }

    function idsForZone(zone: string): var {
        const normalized = String(zone ?? "").trim()
        return root.widgetIds.filter(id => root.widgets[id]?.preferredZone === normalized)
    }

    function configKey(id: string): string {
        return root.definition(id)?.key ?? ""
    }
}
