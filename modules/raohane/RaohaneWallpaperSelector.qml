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
        RaohaneState.setPrimaryOpen("wallpaper", false)
    }

    function toggle(): void {
        RaohaneState.togglePrimary("wallpaper")
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
                color: RaohaneTheme.dark ? "#70000000" : "#305b5750"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: selector
                width: Math.min(parent.width - 96, 1080)
                height: Math.min(parent.height - 104, 700)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
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
                    anchors.margins: 14
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 7

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 11
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.border

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "wallpaper"
                                iconSize: 18
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                text: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? qsTr("Lock screen wallpaper") : qsTr("Wallpaper")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("Browse, preview and apply")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Item { Layout.fillWidth: true }

                        NavButton { icon: "arrow_back"; onTriggered: RaohaneWallpapers.navigateBack() }
                        NavButton { icon: "arrow_upward"; onTriggered: RaohaneWallpapers.navigateUp() }
                        NavButton { icon: "arrow_forward"; onTriggered: RaohaneWallpapers.navigateForward() }
                        NavButton {
                            icon: "casino"
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        spacing: 7

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 11
                            color: searchField.activeFocus ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: searchField.activeFocus ? RaohaneTheme.borderStrong : RaohaneTheme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 9
                                spacing: 7

                                RaohaneIcon {
                                    text: "search"
                                    iconSize: 15
                                    color: searchField.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    background: null
                                    color: RaohaneTheme.text
                                    placeholderText: qsTr("Search wallpapers")
                                    placeholderTextColor: RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                    selectByMouse: true
                                    onTextChanged: RaohaneWallpapers.searchQuery = text
                                }

                                Text {
                                    visible: searchField.text.length === 0
                                    text: RaohaneWallpapers.effectiveDirectory
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    elide: Text.ElideMiddle
                                    Layout.maximumWidth: 260
                                }
                            }
                        }

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
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        surfaceRadius: 17
                        raised: false
                        showSheen: false
                        clip: true

                        GridView {
                            id: grid
                            anchors.fill: parent
                            anchors.margins: 7
                            model: RaohaneWallpapers.folderModel
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            cellWidth: width / Math.max(2, Math.min(6, RaohaneConfig.wallpaperColumns || 4))
                            cellHeight: cellWidth * 0.70
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
                                    anchors.margins: 4
                                    radius: 13
                                    color: RaohaneTheme.surfaceSubtle
                                    border.width: cell.selected || cellMouse.containsMouse ? 2 : 1
                                    border.color: cell.selected ? RaohaneTheme.accentBorder
                                        : cellMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border
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
                                        color: RaohaneTheme.surfaceDeep

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "movie"
                                            iconSize: 32
                                            color: RaohaneTheme.textMuted
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: !cell.isDirectory
                                        gradient: Gradient {
                                            GradientStop { position: 0.48; color: "#00000000" }
                                            GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#c0000000" : "#b8f5f2ec" }
                                        }
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: cell.isDirectory
                                        width: 48
                                        height: 48
                                        radius: 14
                                        color: RaohaneTheme.surfaceRaised
                                        border.width: 1
                                        border.color: RaohaneTheme.border

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "folder"
                                            iconSize: 24
                                            color: RaohaneTheme.textMuted
                                        }
                                    }

                                    RowLayout {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: 9
                                        }
                                        spacing: 6

                                        RaohaneIcon {
                                            text: cell.isDirectory ? "folder"
                                                : cell.selected ? "check_circle"
                                                : cell.isVideo ? "movie" : "image"
                                            iconSize: 14
                                            color: cell.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: cell.fileName
                                            color: RaohaneTheme.text
                                            font.pixelSize: 8
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

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: RaohaneWallpapers.folderModel.count === 0
                            spacing: 7

                            RaohaneIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "image_not_supported"
                                iconSize: 30
                                color: RaohaneTheme.textFaint
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("No wallpapers found")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24

                        Text {
                            text: qsTr("%1 items").arg(RaohaneWallpapers.folderModel.count)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: qsTr("Alt+←/→ history · Alt+↑ parent · Ctrl+F search")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
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
        signal triggered()

        width: 32
        height: 32
        radius: 10
        color: pointer.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: pointer.containsMouse ? 1 : 0
        border.color: RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 16
            color: pointer.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
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

        Layout.preferredWidth: label.implicitWidth + 42
        Layout.preferredHeight: 32
        radius: 10
        color: dirMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: dirMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: dir.icon
                iconSize: 13
                color: dirMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                id: label
                text: dir.title
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.Medium
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
