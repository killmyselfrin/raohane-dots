pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property string homePath: RaohanePaths.home
    readonly property string picturesPath: RaohanePaths.pictures

    function isVideo(path: string): bool {
        const lower = (path ?? "").toLowerCase()
        return lower.endsWith(".mp4")
            || lower.endsWith(".webm")
            || lower.endsWith(".mkv")
            || lower.endsWith(".mov")
            || lower.endsWith(".avi")
    }

    function close(): void {
        RaohaneWallpapers.stopPreview()
        RaohaneState.wallpaperSelectorOpen = false
    }

    function toggle(): void {
        RaohaneState.wallpaperSelectorOpen = !RaohaneState.wallpaperSelectorOpen
    }

    function selectPath(path: string, isDirectory: bool): void {
        if (!path || path.length === 0)
            return

        if (isDirectory) {
            RaohaneWallpapers.setDirectory(path)
            return
        }

        RaohaneWallpapers.stopPreview()
        if (RaohaneState.wallpaperSelectorTarget === "lockWall") {
            RaohaneWallpapers.select(path, true, finalPath => {
                RaohaneConfig.lockWallpaperPath = finalPath
                RaohaneState.wallpaperSelectorTarget = "wallpaper"
                root.close()
            })
        } else {
            RaohaneWallpapers.select(path)
            root.close()
        }
    }

    Loader {
        active: RaohaneState.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            screen: root.focusedScreen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:raohane-wallpaper-selector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: {
                RaohaneWallpapers.load()
                RaohaneFocusGrab.addDismissable(panelWindow)
                searchField.forceActiveFocus()
            }
            Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: RaohaneFocusGrab
                function onDismissed(): void { root.close() }
            }

            Rectangle {
                anchors.fill: parent
                color: "#7808070d"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                id: selector
                width: Math.min(parent.width - 72, 1120)
                height: Math.min(parent.height - 90, 720)
                anchors.centerIn: parent
                radius: 28
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border
                clip: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close()
                        event.accepted = true
                    } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Up) {
                        RaohaneWallpapers.navigateUp()
                        event.accepted = true
                    } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Left) {
                        RaohaneWallpapers.navigateBack()
                        event.accepted = true
                    } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Right) {
                        RaohaneWallpapers.navigateForward()
                        event.accepted = true
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                        searchField.forceActiveFocus()
                        event.accepted = true
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        radius: 18
                        color: "#87171320"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 7

                            NavButton { icon: "arrow_back"; onTriggered: RaohaneWallpapers.navigateBack() }
                            NavButton { icon: "arrow_upward"; onTriggered: RaohaneWallpapers.navigateUp() }
                            NavButton { icon: "arrow_forward"; onTriggered: RaohaneWallpapers.navigateForward() }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 13
                                color: "#54100e16"
                                border.width: 1
                                border.color: searchField.activeFocus ? RaohaneTheme.accent : RaohaneTheme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    RaohaneIcon {
                                        text: "search"
                                        iconSize: 17
                                        color: RaohaneTheme.textMuted
                                    }

                                    TextField {
                                        id: searchField
                                        Layout.fillWidth: true
                                        background: null
                                        color: RaohaneTheme.text
                                        placeholderText: qsTr("Search wallpapers")
                                        placeholderTextColor: RaohaneTheme.textMuted
                                        font.pixelSize: 10
                                        selectByMouse: true
                                        onTextChanged: RaohaneWallpapers.searchQuery = text
                                    }

                                    Text {
                                        visible: searchField.text.length === 0
                                        text: RaohaneWallpapers.effectiveDirectory
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        elide: Text.ElideMiddle
                                        Layout.maximumWidth: 290
                                    }
                                }
                            }

                            NavButton {
                                icon: "casino"
                                emphasized: true
                                onTriggered: {
                                    RaohaneWallpapers.stopPreview()
                                    RaohaneWallpapers.randomFromCurrentFolder()
                                    root.close()
                                }
                            }
                            NavButton {
                                icon: "folder_open"
                                onTriggered: RaohaneWallpapers.openFallbackPicker(true, RaohaneWallpapers.effectiveDirectory)
                            }
                            NavButton { icon: "close"; onTriggered: root.close() }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        spacing: 7

                        QuickDir {
                            visible: root.picturesPath.length > 0
                            icon: "wallpaper"
                            title: qsTr("Wallpapers")
                            path: root.picturesPath + "/Wallpapers"
                        }
                        QuickDir {
                            visible: root.homePath.length > 0
                            icon: "home"
                            title: qsTr("Home")
                            path: root.homePath
                        }
                        QuickDir {
                            visible: RaohaneConfig.wallpaperDirectory.length > 0
                                && RaohaneConfig.wallpaperDirectory !== root.homePath
                                && RaohaneConfig.wallpaperDirectory !== root.picturesPath + "/Wallpapers"
                            icon: "folder_special"
                            title: qsTr("Current")
                            path: RaohaneConfig.wallpaperDirectory
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: targetText.implicitWidth + 18
                            height: 28
                            radius: 14
                            color: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                id: targetText
                                anchors.centerIn: parent
                                text: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? qsTr("LOCK SCREEN") : qsTr("DESKTOP")
                                color: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 20
                        color: "#74121019"
                        border.width: 1
                        border.color: RaohaneTheme.border
                        clip: true

                        GridView {
                            id: grid
                            anchors.fill: parent
                            anchors.margins: 8
                            model: RaohaneWallpapers.folderModel
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            cellWidth: width / Math.max(2, Math.min(6, RaohaneConfig.wallpaperColumns || 4))
                            cellHeight: cellWidth * 0.72
                            keyNavigationWraps: true
                            focus: true

                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index

                                width: grid.cellWidth
                                height: grid.cellHeight
                                readonly property bool isDirectory: modelData.fileIsDir ?? false
                                readonly property string filePath: modelData.filePath ?? ""
                                readonly property string fileName: modelData.fileName ?? filePath.split("/").pop()
                                readonly property bool isVideo: root.isVideo(filePath)
                                readonly property bool selected: filePath === (RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? RaohaneConfig.lockWallpaperPath
                                    : RaohaneConfig.wallpaperPath)

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    radius: 16
                                    color: cell.selected ? RaohaneTheme.accentSoft : "#471a1722"
                                    border.width: 1
                                    border.color: cellMouse.containsMouse || cell.selected
                                        ? RaohaneTheme.accent : RaohaneTheme.border
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        visible: !cell.isDirectory && !cell.isVideo
                                        source: cell.filePath.length > 0 ? "file://" + cell.filePath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: !cell.isDirectory && cell.isVideo
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "#2c231f36" }
                                            GradientStop { position: 1.0; color: "#b20c0a11" }
                                        }

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "movie"
                                            iconSize: 38
                                            color: RaohaneTheme.accent
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: !cell.isDirectory
                                        gradient: Gradient {
                                            GradientStop { position: 0.38; color: "#00100e16" }
                                            GradientStop { position: 1.0; color: "#cf100e16" }
                                        }
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: cell.isDirectory
                                        width: 54
                                        height: 54
                                        radius: 18
                                        color: RaohaneTheme.accentSoft

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "folder"
                                            iconSize: 28
                                            color: RaohaneTheme.accent
                                        }
                                    }

                                    RowLayout {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: 10
                                        }
                                        spacing: 6

                                        RaohaneIcon {
                                            text: cell.isDirectory ? "folder"
                                                : cell.selected ? "check_circle"
                                                : cell.isVideo ? "movie" : "image"
                                            iconSize: 15
                                            color: cell.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: cell.fileName
                                            color: RaohaneTheme.text
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            grid.currentIndex = cell.index
                                            if (!cell.isDirectory && !cell.isVideo && RaohaneConfig.wallpaperPreview)
                                                RaohaneWallpapers.startPreview(cell.filePath)
                                        }
                                        onExited: {
                                            if (!cell.isDirectory && RaohaneConfig.wallpaperPreview)
                                                RaohaneWallpapers.stopPreview()
                                        }
                                        onClicked: root.selectPath(cell.filePath, cell.isDirectory)
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: RaohaneWallpapers.folderModel.count === 0
                            spacing: 7

                            RaohaneIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "image_not_supported"
                                iconSize: 34
                                color: RaohaneTheme.textMuted
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("No wallpapers found")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        Text {
                            text: qsTr("%1 items").arg(RaohaneWallpapers.folderModel.count)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: qsTr("Alt+←/→ history · Alt+↑ parent · Ctrl+F search")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { root.toggle() }
        function random(): void { RaohaneWallpapers.randomFromCurrentFolder() }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle Raohane wallpaper selector"
        onPressed: root.toggle()
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: RaohaneWallpapers.randomFromCurrentFolder()
    }

    component NavButton: Rectangle {
        id: button
        required property string icon
        property bool emphasized: false
        signal triggered()

        width: 36
        height: 36
        radius: 12
        color: emphasized || pointer.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
        border.width: 1
        border.color: emphasized || pointer.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 18
            color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    component QuickDir: Rectangle {
        id: dir
        required property string icon
        required property string title
        required property string path
        Layout.preferredWidth: label.implicitWidth + 48
        Layout.preferredHeight: 30
        radius: 15
        color: dirMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
        border.width: 1
        border.color: dirMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        Row {
            anchors.centerIn: parent
            spacing: 6
            RaohaneIcon { text: dir.icon; iconSize: 14; color: RaohaneTheme.textMuted }
            Text {
                id: label
                text: dir.title
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: dirMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: RaohaneWallpapers.setDirectory(dir.path)
        }
    }
}
