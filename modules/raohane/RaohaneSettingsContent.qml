pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property int currentPage: 0
    property string pendingSearch: ""
    readonly property bool compactNav: width < 860

    readonly property var pages: [
        { name: qsTr("Home"), icon: "space_dashboard", source: Qt.resolvedUrl("RaohaneSettingsHome.qml") },
        { name: qsTr("Quick"), icon: "instant_mix", source: Qt.resolvedUrl("../ii/settings/pages/QuickConfig.qml") },
        { name: qsTr("General"), icon: "browse", source: Qt.resolvedUrl("../ii/settings/pages/GeneralConfig.qml") },
        { name: qsTr("Bar"), icon: "toast", source: Qt.resolvedUrl("../ii/settings/pages/BarConfig.qml") },
        { name: qsTr("Desktop"), icon: "texture", source: Qt.resolvedUrl("../ii/settings/pages/BackgroundConfig.qml") },
        { name: qsTr("Interface"), icon: "bottom_app_bar", source: Qt.resolvedUrl("../ii/settings/pages/InterfaceConfig.qml") },
        { name: qsTr("Services"), icon: "settings", source: Qt.resolvedUrl("../ii/settings/pages/ServicesConfig.qml") },
        { name: qsTr("Hyprland"), icon: "select_window_2", source: Qt.resolvedUrl("../ii/settings/pages/HyprlandConfig.qml") },
        { name: qsTr("Profile"), icon: "account_circle", source: Qt.resolvedUrl("../ii/settings/pages/Profile.qml") },
        { name: qsTr("About"), icon: "info", source: Qt.resolvedUrl("RaohaneSettingsAbout.qml") }
    ]

    Component.onCompleted: Config.readWriteDelay = 0

    onCurrentPageChanged: {
        const page = pages[currentPage]
        if (page?.name === qsTr("About") && RaohaneSystemInfo.cpu === "")
            RaohaneSystemInfo.refresh()
    }

    Connections {
        target: GlobalStates

        function onSettingsPageChanged(): void {
            if (GlobalStates.settingsPage === "")
                return

            const parts = GlobalStates.settingsPage.split(":")
            const requested = parts[0]
            root.pendingSearch = parts.length > 1 ? parts.slice(1).join(":") : ""

            const index = root.pages.findIndex(page => page.name.toLowerCase() === requested.toLowerCase())
            if (index >= 0) {
                root.currentPage = index
                Qt.callLater(root.dispatchPendingSearch)
            }

            GlobalStates.settingsPage = ""
        }
    }

    function dispatchPendingSearch(): void {
        if (pendingSearch === "")
            return
        if (pageLoader.item && typeof pageLoader.item.goTo === "function") {
            pageLoader.item.goTo(pendingSearch)
            pendingSearch = ""
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.compactNav ? 70 : 214
            radius: 18
            color: "#9d17141f"
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
                    color: "#611f1a29"
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
                            color: RaohaneTheme.accentSoft
                            clip: true

                            Image {
                                id: avatar
                                anchors.fill: parent
                                source: Config.options.profile.avatarPicture !== ""
                                    ? "file://" + Config.options.profile.avatarPicture
                                    : RaohanePaths.defaultAvatarUrl
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
                                text: Config.options.profile.displayName === "" ? RaohaneSystemInfo.username : Config.options.profile.displayName
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
                        onClicked: root.currentPage = root.pages.findIndex(page => page.name === qsTr("Profile"))
                    }
                }

                Text {
                    visible: !root.compactNav
                    text: "RAOHANE / CONFIG"
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.letterSpacing: 1.0
                    font.weight: Font.DemiBold
                    Layout.leftMargin: 5
                }

                ListView {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.pages
                    spacing: 5
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: navItem
                        required property var modelData
                        required property int index

                        width: navigation.width
                        height: 42
                        radius: 13
                        color: root.currentPage === index ? RaohaneTheme.accentSoft
                            : navMouse.containsMouse ? "#20ffffff" : "transparent"
                        border.width: 1
                        border.color: root.currentPage === index ? RaohaneTheme.accent : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 9
                            spacing: 9

                            RaohaneIcon {
                                text: navItem.modelData.icon
                                iconSize: 17
                                color: root.currentPage === navItem.index ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !root.compactNav
                                text: navItem.modelData.name
                                color: root.currentPage === navItem.index ? RaohaneTheme.text : RaohaneTheme.textMuted
                                font.pixelSize: 10
                                font.weight: root.currentPage === navItem.index ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: root.currentPage === navItem.index && !root.compactNav
                                width: 5
                                height: 5
                                radius: 3
                                color: RaohaneTheme.accent
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.pendingSearch = ""
                                root.currentPage = navItem.index
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 13
                    color: configMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                    border.width: 1
                    border.color: configMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 9
                        spacing: 9

                        RaohaneIcon {
                            text: "description"
                            iconSize: 17
                            color: RaohaneTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.compactNav
                            text: copiedTimer.running ? qsTr("Path copied") : qsTr("config.json")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: configMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                Quickshell.clipboardText = RaohanePaths.compatibilityConfigFile
                                copiedTimer.restart()
                            } else {
                                Qt.openUrlExternally("file://" + RaohanePaths.compatibilityConfigFile)
                            }
                        }
                    }

                    Timer {
                        id: copiedTimer
                        interval: 1400
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: "#6f121019"
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: "#7f17141f"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 10
                            color: RaohaneTheme.accentSoft

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: root.pages[root.currentPage]?.icon ?? "settings"
                                iconSize: 17
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1

                            Text {
                                Layout.fillWidth: true
                                text: root.pages[root.currentPage]?.name ?? qsTr("Settings")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Live settings · ~/.config/raohane/config.json")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 4
                            color: RaohaneTheme.accent
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        anchors.margins: 8
                        source: root.pages[root.currentPage]?.source ?? ""

                        onLoaded: Qt.callLater(root.dispatchPendingSearch)
                    }
                }
            }
        }
    }
}
