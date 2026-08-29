pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string query: ""
    property int currentIndex: 0
    readonly property bool active: searchInput.activeFocus || root.query.length > 0
    readonly property var entries: [
        { section: "quick", key: "quickSliderBrightness", label: qsTr("Brightness slider"), detail: qsTr("Quick Controls") },
        { section: "quick", key: "quickSliderVolume", label: qsTr("Volume slider"), detail: qsTr("Quick Controls") },
        { section: "quick", key: "quickSliderMic", label: qsTr("Microphone slider"), detail: qsTr("Quick Controls") },
        { section: "general", key: "contextIslandEnabled", label: qsTr("Context island"), detail: qsTr("General") },
        { section: "general", key: "mediaOverlayEnabled", label: qsTr("Media overlay"), detail: qsTr("General") },
        { section: "general", key: "integrationMode", label: qsTr("Integration mode"), detail: qsTr("General") },
        { section: "general", key: "osdTimeout", label: qsTr("OSD timeout"), detail: qsTr("General") },
        { section: "general", key: "colorTemperature", label: qsTr("Night temperature"), detail: qsTr("General") },
        { section: "general", key: "nightLightAutomatic", label: qsTr("Automatic night light"), detail: qsTr("General") },
        { section: "bar", key: "barBottom", label: qsTr("Bottom bar"), detail: qsTr("Bar") },
        { section: "bar", key: "barVertical", label: qsTr("Vertical bar"), detail: qsTr("Bar") },
        { section: "bar", key: "barAutoHide", label: qsTr("Auto-hide bar"), detail: qsTr("Bar") },
        { section: "bar", key: "barAutoHidePushWindows", label: qsTr("Push windows"), detail: qsTr("Bar") },
        { section: "bar", key: "barShowOnSuper", label: qsTr("Reveal on Super"), detail: qsTr("Bar") },
        { section: "bar", key: "barShowDate", label: qsTr("Show date"), detail: qsTr("Bar") },
        { section: "bar", key: "dockEnabled", label: qsTr("Dock"), detail: qsTr("Bar") },
        { section: "bar", key: "dockAutoHide", label: qsTr("Auto-hide dock"), detail: qsTr("Bar") },
        { section: "bar", key: "dockIconSize", label: qsTr("Dock icon size"), detail: qsTr("Bar") },
        { section: "desktop", key: "wallpaperPreview", label: qsTr("Wallpaper preview"), detail: qsTr("Desktop") },
        { section: "desktop", key: "wallpaperHideWhenFullscreen", label: qsTr("Hide wallpaper on fullscreen"), detail: qsTr("Desktop") },
        { section: "desktop", key: "wallpaperColumns", label: qsTr("Wallpaper columns"), detail: qsTr("Desktop") },
        { section: "desktop", key: "wallpaperTransitionDuration", label: qsTr("Transition duration"), detail: qsTr("Desktop") },
        { section: "desktop", key: "overviewWorkspaceCount", label: qsTr("Overview workspaces"), detail: qsTr("Desktop") },
        { section: "desktop", key: "overviewColumns", label: qsTr("Overview columns"), detail: qsTr("Desktop") },
        { section: "interface", key: "frameEnabled", label: qsTr("Screen frame"), detail: qsTr("Interface") },
        { section: "interface", key: "frameThickness", label: qsTr("Frame thickness"), detail: qsTr("Interface") },
        { section: "interface", key: "frameBarSideVisible", label: qsTr("Frame on bar edge"), detail: qsTr("Interface") },
        { section: "interface", key: "screenRoundingMode", label: qsTr("Rounding mode"), detail: qsTr("Interface") },
        { section: "interface", key: "screenCornerRadius", label: qsTr("Corner radius"), detail: qsTr("Interface") },
        { section: "interface", key: "hotCornersEnabled", label: qsTr("Hot corners"), detail: qsTr("Interface") },
        { section: "interface", key: "hotCornerVisualize", label: qsTr("Visualize hot corners"), detail: qsTr("Interface") },
        { section: "services", key: "networkCommand", label: qsTr("Network command"), detail: qsTr("Services") },
        { section: "services", key: "networkEthernetCommand", label: qsTr("Ethernet command"), detail: qsTr("Services") },
        { section: "services", key: "bluetoothCommand", label: qsTr("Bluetooth command"), detail: qsTr("Services") },
        { section: "services", key: "taskManagerCommand", label: qsTr("Task manager command"), detail: qsTr("Services") },
        { section: "services", key: "changePasswordCommand", label: qsTr("Password command"), detail: qsTr("Services") },
        { section: "hyprland", key: "deadPixelWorkaround", label: qsTr("Dead-pixel workaround"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerValueScroll", label: qsTr("Hot-corner value scroll"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerClickless", label: qsTr("Clickless hot corners"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerRegionWidth", label: qsTr("Corner region width"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "hotCornerRegionHeight", label: qsTr("Corner region height"), detail: qsTr("Hyprland") },
        { section: "hyprland", key: "barShowOnSuperDelay", label: qsTr("Super reveal delay"), detail: qsTr("Hyprland") },
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

    Rectangle {
        id: searchBox
        anchors.fill: parent
        radius: 11
        color: searchInput.activeFocus ? RaohaneTheme.surfaceHover : "#18ffffff"
        border.width: 1
        border.color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 8
            spacing: 7

            RaohaneIcon {
                text: "search"
                iconSize: 15
                color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
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

            Text {
                visible: root.query.length === 0
                text: "Ctrl F"
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
            }

            RaohaneIconButton {
                visible: root.query.length > 0
                buttonSize: 24
                iconSize: 14
                icon: "close"
                onClicked: root.clear()
            }
        }
    }

    Rectangle {
        id: resultsPanel
        visible: root.query.length > 0
        anchors {
            top: searchBox.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
        }
        height: root.filteredEntries.length > 0 ? Math.min(282, resultsList.contentHeight + 12) : 46
        radius: 14
        color: RaohaneTheme.surfaceRaised
        border.width: 1
        border.color: RaohaneTheme.borderStrong
        clip: true
        z: 101

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

            delegate: Rectangle {
                id: resultRow
                required property var modelData
                required property int index

                width: resultsList.width
                height: 36
                radius: 10
                color: resultRow.index === root.currentIndex || resultMouse.containsMouse
                    ? RaohaneTheme.accentSoft
                    : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    RaohaneIcon {
                        text: "tune"
                        iconSize: 14
                        color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: resultRow.modelData.label
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        text: resultRow.modelData.detail
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }

                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.currentIndex = resultRow.index
                    onClicked: root.activate(resultRow.index)
                }
            }
        }
    }
}
