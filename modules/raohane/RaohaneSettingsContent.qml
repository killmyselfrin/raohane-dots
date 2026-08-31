pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property int currentPage: 0
    property string pendingSearch: ""
    readonly property bool compactNav: width < 860

    readonly property var pages: [
        { key: "home", name: qsTr("Home"), icon: "home", group: qsTr("PERSONALIZE"), subtitle: qsTr("Raohane at a glance") },
        { key: "themes", name: qsTr("Themes"), icon: "palette", group: qsTr("PERSONALIZE"), subtitle: qsTr("Theme library and Style Studio") },
        { key: "interface", name: qsTr("Appearance"), icon: "wand_stars", group: qsTr("PERSONALIZE"), subtitle: qsTr("Screen chrome, corners and visual framing") },
        { key: "bar", name: qsTr("Bar & Dock"), icon: "dock_to_bottom", group: qsTr("SHELL"), subtitle: qsTr("Bar placement, reveal behavior and dock sizing") },
        { key: "quick", name: qsTr("Quick Controls"), icon: "instant_mix", group: qsTr("SHELL"), subtitle: qsTr("Choose the controls shown in the command surface") },
        { key: "general", name: qsTr("Media & OSD"), icon: "music_note", group: qsTr("SHELL"), subtitle: qsTr("Context Island, media overlay and display feedback") },
        { key: "desktop", name: qsTr("Desktop & Spaces"), icon: "view_quilt", group: qsTr("SHELL"), subtitle: qsTr("Wallpaper, transitions and workspace overview") },
        { key: "hyprland", name: qsTr("Hyprland"), icon: "select_window_2", group: qsTr("SYSTEM"), subtitle: qsTr("Compositor-facing behavior and interaction boundaries") },
        { key: "services", name: qsTr("Integrations"), icon: "hub", group: qsTr("SYSTEM"), subtitle: qsTr("External commands and native system helpers") },
        { key: "profile", name: qsTr("Profile"), icon: "account_circle", group: qsTr("SYSTEM"), subtitle: qsTr("Local identity used by Raohane surfaces") },
        { key: "about", name: qsTr("About"), icon: "info", group: qsTr("SYSTEM"), subtitle: qsTr("Version, runtime and system information") }
    ]

    function isFirstInGroup(index: int): bool {
        if (index <= 0)
            return true
        return root.pages[index - 1].group !== root.pages[index].group
    }

    function resolvePageIndex(requestedValue: string): int {
        let requested = String(requestedValue ?? "").trim().toLowerCase()
        const aliases = {
            "appearance": "interface",
            "display": "interface",
            "bar & dock": "bar",
            "dock": "bar",
            "quick controls": "quick",
            "media": "general",
            "media & osd": "general",
            "desktop & spaces": "desktop",
            "spaces": "desktop",
            "integrations": "services",
            "system": "services"
        }
        requested = aliases[requested] ?? requested
        return root.pages.findIndex(page => page.key === requested || page.name.toLowerCase() === requested)
    }

    function sectionDescription(key: string): string {
        switch (key) {
        case "quick": return qsTr("Choose which controls appear in the compact Quick Controls surface.")
        case "general": return qsTr("Tune Context Island, media presentation, OSD timing and night-light behavior.")
        case "bar": return qsTr("Control the horizontal or vertical bar and the application dock without changing the shell layout.")
        case "desktop": return qsTr("Configure wallpaper browsing, transition timing and the Spaces overview grid.")
        case "interface": return qsTr("Refine screen framing, rounding and hot-corner presentation.")
        case "services": return qsTr("Choose the commands Raohane launches for system configuration and helper tools.")
        case "hyprland": return qsTr("Configure Hyprland-facing interaction behavior owned by Raohane.")
        case "profile": return qsTr("Set the local display identity used by Settings and session surfaces.")
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

    function changeNumber(key: string, delta: real, minimum: real, maximum: real): void {
        const current = Number(RaohaneConfig[key] ?? 0)
        RaohaneConfig[key] = Math.max(minimum, Math.min(maximum, current + delta))
    }

    onCurrentPageChanged: {
        const page = pages[currentPage]
        if (page?.key === "about" && RaohaneSystemInfo.cpu === "")
            RaohaneSystemInfo.refresh()
        Qt.callLater(root.configureLoadedPage)
    }

    Connections {
        target: RaohaneState

        function onSettingsPageChanged(): void {
            if (RaohaneState.settingsPage === "")
                return

            const parts = RaohaneState.settingsPage.split(":")
            const requested = parts[0]
            root.pendingSearch = parts.length > 1 ? parts.slice(1).join(":") : ""

            const index = root.resolvePageIndex(requested)
            if (index >= 0)
                root.currentPage = index

            RaohaneState.settingsPage = ""
        }
    }

    function configureLoadedPage(): void {
        const page = root.pages[root.currentPage]
        if (!pageLoader.item || !page)
            return
        if (pageLoader.item.hasOwnProperty("sectionKey"))
            pageLoader.item.sectionKey = page.key
        if (root.pendingSearch !== "" && typeof pageLoader.item.goTo === "function")
            pageLoader.item.goTo(root.pendingSearch)
        root.pendingSearch = ""
    }

    Component {
        id: homePage
        RaohaneSettingsHome {}
    }

    Component {
        id: themesPage
        RaohaneThemeCatalog {}
    }

    Component {
        id: aboutPage
        RaohaneSettingsAbout {}
    }

    Component {
        id: nativeSectionPage

        Item {
            id: sectionRoot
            property string sectionKey: "general"

            function goTo(search: string): void {
                const needle = String(search ?? "").toLowerCase()
                if (needle === "")
                    return
                const entries = root.sectionEntries(sectionRoot.sectionKey)
                const index = entries.findIndex(entry => String(entry.label).toLowerCase().includes(needle) || entry.key.toLowerCase().includes(needle))
                if (index >= 0)
                    settingsFlick.contentY = Math.max(0, index * 78 - 24)
            }

            Flickable {
                id: settingsFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: sectionColumn.implicitHeight + 32
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 2500

                Column {
                    id: sectionColumn
                    y: 16
                    width: settingsFlick.width
                    spacing: 9

                    Text {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.sectionDescription(sectionRoot.sectionKey)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                        lineHeight: 1.18
                        wrapMode: Text.WordWrap
                    }

                    Item { width: 1; height: 3 }

                    Repeater {
                        model: root.sectionEntries(sectionRoot.sectionKey)

                        delegate: RaohaneSurface {
                            id: settingRow
                            required property var modelData

                            readonly property bool toggleRow: modelData.type === "toggle"

                            width: sectionColumn.width - 32
                            height: modelData.type === "text" ? 80 : 64
                            anchors.horizontalCenter: parent.horizontalCenter
                            surfaceRadius: 15
                            raised: false
                            interactive: toggleRow
                            hovered: settingMouse.containsMouse || activeFocus
                            pressed: toggleRow && settingMouse.pressed
                            showSheen: false
                            hoverScale: toggleRow ? 1.004 : 1
                            pressedScale: toggleRow ? 0.996 : 1
                            activeFocusOnTab: toggleRow

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        Layout.fillWidth: true
                                        text: settingRow.modelData.label
                                        color: RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: settingRow.modelData.detail
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        lineHeight: 1.15
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                RaohaneSwitch {
                                    visible: settingRow.toggleRow
                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 24
                                    checked: Boolean(RaohaneConfig[settingRow.modelData.key])
                                    enabled: false
                                    opacity: 1
                                }

                                RowLayout {
                                    visible: settingRow.modelData.type === "number"
                                    spacing: 6

                                    RaohaneIconButton {
                                        buttonSize: 28
                                        iconSize: 15
                                        icon: "remove"
                                        transparentIdle: true
                                        showSheen: false
                                        onClicked: root.changeNumber(settingRow.modelData.key, -Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                    }

                                    RaohaneSurface {
                                        Layout.preferredWidth: 66
                                        Layout.preferredHeight: 28
                                        surfaceRadius: 9
                                        showSheen: false

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(RaohaneConfig[settingRow.modelData.key])
                                            color: RaohaneTheme.text
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    RaohaneIconButton {
                                        buttonSize: 28
                                        iconSize: 15
                                        icon: "add"
                                        transparentIdle: true
                                        showSheen: false
                                        onClicked: root.changeNumber(settingRow.modelData.key, Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                    }
                                }

                                RaohaneSurface {
                                    visible: settingRow.modelData.type === "text"
                                    Layout.preferredWidth: Math.min(320, sectionRoot.width * 0.43)
                                    Layout.preferredHeight: 34
                                    surfaceRadius: 10
                                    hovered: field.activeFocus
                                    showSheen: false
                                    border.color: field.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                                    TextInput {
                                        id: field
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: String(RaohaneConfig[settingRow.modelData.key] ?? "")
                                        color: RaohaneTheme.text
                                        selectionColor: RaohaneTheme.accentSoft
                                        selectedTextColor: RaohaneTheme.text
                                        font.pixelSize: 9
                                        clip: true
                                        onEditingFinished: RaohaneConfig[settingRow.modelData.key] = text
                                    }
                                }
                            }

                            MouseArea {
                                id: settingMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: settingRow.toggleRow ? Qt.LeftButton : Qt.NoButton
                                cursorShape: settingRow.toggleRow ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: settingRow.forceActiveFocus()
                                onClicked: {
                                    if (settingRow.toggleRow)
                                        RaohaneConfig[settingRow.modelData.key] = !Boolean(RaohaneConfig[settingRow.modelData.key])
                                }
                            }

                            Keys.onPressed: event => {
                                if (!settingRow.toggleRow)
                                    return
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    RaohaneConfig[settingRow.modelData.key] = !Boolean(RaohaneConfig[settingRow.modelData.key])
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 16 }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        RaohaneSurface {
            Layout.fillHeight: true
            Layout.preferredWidth: root.compactNav ? 68 : 222
            surfaceRadius: 18
            raised: false
            showSheen: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 8

                RaohaneSurface {
                    id: profileShortcut
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.compactNav ? 48 : 58
                    surfaceRadius: 13
                    transparentIdle: true
                    showSheen: false
                    interactive: true
                    hovered: profileMouse.containsMouse || activeFocus
                    pressed: profileMouse.pressed
                    hoverScale: 1.01
                    pressedScale: RaohaneMotion.pressScale
                    activeFocusOnTab: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 10

                        RaohaneSurface {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            surfaceRadius: 13
                            active: root.pages[root.currentPage]?.key === "profile"
                            showSheen: false
                            clip: true

                            Image {
                                id: avatar
                                anchors.fill: parent
                                source: RaohaneConfig.profileAvatarPath !== "" ? "file://" + RaohaneConfig.profileAvatarPath : RaohanePaths.defaultAvatarUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            RaohaneIcon {
                                anchors.centerIn: parent
                                visible: !avatar.visible
                                text: "account_circle"
                                iconSize: 22
                                fill: root.pages[root.currentPage]?.key === "profile" ? 1 : 0
                                symbolWeight: root.pages[root.currentPage]?.key === "profile" ? 540 : 430
                                color: root.pages[root.currentPage]?.key === "profile" ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !root.compactNav
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneConfig.profileDisplayName === "" ? RaohaneSystemInfo.username : RaohaneConfig.profileDisplayName
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneSystemInfo.distroName || qsTr("Hyprland system")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: profileShortcut.forceActiveFocus()
                        onClicked: root.currentPage = root.resolvePageIndex("profile")
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.currentPage = root.resolvePageIndex("profile")
                            event.accepted = true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                Flickable {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: navColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2500

                    Column {
                        id: navColumn
                        width: navigation.width
                        spacing: 2

                        Repeater {
                            model: root.pages

                            delegate: Item {
                                id: navDelegate
                                required property var modelData
                                required property int index
                                readonly property bool firstInGroup: root.isFirstInGroup(index)

                                width: navColumn.width
                                height: root.compactNav ? 42 : (firstInGroup ? 61 : 42)

                                Text {
                                    visible: !root.compactNav && navDelegate.firstInGroup
                                    anchors {
                                        left: parent.left
                                        leftMargin: 7
                                        top: parent.top
                                        topMargin: 8
                                    }
                                    text: navDelegate.modelData.group
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                RaohaneSurface {
                                    id: navItem
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    height: 38
                                    surfaceRadius: 12
                                    active: root.currentPage === navDelegate.index
                                    transparentIdle: !active
                                    showSheen: false
                                    interactive: true
                                    hovered: navMouse.containsMouse || activeFocus
                                    pressed: navMouse.pressed
                                    hoverScale: 1.008
                                    pressedScale: RaohaneMotion.pressScale
                                    activeFocusOnTab: true

                                    Rectangle {
                                        visible: navItem.active
                                        anchors {
                                            left: parent.left
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: 3
                                        }
                                        width: 2
                                        height: 18
                                        radius: 1
                                        color: RaohaneTheme.accent
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: root.compactNav ? 0 : 12
                                        anchors.rightMargin: root.compactNav ? 0 : 9
                                        spacing: 9

                                        RaohaneIcon {
                                            Layout.alignment: root.compactNav ? Qt.AlignCenter : Qt.AlignVCenter
                                            text: navDelegate.modelData.icon
                                            iconSize: 17
                                            fill: navItem.active ? 1 : navItem.hovered ? 0.5 : 0
                                            symbolWeight: navItem.active ? 540 : navItem.hovered ? 500 : 430
                                            color: navItem.active ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: !root.compactNav
                                            text: navDelegate.modelData.name
                                            color: navItem.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                                            font.pixelSize: 9
                                            font.weight: navItem.active ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight

                                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                        }
                                    }

                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: navItem.forceActiveFocus()
                                        onClicked: {
                                            root.pendingSearch = ""
                                            root.currentPage = navDelegate.index
                                        }
                                    }

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            root.pendingSearch = ""
                                            root.currentPage = navDelegate.index
                                            event.accepted = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: configButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    surfaceRadius: 11
                    transparentIdle: true
                    showSheen: false
                    interactive: true
                    hovered: configMouse.containsMouse || activeFocus
                    pressed: configMouse.pressed
                    hoverScale: 1.008
                    pressedScale: RaohaneMotion.pressScale
                    activeFocusOnTab: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.compactNav ? 0 : 10
                        anchors.rightMargin: root.compactNav ? 0 : 8
                        spacing: 8

                        RaohaneIcon {
                            Layout.alignment: root.compactNav ? Qt.AlignCenter : Qt.AlignVCenter
                            text: copiedTimer.running ? "check_circle" : "description"
                            iconSize: 16
                            fill: copiedTimer.running ? 1 : 0
                            symbolWeight: copiedTimer.running ? 540 : configButton.hovered ? 500 : 430
                            color: copiedTimer.running ? RaohaneTheme.accent : RaohaneTheme.textMuted

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.compactNav
                            text: copiedTimer.running ? qsTr("Path copied") : qsTr("native.json")
                            color: copiedTimer.running ? RaohaneTheme.text : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            elide: Text.ElideRight

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        }
                    }

                    MouseArea {
                        id: configMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onPressed: configButton.forceActiveFocus()
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                Quickshell.clipboardText = RaohanePaths.nativeConfigFile
                                copiedTimer.restart()
                            } else {
                                Qt.openUrlExternally("file://" + RaohanePaths.nativeConfigFile)
                            }
                        }
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            Qt.openUrlExternally("file://" + RaohanePaths.nativeConfigFile)
                            event.accepted = true
                        }
                    }
                    Timer { id: copiedTimer; interval: 1400 }
                }
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            surfaceRadius: 18
            raised: false
            showSheen: false
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 17
                        anchors.rightMargin: 16
                        spacing: 11

                        RaohaneSurface {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            surfaceRadius: 10
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: root.pages[root.currentPage]?.icon ?? "settings"
                                iconSize: 17
                                fill: 1
                                symbolWeight: 540
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: root.pages[root.currentPage]?.name ?? qsTr("Settings")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.pages[root.currentPage]?.subtitle ?? ""
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        RaohaneSurface {
                            visible: !root.compactNav
                            Layout.preferredWidth: liveRow.implicitWidth + 14
                            Layout.preferredHeight: 24
                            surfaceRadius: 9
                            transparentIdle: true
                            showSheen: false

                            Row {
                                id: liveRow
                                anchors.centerIn: parent
                                spacing: 5
                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 3
                                    color: RaohaneTheme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: qsTr("LIVE")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 16
                            rightMargin: 16
                        }
                        height: 1
                        color: RaohaneTheme.borderFaint
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        anchors.margins: 10
                        sourceComponent: root.pages[root.currentPage]?.key === "home" ? homePage
                            : root.pages[root.currentPage]?.key === "themes" ? themesPage
                            : root.pages[root.currentPage]?.key === "about" ? aboutPage
                            : nativeSectionPage
                        onLoaded: Qt.callLater(root.configureLoadedPage)
                    }
                }
            }
        }
    }
}
