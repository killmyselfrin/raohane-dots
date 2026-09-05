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
        return RaohaneWallpapers.isVideo(path)
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
                color: RaohaneTheme.dark ? "#76000000" : "#355b5750"
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

                width: Math.min(parent.width - 72, 1180)
                height: Math.min(parent.height - 72, 760)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0
                scale: entered ? 1 : 0.986

                transform: Translate {
                    y: selector.entered ? 0 : 10
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
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 11
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentBorder

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "wallpaper"
                                iconSize: 18
                                fill: 1
                                symbolWeight: 560
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                text: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? qsTr("Lock screen wallpaper") : qsTr("Wallpaper")
                                color: RaohaneTheme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("Browse, preview and apply")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            Layout.maximumWidth: 250
                            text: RaohaneWallpapers.effectiveDirectory
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            elide: Text.ElideMiddle
                        }

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
                            border.color: searchField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 7

                                RaohaneIcon {
                                    text: "search"
                                    iconSize: 15
                                    fill: searchField.activeFocus ? 1 : 0
                                    symbolWeight: searchField.activeFocus ? 520 : 430
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
                                    text: qsTr("%1 items").arg(RaohaneWallpapers.folderModel.count)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GridView {
                            id: gallery
                            anchors.fill: parent
                            anchors.topMargin: 2
                            clip: true
                            model: RaohaneWallpapers.folderModel
                            boundsBehavior: Flickable.StopAtBounds
                            cellWidth: width / Math.max(1, width >= 980 ? 4 : width >= 700 ? 3 : 2)
                            cellHeight: Math.max(150, Math.min(210, cellWidth * 0.64))

                            ScrollBar.vertical: ScrollBar {
                                id: galleryScroll
                                policy: ScrollBar.AsNeeded
                                width: 7
                                background: Item {}
                                contentItem: Rectangle {
                                    implicitWidth: 5
                                    radius: width / 2
                                    color: galleryScroll.pressed ? RaohaneTheme.accent : RaohaneTheme.borderStrong
                                    opacity: galleryScroll.active ? 0.8 : 0.28
                                }
                            }

                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index

                                width: gallery.cellWidth
                                height: gallery.cellHeight
                                readonly property bool isDirectory: modelData.fileIsDir ?? false
                                readonly property string filePath: modelData.filePath ?? ""
                                readonly property string fileName: modelData.fileName ?? filePath.split("/").pop()
                                readonly property bool isVideo: root.isVideo(filePath)
                                readonly property bool selected: filePath === (RaohaneState.wallpaperSelectorTarget === "lockWall"
                                    ? RaohaneConfig.lockWallpaperPath
                                    : RaohaneConfig.wallpaperPath)

                                RaohaneSurface {
                                    id: card
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    surfaceRadius: 17
                                    active: cell.selected
                                    hovered: cellMouse.containsMouse
                                    pressed: cellMouse.pressed
                                    interactive: true
                                    raised: false
                                    showSheen: false
                                    hoverScale: 1.006
                                    pressedScale: 0.99
                                    border.color: cell.selected ? RaohaneTheme.accentBorder
                                        : cellMouse.containsMouse ? RaohaneTheme.borderStrong
                                        : RaohaneTheme.borderFaint
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
                                        visible: cell.isVideo
                                        color: RaohaneTheme.surfaceDeep

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 44
                                                height: 44
                                                radius: 14
                                                color: RaohaneTheme.surfaceRaised
                                                border.width: 1
                                                border.color: RaohaneTheme.borderStrong

                                                RaohaneIcon {
                                                    anchors.centerIn: parent
                                                    text: "movie"
                                                    iconSize: 23
                                                    color: cellMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                                }
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Math.min(190, card.width - 36)
                                                text: cell.fileName
                                                horizontalAlignment: Text.AlignHCenter
                                                color: RaohaneTheme.textMuted
                                                font.pixelSize: 7
                                                elide: Text.ElideMiddle
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: cell.isDirectory
                                        color: RaohaneTheme.surfaceSubtle

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 8

                                            RaohaneIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "folder"
                                                iconSize: 30
                                                fill: cellMouse.containsMouse ? 1 : 0
                                                symbolWeight: cellMouse.containsMouse ? 540 : 430
                                                color: cellMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Math.min(180, card.width - 28)
                                                text: cell.fileName
                                                horizontalAlignment: Text.AlignHCenter
                                                color: RaohaneTheme.text
                                                font.pixelSize: 8
                                                font.weight: Font.Medium
                                                elide: Text.ElideMiddle
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: !cell.isDirectory && !cell.isVideo
                                        gradient: Gradient {
                                            GradientStop { position: 0.56; color: "#00000000" }
                                            GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#c8000000" : "#c8f4f1eb" }
                                        }
                                    }

                                    Rectangle {
                                        visible: cell.selected
                                        anchors {
                                            top: parent.top
                                            right: parent.right
                                            margins: 9
                                        }
                                        width: 26
                                        height: 26
                                        radius: 9
                                        color: RaohaneTheme.accent

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "check"
                                            iconSize: 14
                                            fill: 1
                                            symbolWeight: 650
                                            color: RaohaneTheme.onAccent
                                        }
                                    }

                                    RowLayout {
                                        visible: !cell.isDirectory
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            leftMargin: 11
                                            rightMargin: 11
                                            bottomMargin: 9
                                        }
                                        spacing: 6

                                        RaohaneIcon {
                                            text: cell.isVideo ? "movie" : "image"
                                            iconSize: 13
                                            color: cell.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: cell.fileName
                                            color: RaohaneTheme.text
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            gallery.currentIndex = cell.index
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
                        Layout.preferredHeight: 20

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

        buttonSize: 30
        iconSize: 15
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
        hoverScale: 1.006
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
