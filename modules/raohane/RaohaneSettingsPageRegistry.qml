pragma Singleton

import QtQuick

// Single source of truth for Settings navigation, routing, page loading and
// generic native setting schemas. Persistent values remain owned by RaohaneConfig.
QtObject {
    id: root

    readonly property var pages: [
        { key: "home", name: qsTr("Home"), icon: "home", group: qsTr("PERSONALIZE"), subtitle: qsTr("Raohane at a glance"), source: "RaohaneSettingsHome.qml" },
        { key: "themes", name: qsTr("Themes"), icon: "palette", group: qsTr("PERSONALIZE"), subtitle: qsTr("Theme library and Style Studio"), source: "RaohaneThemeCatalog.qml" },
        { key: "widgets", name: qsTr("Desktop Widgets"), icon: "widgets", group: qsTr("PERSONALIZE"), subtitle: qsTr("Choose the quiet information shown on your wallpaper"), source: "RaohaneWidgetStudio.qml" },
        { key: "interface", name: qsTr("Appearance"), icon: "wand_stars", group: qsTr("PERSONALIZE"), subtitle: qsTr("Screen chrome, corners and visual framing"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "bar", name: qsTr("Bar & Dock"), icon: "dock_to_bottom", group: qsTr("SHELL"), subtitle: qsTr("Placement, reveal behavior, modules and dock sizing"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "quick", name: qsTr("Quick Controls"), icon: "instant_mix", group: qsTr("SHELL"), subtitle: qsTr("Choose controls shown in the compact command surface"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "general", name: qsTr("Media & OSD"), icon: "music_note", group: qsTr("SHELL"), subtitle: qsTr("Context Island, media overlay and display feedback"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "desktop", name: qsTr("Desktop & Spaces"), icon: "view_quilt", group: qsTr("SHELL"), subtitle: qsTr("Wallpaper, transitions and workspace overview"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "displays", name: qsTr("Displays"), icon: "monitor", group: qsTr("SYSTEM"), subtitle: qsTr("Resolution, refresh rate, scale and multi-monitor layout"), source: "", externalSurface: "displaySettings" },
        { key: "hyprland", name: qsTr("Hyprland"), icon: "select_window_2", group: qsTr("SYSTEM"), subtitle: qsTr("Compositor-facing behavior and interaction boundaries"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "preferences", name: qsTr("Keyboard & Motion"), icon: "keyboard", group: qsTr("SYSTEM"), subtitle: qsTr("Shortcuts, application bindings and animation behavior"), source: "RaohaneSettingsPreferences.qml", hideHeader: true },
        { key: "services", name: qsTr("Integrations"), icon: "hub", group: qsTr("SYSTEM"), subtitle: qsTr("External commands and native system helpers"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "profile", name: qsTr("Profile"), icon: "account_circle", group: qsTr("SYSTEM"), subtitle: qsTr("Local identity used by Raohane surfaces"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "backup", name: qsTr("Backup & Restore"), icon: "inventory_2", group: qsTr("SYSTEM"), subtitle: qsTr("Portable Raohane settings, wallpapers and monitor profiles"), source: "RaohaneBackupSettings.qml" },
        { key: "language", name: qsTr("Language"), icon: "language", group: qsTr("SYSTEM"), subtitle: qsTr("Choose the language used by Raohane"), source: "RaohaneSettingsLanguage.qml" },
        { key: "about", name: qsTr("About"), icon: "info", group: qsTr("SYSTEM"), subtitle: qsTr("Version, runtime and system information"), source: "RaohaneSettingsAbout.qml" }
    ]

    readonly property var aliases: ({
        "appearance": "interface",
        "display": "displays",
        "monitor": "displays",
        "monitors": "displays",
        "bar & dock": "bar",
        "dock": "bar",
        "quick controls": "quick",
        "media": "general",
        "media & osd": "general",
        "desktop & spaces": "desktop",
        "spaces": "desktop",
        "integrations": "services",
        "system": "services",
        "restore": "backup",
        "backup & restore": "backup",
        "locale": "language"
    })

    readonly property var routeAliases: ({
        "keybinds": { page: "preferences", control: "keybinds" },
        "shortcuts": { page: "preferences", control: "keybinds" },
        "keyboard": { page: "preferences", control: "keybinds" },
        "motion": { page: "preferences", control: "motion" },
        "animations": { page: "preferences", control: "motion" },
        "animation": { page: "preferences", control: "motion" }
    })

    readonly property var sectionOrder: [
        "quick", "general", "bar", "desktop", "widgets", "interface", "hyprland", "services", "profile"
    ]

    readonly property var sectionSchemas: ({
        quick: {
            description: qsTr("Choose the controls that belong in the compact Control Center surface."),
            entries: [
                { type: "toggle", key: "quickSliderBrightness", label: qsTr("Brightness slider"), detail: qsTr("Show display brightness in Quick Controls") },
                { type: "toggle", key: "quickSliderVolume", label: qsTr("Volume slider"), detail: qsTr("Show speaker volume in Quick Controls") },
                { type: "toggle", key: "quickSliderMic", label: qsTr("Microphone slider"), detail: qsTr("Show microphone gain in Quick Controls") }
            ]
        },
        general: {
            description: qsTr("Tune Context Island, media presentation, OSD timing and night-light behavior."),
            entries: [
                { type: "toggle", key: "contextIslandEnabled", label: qsTr("Context Island"), detail: qsTr("Show live media, privacy and active-window context") },
                { type: "toggle", key: "mediaOverlayEnabled", label: qsTr("Media overlay"), detail: qsTr("Enable Raohane media overlay surfaces") },
                { type: "number", key: "osdTimeout", label: qsTr("OSD timeout"), detail: qsTr("Milliseconds before the native OSD closes"), min: 250, max: 10000, step: 250 },
                { type: "number", key: "colorTemperature", label: qsTr("Night temperature"), detail: qsTr("Target color temperature in Kelvin"), min: 1000, max: 10000, step: 250 },
                { type: "toggle", key: "nightLightAutomatic", label: qsTr("Automatic night light"), detail: qsTr("Allow Raohane display service to automate color temperature") }
            ]
        },
        bar: {
            description: qsTr("Control placement, reveal behavior and module composition while preserving Raohane's spatial rhythm."),
            entries: [
                { type: "toggle", key: "barBottom", label: qsTr("Bottom bar"), detail: qsTr("Place the horizontal bar on the bottom edge") },
                { type: "toggle", key: "barVertical", label: qsTr("Vertical bar"), detail: qsTr("Use the native vertical bar layout") },
                { type: "toggle", key: "barAutoHide", label: qsTr("Auto-hide bar"), detail: qsTr("Hide the bar until interaction requires it") },
                { type: "toggle", key: "barAutoHidePushWindows", label: qsTr("Push windows"), detail: qsTr("Reserve space while an auto-hidden bar is visible") },
                { type: "toggle", key: "barShowOnSuper", label: qsTr("Reveal on Super"), detail: qsTr("Temporarily reveal the bar with Super, including over fullscreen apps") },
                { type: "toggle", key: "barShowDate", label: qsTr("Show date"), detail: qsTr("Display the date alongside the clock") },
                { type: "toggle", key: "dockEnabled", label: qsTr("Dock"), detail: qsTr("Enable the Raohane dock") },
                { type: "toggle", key: "dockAutoHide", label: qsTr("Auto-hide dock"), detail: qsTr("Hide the dock when it is not in use") },
                { type: "number", key: "dockIconSize", label: qsTr("Dock icon size"), detail: qsTr("Native dock icon size in pixels"), min: 26, max: 72, step: 2 }
            ]
        },
        desktop: {
            description: qsTr("Configure wallpaper browsing, transitions and the Spaces overview grid."),
            entries: [
                { type: "toggle", key: "wallpaperPreview", label: qsTr("Wallpaper preview"), detail: qsTr("Preview wallpapers before applying them") },
                { type: "toggle", key: "wallpaperHideWhenFullscreen", label: qsTr("Hide wallpaper on fullscreen"), detail: qsTr("Reduce background rendering behind fullscreen clients") },
                { type: "number", key: "wallpaperColumns", label: qsTr("Wallpaper columns"), detail: qsTr("Columns in the wallpaper selector"), min: 2, max: 8, step: 1 },
                { type: "number", key: "wallpaperTransitionDuration", label: qsTr("Transition duration"), detail: qsTr("Wallpaper transition duration in milliseconds"), min: 0, max: 3000, step: 100 },
                { type: "number", key: "overviewWorkspaceCount", label: qsTr("Overview workspaces"), detail: qsTr("Workspace count represented in Overview"), min: 2, max: 12, step: 1 },
                { type: "number", key: "overviewColumns", label: qsTr("Overview columns"), detail: qsTr("Workspace grid columns"), min: 1, max: 4, step: 1 }
            ]
        },
        widgets: {
            description: qsTr("Build a calm desktop composition from native Raohane widgets."),
            entries: [
                { type: "toggle", key: "desktopWidgetsEnabled", label: qsTr("Desktop widgets"), detail: qsTr("Show the native widget layer on the wallpaper") },
                { type: "toggle", key: "desktopWidgetClock", label: qsTr("Clock and date"), detail: qsTr("Large time with a restrained Japanese label") },
                { type: "toggle", key: "desktopWidgetContext", label: qsTr("Live context"), detail: qsTr("Show media, privacy or active-window context") },
                { type: "toggle", key: "desktopWidgetSystem", label: qsTr("System status"), detail: qsTr("Show network, audio and host status") },
                { type: "toggle", key: "desktopWidgetMotto", label: qsTr("Quiet motto"), detail: qsTr("Add a small Japanese-inspired ambient card") },
                { type: "toggle", key: "desktopWidgetsCompact", label: qsTr("Compact layout"), detail: qsTr("Reduce spacing and card sizes on smaller screens") },
                { type: "number", key: "desktopWidgetsScale", label: qsTr("Widget scale"), detail: qsTr("Resize the complete desktop composition"), min: 0.75, max: 1.25, step: 0.05 },
                { type: "number", key: "desktopWidgetsOpacity", label: qsTr("Surface opacity"), detail: qsTr("Blend widgets softly into the wallpaper"), min: 0.45, max: 1.0, step: 0.05 }
            ]
        },
        interface: {
            description: qsTr("Refine screen framing, rounding and hot-corner presentation."),
            entries: [
                { type: "toggle", key: "frameEnabled", label: qsTr("Screen frame"), detail: qsTr("Draw the native Raohane screen frame") },
                { type: "number", key: "frameThickness", label: qsTr("Frame thickness"), detail: qsTr("Screen frame thickness in pixels"), min: 1, max: 24, step: 1 },
                { type: "toggle", key: "frameBarSideVisible", label: qsTr("Frame on bar edge"), detail: qsTr("Keep frame visible on the bar side") },
                { type: "number", key: "screenRoundingMode", label: qsTr("Rounding mode"), detail: qsTr("0 off · 1 always · 2 hide on fullscreen"), min: 0, max: 2, step: 1 },
                { type: "number", key: "screenCornerRadius", label: qsTr("Corner radius"), detail: qsTr("Fake-screen rounding radius in pixels"), min: 6, max: 96, step: 2 },
                { type: "toggle", key: "hotCornersEnabled", label: qsTr("Hot corners"), detail: qsTr("Enable native bottom-corner actions") },
                { type: "toggle", key: "hotCornerVisualize", label: qsTr("Visualize hot corners"), detail: qsTr("Show interaction regions while tuning them") }
            ]
        },
        hyprland: {
            description: qsTr("Configure Hyprland-facing interaction behavior owned by Raohane."),
            entries: [
                { type: "toggle", key: "integrationMode", label: qsTr("Integration mode"), detail: qsTr("Keep Hyprland integration features enabled") },
                { type: "toggle", key: "deadPixelWorkaround", label: qsTr("Dead-pixel workaround"), detail: qsTr("Enable the native screen-edge workaround") },
                { type: "toggle", key: "hotCornerValueScroll", label: qsTr("Hot-corner value scroll"), detail: qsTr("Allow scroll interaction in native hot corners") },
                { type: "toggle", key: "hotCornerClickless", label: qsTr("Clickless hot corners"), detail: qsTr("Trigger corner actions without a click") },
                { type: "number", key: "hotCornerRegionWidth", label: qsTr("Corner region width"), detail: qsTr("Hyprland edge interaction width"), min: 12, max: 600, step: 10 },
                { type: "number", key: "hotCornerRegionHeight", label: qsTr("Corner region height"), detail: qsTr("Hyprland edge interaction height"), min: 2, max: 80, step: 1 },
                { type: "number", key: "barShowOnSuperDelay", label: qsTr("Super reveal delay"), detail: qsTr("Delay before Super reveals the bar"), min: 0, max: 2000, step: 20 }
            ]
        },
        services: {
            description: qsTr("Choose commands Raohane launches for system configuration and helper tools."),
            entries: [
                { type: "text", key: "networkCommand", label: qsTr("Network command"), detail: qsTr("Program launched for Wi-Fi/network settings") },
                { type: "text", key: "networkEthernetCommand", label: qsTr("Ethernet command"), detail: qsTr("Program launched for wired network settings") },
                { type: "text", key: "bluetoothCommand", label: qsTr("Bluetooth command"), detail: qsTr("Program launched for Bluetooth management") },
                { type: "text", key: "taskManagerCommand", label: qsTr("Task manager command"), detail: qsTr("Optional process manager command") },
                { type: "text", key: "changePasswordCommand", label: qsTr("Password command"), detail: qsTr("Command used by profile/session password actions") }
            ]
        },
        profile: {
            description: qsTr("Set the local identity used by Settings and session surfaces."),
            entries: [
                { type: "text", key: "profileDisplayName", label: qsTr("Display name"), detail: qsTr("Name shown in Raohane profile surfaces") },
                { type: "text", key: "profileAvatarPath", label: qsTr("Avatar path"), detail: qsTr("Absolute local path to your profile image") }
            ]
        }
    })

    readonly property var searchOnlyEntries: [
        { section: "themes", key: "themePreset", label: qsTr("Theme library"), detail: qsTr("Themes") },
        { section: "bar", key: "barModuleLayout", label: qsTr("Bar modules"), detail: qsTr("Bar Studio") },
        { section: "quick", key: "quickControlTiles", label: qsTr("Quick Control tiles"), detail: qsTr("Quick Controls Studio") },
        { section: "widgets", key: "desktopWidgetsLayout", label: qsTr("Composition preset"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetComposition", label: qsTr("Widget positions"), detail: qsTr("Desktop Widgets") },
        { section: "preferences", key: "keybinds", label: qsTr("Keyboard shortcuts"), detail: qsTr("Keyboard & Motion") },
        { section: "preferences", key: "motion", label: qsTr("Motion & animations"), detail: qsTr("Keyboard & Motion") },
        { section: "backup", key: "backup", label: qsTr("Backup & Restore"), detail: qsTr("System") },
        { section: "language", key: "language", label: qsTr("Interface language"), detail: qsTr("System") }
    ]

    function isFirstInGroup(index: int): bool {
        return index <= 0 || root.pages[index - 1].group !== root.pages[index].group
    }

    function page(key: string): var {
        const normalized = String(key ?? "").trim().toLowerCase()
        return root.pages.find(item => item.key === normalized) ?? null
    }

    function resolvePageIndex(requestedValue: string): int {
        let requested = String(requestedValue ?? "").trim().toLowerCase()
        requested = root.aliases[requested] ?? requested
        return root.pages.findIndex(item => item.key === requested || item.name.toLowerCase() === requested)
    }

    function resolveRoute(requestedValue: string, control: string): var {
        const requested = String(requestedValue ?? "").trim().toLowerCase()
        const explicitControl = String(control ?? "").trim()
        if (explicitControl === "") {
            const routed = root.routeAliases[requested]
            if (routed)
                return { page: routed.page, control: routed.control }
        }
        const index = root.resolvePageIndex(requested)
        if (index < 0)
            return null
        return { page: root.pages[index].key, control: explicitControl }
    }

    function sectionSchema(key: string): var {
        const normalized = String(key ?? "").trim().toLowerCase()
        return root.sectionSchemas[normalized] ?? null
    }

    function sectionDescription(key: string): string {
        return root.sectionSchema(key)?.description ?? ""
    }

    function sectionEntries(key: string): var {
        return root.sectionSchema(key)?.entries ?? []
    }

    function searchEntries(): var {
        const result = root.searchOnlyEntries.slice()
        for (let i = 0; i < root.sectionOrder.length; ++i) {
            const sectionKey = root.sectionOrder[i]
            const pageInfo = root.page(sectionKey)
            const entries = root.sectionEntries(sectionKey)
            for (let j = 0; j < entries.length; ++j) {
                const entry = entries[j]
                result.push({
                    section: sectionKey,
                    key: entry.key,
                    label: entry.label,
                    detail: pageInfo?.name ?? sectionKey
                })
            }
        }
        return result
    }
}
