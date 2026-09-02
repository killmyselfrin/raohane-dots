pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string query: ""
    property int currentIndex: 0
    readonly property bool active: searchInput.activeFocus || root.query.length > 0
    readonly property var entries: [
        { section: "themes", key: "themePreset", label: qsTr("Theme library"), detail: qsTr("Themes") },
        { section: "quick", key: "quickSliderBrightness", label: qsTr("Brightness slider"), detail: qsTr("Quick Controls") },
        { section: "quick", key: "quickSliderVolume", label: qsTr("Volume slider"), detail: qsTr("Quick Controls") },
        { section: "quick", key: "quickSliderMic", label: qsTr("Microphone slider"), detail: qsTr("Quick Controls") },
        { section: "general", key: "contextIslandEnabled", label: qsTr("Context Island"), detail: qsTr("Media & OSD") },
        { section: "general", key: "mediaOverlayEnabled", label: qsTr("Media overlay"), detail: qsTr("Media & OSD") },
        { section: "general", key: "osdTimeout", label: qsTr("OSD timeout"), detail: qsTr("Media & OSD") },
        { section: "general", key: "colorTemperature", label: qsTr("Night temperature"), detail: qsTr("Media & OSD") },
        { section: "general", key: "nightLightAutomatic", label: qsTr("Automatic night light"), detail: qsTr("Media & OSD") },
        { section: "bar", key: "barBottom", label: qsTr("Bottom bar"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "barVertical", label: qsTr("Vertical bar"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "barAutoHide", label: qsTr("Auto-hide bar"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "barAutoHidePushWindows", label: qsTr("Push windows"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "barShowOnSuper", label: qsTr("Reveal on Super"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "barShowDate", label: qsTr("Show date"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "dockEnabled", label: qsTr("Dock"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "dockAutoHide", label: qsTr("Auto-hide dock"), detail: qsTr("Bar & Dock") },
        { section: "bar", key: "dockIconSize", label: qsTr("Dock icon size"), detail: qsTr("Bar & Dock") },
        { section: "desktop", key: "wallpaperPreview", label: qsTr("Wallpaper preview"), detail: qsTr("Desktop & Spaces") },
        { section: "desktop", key: "wallpaperHideWhenFullscreen", label: qsTr("Hide wallpaper on fullscreen"), detail: qsTr("Desktop & Spaces") },
        { section: "desktop", key: "wallpaperColumns", label: qsTr("Wallpaper columns"), detail: qsTr("Desktop & Spaces") },
        { section: "desktop", key: "wallpaperTransitionDuration", label: qsTr("Transition duration"), detail: qsTr("Desktop & Spaces") },
        { section: "desktop", key: "overviewWorkspaceCount", label: qsTr("Overview workspaces"), detail: qsTr("Desktop & Spaces") },
        { section: "desktop", key: "overviewColumns", label: qsTr("Overview columns"), detail: qsTr("Desktop & Spaces") },
        { section: "widgets", key: "desktopWidgetsEnabled", label: qsTr("Desktop widgets"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetClock", label: qsTr("Clock and date"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetContext", label: qsTr("Live context"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetSystem", label: qsTr("System status"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetMotto", label: qsTr("Quiet motto"), detail: qsTr("Desktop Widgets") },
        { section: "widgets", key: "desktopWidgetsCompact", label: qsTr("Compact layout"), detail: qsTr("Desktop Widgets") },
        { section: "interface", key: "frameEnabled", label: qsTr("Screen frame"), detail: qsTr("Appearance") },
        { section: "interface", key: "frameThickness", label: qsTr("Frame thickness"), detail: qsTr("Appearance") },
        { section: "interface", key: "frameBarSideVisible", label: qsTr("Frame on bar edge"), detail: qsTr("Appearance") },
        { section: "interface", key: "screenRoundingMode", label: qsTr("Rounding mode"), detail: qsTr("Appearance") },
        { section: "interface", key: "screenCornerRadius", label: qsTr("Corner radius"), detail: qsTr("Appearance") },
        { section: "interface", key: "hotCornersEnabled", label: qsTr("Hot corners"), detail: qsTr("Appearance") },
        { section: "interface", key: "hotCornerVisualize", label: qsTr("Visualize hot corners"), detail: qsTr("Appearance") },
        { section: "hyprland", key: "integrationMode", label: qsTr("Integration mode"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "deadPixelWorkaround", label: qsTr("Dead-pixel workaround"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerValueScroll", label: qsTr("Hot-corner value scroll"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerClickless", label: qsTr("Clickless hot corners"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerRegionWidth", label: qsTr("Corner region width"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerRegionHeight", label: qsTr("Corner region height"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "barShowOnSuperDelay", label: qsTr("Super reveal delay"), detail: qsTr("Hyprland") },
        { section: "services", key: "networkCommand", label: qsTr("Network command"), detail: qsTr("Integrations") },
        { section: "services", key: "networkEthernetCommand", label: qsTr("Ethernet command"), detail: qsTr("Integrations") },
        { section: "services", key: "bluetoothCommand", label: qsTr("Bluetooth command"), detail: qsTr("Integrations") },
        { section: "services", key: "taskManagerCommand", label: qsTr("Task manager command"), detail: qsTr("Integrations") },
        { section: "services", key: "changePasswordCommand", label: qsTr("Password command"), detail: qsTr("Integrations") },
        { section: "profile", key: "profileDisplayName", label: qsTr("Display name"), detail: qsTr("Profile") },
        { section: "profile", key: "profileAvatarPath", label: qsTr("Avatar path"), detail: qsTr("Profile") }
    ]
    readonly property var filteredEntries: root.filtered(root.query)

    implicitWidth: 300
    implicitHeight: 32
    z: 100

    function filtered(value: string): var {
        const needle = String(value ?? "").trim().toLowerCase()
        if (needle.length === 0)
            return []
        return root.entries.filter(entry => {
            return entry.label.toLowerCase().includes(needle)
                || entry.detail.toLowerCase().includes(needle)
                || entry.key.toLowerCase().includes(needle)
        }).slice(0, 7)
    }

    function focusSearch(): void {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function clear(): void {
        root.query = ""
        root.currentIndex = 0
        searchInput.text = ""
    }

    function activate(index: int): void {
        if (root.filteredEntries.length === 0)
            return
        const safeIndex = Math.max(0, Math.min(root.filteredEntries.length - 1, index))
        const entry = root.filteredEntries[safeIndex]
        RaohaneState.settingsPage = entry.section + ":" + entry.key
        root.clear()
    }

    RaohaneSurface {
        id: searchBox

        anchors.fill: parent
        surfaceRadius: 11
        raised: false
        active: searchInput.activeFocus
        hovered: searchHover.containsMouse
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 8
            spacing: 7

            RaohaneIcon {
                text: "search"
                iconSize: 15
                fill: searchInput.activeFocus ? 1 : 0
                color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: RaohaneTheme.text
                    selectionColor: RaohaneTheme.accentSoft
                    selectedTextColor: RaohaneTheme.text
                    font.pixelSize: 9
                    clip: true
                    text: root.query

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text
                        root.currentIndex = 0
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down && root.filteredEntries.length > 0) {
                            root.currentIndex = Math.min(root.filteredEntries.length - 1, root.currentIndex + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up && root.filteredEntries.length > 0) {
                            root.currentIndex = Math.max(0, root.currentIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.currentIndex)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.clear()
                            focus = false
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.query.length === 0 && !searchInput.activeFocus
                    text: qsTr("Search settings")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 9
                }
            }

            RaohaneSurface {
                visible: root.query.length === 0
                Layout.preferredWidth: 40
                Layout.preferredHeight: 20
                surfaceRadius: 7
                raised: false
                showSheen: false

                Text {
                    anchors.centerIn: parent
                    text: "Ctrl F"
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.Medium
                }
            }

            RaohaneIconButton {
                visible: root.query.length > 0
                buttonSize: 24
                iconSize: 14
                icon: "close"
                onClicked: {
                    root.clear()
                    searchInput.forceActiveFocus()
                }
            }
        }

        MouseArea {
            id: searchHover
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }

    RaohaneSurface {
        id: resultsPanel

        visible: root.query.length > 0
        anchors {
            top: searchBox.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
        }
        height: root.filteredEntries.length > 0 ? Math.min(282, resultsList.contentHeight + 12) : 46
        surfaceRadius: 14
        raised: true
        showSheen: false
        border.color: RaohaneTheme.borderStrong
        clip: true
        z: 101

        opacity: root.query.length > 0 ? 1 : 0
        scale: root.query.length > 0 ? 1 : 0.975

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
        Behavior on scale {
            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
        }

        Text {
            visible: root.filteredEntries.length === 0
            anchors.centerIn: parent
            text: qsTr("No matching setting")
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
        }

        ListView {
            id: resultsList

            visible: root.filteredEntries.length > 0
            anchors.fill: parent
            anchors.margins: 6
            model: root.filteredEntries
            spacing: 3
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: FocusScope {
                id: resultRow

                required property var modelData
                required property int index

                width: resultsList.width
                height: 36
                activeFocusOnTab: true

                RaohaneSurface {
                    anchors.fill: parent
                    surfaceRadius: 10
                    raised: false
                    active: resultRow.index === root.currentIndex || resultRow.activeFocus
                    hovered: resultMouse.containsMouse
                    pressed: resultMouse.pressed
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 8

                        RaohaneIcon {
                            text: "tune"
                            iconSize: 14
                            fill: resultRow.index === root.currentIndex ? 1 : 0
                            color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: resultRow.modelData.label
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.weight: resultRow.index === root.currentIndex ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: resultRow.modelData.detail
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }

                        RaohaneIcon {
                            text: "arrow_forward"
                            iconSize: 13
                            color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textFaint
                            opacity: resultRow.index === root.currentIndex || resultMouse.containsMouse ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.currentIndex = resultRow.index
                    onPressed: resultRow.forceActiveFocus()
                    onClicked: root.activate(resultRow.index)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.activate(resultRow.index)
                        event.accepted = true
                    }
                }
            }
        }
    }
}
