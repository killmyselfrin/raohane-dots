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
        { key: "services", name: qsTr("Integrations"), icon: "hub", group: qsTr("SYSTEM"), subtitle: qsTr("External commands and native system helpers"), source: "RaohaneSettingsSectionPage.qml" },
        { key: "profile", name: qsTr("Profile"), icon: "account_circle", group: qsTr("SYSTEM"), subtitle: qsTr("Local identity used by Raohane surfaces"), source: "RaohaneSettingsSectionPage.qml" },
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
        "system": "services"
    })

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

    function sectionDescription(key: string): string {
        switch (key) {
        case "quick": return qsTr("Choose the controls that belong in the compact Control Center surface.")
        case "general": return qsTr("Tune Context Island, media presentation, OSD timing and night-light behavior.")
        case "bar": return qsTr("Control placement, reveal behavior and module composition while preserving Raohane's spatial rhythm.")
        case "desktop": return qsTr("Configure wallpaper browsing, transitions and the Spaces overview grid.")
        case "widgets": return qsTr("Build a calm desktop composition from native Raohane widgets.")
        case "interface": return qsTr("Refine screen framing, rounding and hot-corner presentation.")
        case "services": return qsTr("Choose commands Raohane launches for system configuration and helper tools.")
        case "hyprland": return qsTr("Configure Hyprland-facing interaction behavior owned by Raohane.")
        case "profile": return qsTr("Set the local identity used by Settings and session surfaces.")
        default: return ""
        }
    }

    function sectionEntries(key: string): var {
        switch (key) {
        case "quick":
            return [
                { type: "toggle", key: "quickSliderBrightness", label: qsTr("Brightness slider"), detail: qsTr("Show display brightness in Quick Controls") },
                { type: "toggle", key: "quickSliderVolume", label: qsTr("Volume slider"), detail: qsTr("Show speaker volume in Quick Controls") },
                { type: "toggle", key: "quickSliderMic", label: qsTr("Microphone slider"), detail: qsTr("Show microphone gain in Quick Controls") }
            ]
        case "general":
            return [
                { type: "toggle", key: "contextIslandEnabled", label: qsTr("Context Island"), detail: qsTr("Show live media, privacy and active-window context") },
                { type: "toggle", key: "mediaOverlayEnabled", label: qsTr("Media overlay"), detail: qsTr("Enable Raohane media overlay surfaces") },
                { type: "number", key: "osdTimeout", label: qsTr("OSD timeout"), detail: qsTr("Milliseconds before the native OSD closes"), min: 250, max: 10000, step: 250 },
                { type: "number", key: "colorTemperature", label: qsTr("Night temperature"), detail: qsTr("Target color temperature in Kelvin"), min: 1000, max: 10000, step: 250 },
                { type: "toggle", key: "nightLightAutomatic", label: qsTr("Automatic night light"), detail: qsTr("Allow Raohane display service to automate color temperature") }
            ]
        case "bar":
            return [
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
        case "desktop":
            return [
                { type: "toggle", key: "wallpaperPreview", label: qsTr("Wallpaper preview"), detail: qsTr("Preview wallpapers before applying them") },
                { type: "toggle", key: "wallpaperHideWhenFullscreen", label: qsTr("Hide wallpaper on fullscreen"), detail: qsTr("Reduce background rendering behind fullscreen clients") },
                { type: "number", key: "wallpaperColumns", label: qsTr("Wallpaper columns"), detail: qsTr("Columns in the wallpaper selector"), min: 2, max: 8, step: 1 },
                { type: "number", key: "wallpaperTransitionDuration", label: qsTr("Transition duration"), detail: qsTr("Wallpaper transition duration in milliseconds"), min: 0, max: 3000, step: 100 },
                { type: "number", key: "overviewWorkspaceCount", label: qsTr("Overview workspaces"), detail: qsTr("Workspace count represented in Overview"), min: 2, max: 12, step: 1 },
                { type: "number", key: "overviewColumns", label: qsTr("Overview columns"), detail: qsTr("Workspace grid columns"), min: 1, max: 4, step: 1 }
            ]
        case "widgets":
            return [
                { type: "toggle", key: "desktopWidgetsEnabled", label: qsTr("Desktop widgets"), detail: qsTr("Show the native widget layer on the wallpaper") },
                { type: "toggle", key: "desktopWidgetClock", label: qsTr("Clock and date"), detail: qsTr("Large time with a restrained Japanese label") },
                { type: "toggle", key: "desktopWidgetContext", label: qsTr("Live context"), detail: qsTr("Show media, privacy or active-window context") },
                { type: "toggle", key: "desktopWidgetSystem", label: qsTr("System status"), detail: qsTr("Show network, audio and host status") },
                { type: "toggle", key: "desktopWidgetMotto", label: qsTr("Quiet motto"), detail: qsTr("Add a small Japanese-inspired ambient card") },
                { type: "toggle", key: "desktopWidgetsCompact", label: qsTr("Compact layout"), detail: qsTr("Reduce spacing and card sizes on smaller screens") },
                { type: "number", key: "desktopWidgetsScale", label: qsTr("Widget scale"), detail: qsTr("Resize the complete desktop composition"), min: 0.75, max: 1.25, step: 0.05 },
                { type: "number", key: "desktopWidgetsOpacity", label: qsTr("Surface opacity"), detail: qsTr("Blend widgets softly into the wallpaper"), min: 0.45, max: 1.0, step: 0.05 }
            ]
        case "interface":
            return [
                { type: "toggle", key: "frameEnabled", label: qsTr("Screen frame"), detail: qsTr("Draw the native Raohane screen frame") },
                { type: "number", key: "frameThickness", label: qsTr("Frame thickness"), detail: qsTr("Screen frame thickness in pixels"), min: 1, max: 24, step: 1 },
                { type: "toggle", key: "frameBarSideVisible", label: qsTr("Frame on bar edge"), detail: qsTr("Keep frame visible on the bar side") },
                { type: "number", key: "screenRoundingMode", label: qsTr("Rounding mode"), detail: qsTr("0 off · 1 always · 2 hide on fullscreen"), min: 0, max: 2, step: 1 },
                { type: "number", key: "screenCornerRadius", label: qsTr("Corner radius"), detail: qsTr("Fake-screen rounding radius in pixels"), min: 6, max: 96, step: 2 },
                { type: "toggle", key: "hotCornersEnabled", label: qsTr("Hot corners"), detail: qsTr("Enable native bottom-corner actions") },
                { type: "toggle", key: "hotCornerVisualize", label: qsTr("Visualize hot corners"), detail: qsTr("Show interaction regions while tuning them") }
            ]
        case "services":
            return [
                { type: "text", key: "networkCommand", label: qsTr("Network command"), detail: qsTr("Program launched for Wi-Fi/network settings") },
                { type: "text", key: "networkEthernetCommand", label: qsTr("Ethernet command"), detail: qsTr("Program launched for wired network settings") },
                { type: "text", key: "bluetoothCommand", label: qsTr("Bluetooth command"), detail: qsTr("Program launched for Bluetooth management") },
                { type: "text", key: "taskManagerCommand", label: qsTr("Task manager command"), detail: qsTr("Optional process manager command") },
                { type: "text", key: "changePasswordCommand", label: qsTr("Password command"), detail: qsTr("Command used by profile/session password actions") }
            ]
        case "hyprland":
            return [
                { type: "toggle", key: "integrationMode", label: qsTr("Integration mode"), detail: qsTr("Keep Hyprland integration features enabled") },
                { type: "toggle", key: "deadPixelWorkaround", label: qsTr("Dead-pixel workaround"), detail: qsTr("Enable the native screen-edge workaround") },
                { type: "toggle", key: "hotCornerValueScroll", label: qsTr("Hot-corner value scroll"), detail: qsTr("Allow scroll interaction in native hot corners") },
                { type: "toggle", key: "hotCornerClickless", label: qsTr("Clickless hot corners"), detail: qsTr("Trigger corner actions without a click") },
                { type: "number", key: "hotCornerRegionWidth", label: qsTr("Corner region width"), detail: qsTr("Hyprland edge interaction width"), min: 12, max: 600, step: 10 },
                { type: "number", key: "hotCornerRegionHeight", label: qsTr("Corner region height"), detail: qsTr("Hyprland edge interaction height"), min: 2, max: 80, step: 1 },
                { type: "number", key: "barShowOnSuperDelay", label: qsTr("Super reveal delay"), detail: qsTr("Delay before Super reveals the bar"), min: 0, max: 2000, step: 20 }
            ]
        case "profile":
            return [
                { type: "text", key: "profileDisplayName", label: qsTr("Display name"), detail: qsTr("Name shown in Raohane profile surfaces") },
                { type: "text", key: "profileAvatarPath", label: qsTr("Avatar path"), detail: qsTr("Absolute local path to your profile image") }
            ]
        default:
            return []
        }
    }

    function searchEntries(): var {
        const result = [
            { section: "themes", key: "themePreset", label: qsTr("Theme library"), detail: qsTr("Themes") },
            { section: "bar", key: "barModuleLayout", label: qsTr("Bar modules"), detail: qsTr("Bar Studio") },
            { section: "widgets", key: "desktopWidgetsLayout", label: qsTr("Composition preset"), detail: qsTr("Desktop Widgets") }
        ]
        const sectionKeys = ["quick", "general", "bar", "desktop", "widgets", "interface", "hyprland", "services", "profile"]
        for (let i = 0; i < sectionKeys.length; ++i) {
            const sectionKey = sectionKeys[i]
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
