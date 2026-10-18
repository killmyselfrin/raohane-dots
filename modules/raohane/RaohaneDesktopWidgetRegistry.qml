pragma Singleton

import QtQuick

// Single declarative catalog for native desktop widgets. Runtime rendering,
// Widget Studio and future persisted composition all consume the same IDs.
QtObject {
    id: root

    readonly property var widgetIds: ["clock", "context", "system", "motto"]

    readonly property var widgets: ({
        clock: {
            id: "clock",
            key: "desktopWidgetClock",
            source: "RaohaneDesktopClockWidget.qml",
            freeWidth: 420,
            freeHeight: 190,
            icon: "schedule",
            title: qsTr("Clock and date"),
            detail: qsTr("Large time with a restrained secondary label"),
            preferredZone: "primary"
        },
        context: {
            id: "context",
            key: "desktopWidgetContext",
            source: "RaohaneDesktopContextWidget.qml",
            freeWidth: 420,
            freeHeight: 164,
            icon: "music_note",
            title: qsTr("Media and live context"),
            detail: qsTr("Album art, track progress, privacy and active-window state"),
            preferredZone: "primary"
        },
        system: {
            id: "system",
            key: "desktopWidgetSystem",
            source: "RaohaneDesktopSystemWidget.qml",
            freeWidth: 278,
            freeHeight: 142,
            icon: "monitor_heart",
            title: qsTr("System status"),
            detail: qsTr("Network, audio level and host status"),
            preferredZone: "secondary"
        },
        motto: {
            id: "motto",
            key: "desktopWidgetMotto",
            source: "RaohaneDesktopMottoWidget.qml",
            freeWidth: 278,
            freeHeight: 46,
            icon: "spa",
            title: qsTr("Quiet motto"),
            detail: qsTr("A small ambient motto card"),
            preferredZone: "secondary"
        }
    })

    readonly property var layouts: [
        { key: "balanced", icon: "space_dashboard", title: qsTr("Balanced"), detail: qsTr("Clock left, status right") },
        { key: "left", icon: "align_horizontal_left", title: qsTr("Left rail"), detail: qsTr("Keep the composition together on the left") },
        { key: "right", icon: "align_horizontal_right", title: qsTr("Right rail"), detail: qsTr("Keep the composition together on the right") },
        { key: "free", icon: "dashboard_customize", title: qsTr("Free layout"), detail: qsTr("Position each widget freely") }
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

    function source(id: string): string {
        return root.definition(id)?.source ?? ""
    }
}
