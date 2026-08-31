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
                selector.entered = false
                Qt.callLater(() => {
                    selector.entered = true
                    searchField.forceActiveFocus()
                })
            }
            Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: RaohaneFocusGrab
                function onDismissed(): void { root.close() }
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.dark ? "#70000000" : "#305b5750"
                opacity: selector.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: selector
                property bool entered: false

                width: Math.min(parent.width - 96, 1080)
                height: Math.min(parent.height - 104, 700)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0
                scale: entered ? 1 : 0.982

                transform: Translate {
                    y: selector.entered ? 0 : 12
                    Behavior on y {
                        NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }
                Behavior on scale {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }

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

                        RaohaneSurface {
                            width: 34
                            height: 34
                            surfaceRadius: 11
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "wallpaper"
                                iconSize: 18
                                fill: 1
                                symbolWeight: 540
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

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            surfaceRadius: 11
                            hovered: searchField.activeFocus
                            showSheen: false
                            border.color: searchField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 9
                                spacing: 7

                                RaohaneIcon {
                                    text: "search"
                                    iconSize: 15
                                    fill: searchField.activeFocus ? 1 : 0
                                    symbolWeight: searchField.activeFocus ? 520 : 430
                                    color: searchField.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
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

                                RaohaneSurface {
                                    id: cellSurface
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    surfaceRadius: 13
                                    active: cell.selected
                                    hovered: cellMouse.containsMouse
                                    pressed: cellMouse.pressed
                                    interactive: true
                                    showSheen: false
                                    hoverScale: 1.015
                                    pressedScale: 0.985
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

                                    RaohaneSurface {
                                        anchors.centerIn: parent
                                        visible: cell.isDirectory
                                        width: 48
                                        height: 48
                                        surfaceRadius: 14
                                        active: cellMouse.containsMouse
                                        showSheen: false

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "folder"
                                            iconSize: 24
                                            fill: cellMouse.containsMouse ? 1 : 0
                                            symbolWeight: cellMouse.containsMouse ? 520 : 430
                                            color: cellMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
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
                                            fill: cell.selected ? 1 : 0
                                            symbolWeight: cell.selected ? 540 : 430
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

                            ScrollBar.vertical: ScrollBar {
                                id: wallpaperScroll
                                policy: ScrollBar.AsNeeded
                                width: 7
                                background: Item {}
                                contentItem: Rectangle {
                                    implicitWidth: 5
                                    radius: width / 2
                                    color: wallpaperScroll.pressed ? RaohaneTheme.accent : RaohaneTheme.borderStrong
                                    opacity: wallpaperScroll.active ? 0.8 : 0.35

                                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                    Behavior on opacity {
                                        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                                    }
                                }
                            }
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

    component NavButton: RaohaneIconButton {
        id: button
        signal triggered()

        buttonSize: 32
        iconSize: 16
        transparentIdle: true
        showSheen: false
        onClicked: button.triggered()
    }

    component QuickDir: RaohaneSurface {
        id: dir
        required property string icon
        required property string title
        required property string path

        Layout.preferredWidth: label.implicitWidth + 42
        Layout.preferredHeight: 32
        surfaceRadius: 10
        active: RaohaneWallpapers.effectiveDirectory === dir.path
        transparentIdle: !active
        showSheen: false
        interactive: true
        hovered: dirMouse.containsMouse || activeFocus
        pressed: dirMouse.pressed
        hoverScale: 1.012
        pressedScale: RaohaneMotion.pressScale
        activeFocusOnTab: true

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: dir.icon
                iconSize: 13
                fill: dir.active ? 1 : dir.hovered ? 0.5 : 0
                symbolWeight: dir.active ? 540 : dir.hovered ? 500 : 430
                color: dir.active || dir.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
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
            onPressed: dir.forceActiveFocus()
            onClicked: RaohaneWallpapers.setDirectory(dir.path)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                RaohaneWallpapers.setDirectory(dir.path)
                event.accepted = true
            }
        }
    }
}
