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
        { key: "home", name: qsTr("Home"), icon: "space_dashboard" },
        { key: "themes", name: qsTr("Themes"), icon: "palette" },
        { key: "quick", name: qsTr("Quick"), icon: "instant_mix" },
        { key: "general", name: qsTr("General"), icon: "browse" },
        { key: "bar", name: qsTr("Bar"), icon: "toast" },
        { key: "desktop", name: qsTr("Desktop"), icon: "texture" },
        { key: "interface", name: qsTr("Interface"), icon: "bottom_app_bar" },
        { key: "services", name: qsTr("Services"), icon: "settings" },
        { key: "hyprland", name: qsTr("Hyprland"), icon: "select_window_2" },
        { key: "profile", name: qsTr("Profile"), icon: "account_circle" },
        { key: "about", name: qsTr("About"), icon: "info" }
    ]

    function sectionDescription(key: string): string {
        switch (key) {
        case "quick": return qsTr("Choose which controls appear in the compact quick-control surface.")
        case "general": return qsTr("Shell-wide behavior, media surfaces, OSD timing and display temperature.")
        case "bar": return qsTr("Horizontal/vertical bar behavior and dock presentation.")
        case "desktop": return qsTr("Wallpaper browsing, transitions and overview layout.")
        case "interface": return qsTr("Screen frame, rounding and hot-corner presentation.")
        case "services": return qsTr("Commands Raohane launches for system configuration helpers.")
        case "hyprland": return qsTr("Hyprland-facing workspace and interaction behavior owned by Raohane.")
        case "profile": return qsTr("Local display identity used by the Settings and session surfaces.")
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
                { type: "toggle", key: "contextIslandEnabled", label: qsTr("Context island"), detail: qsTr("Show live media, privacy and active-window context") },
                { type: "toggle", key: "mediaOverlayEnabled", label: qsTr("Media overlay"), detail: qsTr("Enable Raohane media overlay surfaces") },
                { type: "toggle", key: "integrationMode", label: qsTr("Integration mode"), detail: qsTr("Keep Hyprland integration features enabled") },
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

            const index = root.pages.findIndex(page => page.name.toLowerCase() === requested.toLowerCase() || page.key === requested.toLowerCase())
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
                    settingsFlick.contentY = Math.max(0, index * 78 - 20)
            }

            Flickable {
                id: settingsFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: sectionColumn.implicitHeight + 28
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sectionColumn
                    width: settingsFlick.width
                    spacing: 10
                    topPadding: 14
                    bottomPadding: 14

                    Text {
                        width: parent.width - 28
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.sectionDescription(sectionRoot.sectionKey)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: root.sectionEntries(sectionRoot.sectionKey)

                        delegate: Rectangle {
                            id: settingRow
                            required property var modelData

                            width: sectionColumn.width - 28
                            height: modelData.type === "text" ? 82 : 64
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 15
                            color: settingMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: settingMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

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
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Rectangle {
                                    visible: settingRow.modelData.type === "toggle"
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: Boolean(RaohaneConfig[settingRow.modelData.key]) ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
                                    border.width: 1
                                    border.color: Boolean(RaohaneConfig[settingRow.modelData.key]) ? RaohaneTheme.accentBorder : RaohaneTheme.border

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Boolean(RaohaneConfig[settingRow.modelData.key]) ? parent.width - width - 4 : 4
                                        color: Boolean(RaohaneConfig[settingRow.modelData.key]) ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                        Behavior on x { NumberAnimation { duration: RaohaneTheme.animationFast } }
                                    }
                                }

                                RowLayout {
                                    visible: settingRow.modelData.type === "number"
                                    spacing: 5

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 9
                                        color: minusMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                                        border.width: 1
                                        border.color: RaohaneTheme.border
                                        Text { anchors.centerIn: parent; text: "−"; color: RaohaneTheme.text; font.pixelSize: 15 }
                                        MouseArea {
                                            id: minusMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.changeNumber(settingRow.modelData.key, -Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 58
                                        horizontalAlignment: Text.AlignHCenter
                                        text: String(RaohaneConfig[settingRow.modelData.key])
                                        color: RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 9
                                        color: plusMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                                        border.width: 1
                                        border.color: RaohaneTheme.border
                                        Text { anchors.centerIn: parent; text: "+"; color: RaohaneTheme.text; font.pixelSize: 14 }
                                        MouseArea {
                                            id: plusMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.changeNumber(settingRow.modelData.key, Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: settingRow.modelData.type === "text"
                                    Layout.preferredWidth: Math.min(310, sectionRoot.width * 0.42)
                                    Layout.preferredHeight: 34
                                    radius: 10
                                    color: RaohaneTheme.surfaceSubtle
                                    border.width: 1
                                    border.color: field.activeFocus ? RaohaneTheme.borderStrong : RaohaneTheme.border

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
                                acceptedButtons: settingRow.modelData.type === "toggle" ? Qt.LeftButton : Qt.NoButton
                                cursorShape: settingRow.modelData.type === "toggle" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (settingRow.modelData.type === "toggle")
                                        RaohaneConfig[settingRow.modelData.key] = !Boolean(RaohaneConfig[settingRow.modelData.key])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.compactNav ? 70 : 214
            radius: 18
            color: RaohaneTheme.surface
            border.width: 1
            border.color: RaohaneTheme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 9

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66
                    radius: 16
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 9

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 14
                            color: RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: RaohaneTheme.border
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
                                iconSize: 23
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !root.compactNav
                            spacing: -1

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
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = root.pages.findIndex(page => page.key === "profile")
                    }
                }

                Text {
                    visible: !root.compactNav
                    text: "CONFIGURATION"
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.letterSpacing: 0.8
                    font.weight: Font.Medium
                    Layout.leftMargin: 5
                }

                ListView {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.pages
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: navItem
                        required property var modelData
                        required property int index
                        width: navigation.width
                        height: 40
                        radius: 12
                        color: root.currentPage === index ? RaohaneTheme.accentSoft : navMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                        border.width: root.currentPage === index ? 1 : 0
                        border.color: root.currentPage === index ? RaohaneTheme.accentBorder : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 9
                            spacing: 9

                            RaohaneIcon { text: navItem.modelData.icon; iconSize: 17; color: root.currentPage === navItem.index ? RaohaneTheme.accent : RaohaneTheme.textMuted }
                            Text {
                                Layout.fillWidth: true
                                visible: !root.compactNav
                                text: navItem.modelData.name
                                color: root.currentPage === navItem.index ? RaohaneTheme.text : RaohaneTheme.textMuted
                                font.pixelSize: 10
                                font.weight: root.currentPage === navItem.index ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.pendingSearch = ""; root.currentPage = navItem.index }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 12
                    color: configMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 9
                        spacing: 9
                        RaohaneIcon { text: "description"; iconSize: 17; color: RaohaneTheme.textMuted }
                        Text { Layout.fillWidth: true; visible: !root.compactNav; text: copiedTimer.running ? qsTr("Path copied") : qsTr("native.json"); color: RaohaneTheme.textMuted; font.pixelSize: 9; elide: Text.ElideRight }
                    }

                    MouseArea {
                        id: configMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                Quickshell.clipboardText = RaohanePaths.nativeConfigFile
                                copiedTimer.restart()
                            } else {
                                Qt.openUrlExternally("file://" + RaohanePaths.nativeConfigFile)
                            }
                        }
                    }
                    Timer { id: copiedTimer; interval: 1400 }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: RaohaneTheme.surfaceSubtle
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: RaohaneTheme.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 10
                            color: RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: RaohaneTheme.border
                            RaohaneIcon { anchors.centerIn: parent; text: root.pages[root.currentPage]?.icon ?? "settings"; iconSize: 17; color: RaohaneTheme.accent }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1
                            Text { Layout.fillWidth: true; text: root.pages[root.currentPage]?.name ?? qsTr("Settings"); color: RaohaneTheme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                            Text { Layout.fillWidth: true; text: qsTr("Live settings · ~/.config/raohane/native.json"); color: RaohaneTheme.textMuted; font.pixelSize: 8; elide: Text.ElideRight }
                        }

                        Rectangle { width: 6; height: 6; radius: 3; color: RaohaneTheme.accent }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        anchors.margins: 8
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
