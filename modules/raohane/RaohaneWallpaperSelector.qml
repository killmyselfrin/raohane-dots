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
    readonly property string wallpapersPath: root.picturesPath.length > 0
        ? root.picturesPath + "/Wallpapers"
        : ""
    property string pendingPath: ""

    function isVideo(path: string): bool {
        return RaohaneWallpapers.isVideo(path)
    }

    function appliedPath(): string {
        return RaohaneState.wallpaperSelectorTarget === "lockWall"
            ? RaohaneConfig.lockWallpaperPath
            : RaohaneConfig.wallpaperPath
    }

    function resetPending(): void {
        root.pendingPath = root.appliedPath()
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

        root.pendingPath = path
        if (RaohaneConfig.wallpaperPreview)
            RaohaneWallpapers.startPreview(path)
    }

    function previewPending(): void {
        if (root.pendingPath.length > 0)
            RaohaneWallpapers.startPreview(root.pendingPath)
    }

    function applyPending(): void {
        const path = root.pendingPath
        if (!path || path.length === 0)
            return

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
                root.resetPending()
                RaohaneFocusGrab.addDismissable(panelWindow)
                selector.entered = false
                Qt.callLater(() => selector.entered = true)
            }
            Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

            Connections {
                target: RaohaneFocusGrab
                function onDismissed(): void { root.close() }
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.dark
                    ? Qt.rgba(0.01, 0.015, 0.035, 0.56)
                    : Qt.rgba(0.18, 0.17, 0.15, 0.20)
                opacity: selector.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: selector
                property bool entered: false

                width: Math.min(parent.width - 72, 1040)
                height: Math.min(parent.height - 72, 720)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: true
                idleBorderColor: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
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
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyPending()
                        event.accepted = true
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingTiny
                            anchors.rightMargin: RaohaneTheme.panelPadding
                            spacing: RaohaneTheme.spacing + 2

                            RaohaneSurface {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                surfaceRadius: RaohaneTheme.radiusLarge
                                active: true
                                showSheen: false
                                showInnerRim: false

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: "wallpaper"
                                    iconSize: 20
                                    fill: 1
                                    symbolWeight: 560
                                    grade: 30
                                    color: RaohaneTheme.accent
                                }
                            }

                            ColumnLayout {
                                spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                                Text {
                                    text: RaohaneState.wallpaperSelectorTarget === "lockWall"
                                        ? qsTr("Lock screen wallpaper")
                                        : qsTr("Wallpaper")
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

                            RaohaneSurface {
                                Layout.preferredWidth: 280
                                Layout.preferredHeight: 36
                                surfaceRadius: RaohaneTheme.radiusLarge
                                active: searchField.activeFocus
                                showSheen: false
                                showInnerRim: false
                                idleColor: RaohaneTheme.surface
                                activeColor: RaohaneTheme.surface
                                idleBorderColor: RaohaneTheme.borderFaint
                                activeBorderColor: RaohaneTheme.accentBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: RaohaneTheme.spacing + 1
                                    anchors.rightMargin: RaohaneTheme.spacing + 1
                                    spacing: RaohaneTheme.spacingSmall + 1

                                    RaohaneIcon {
                                        text: "search"
                                        iconSize: 15
                                        fill: searchField.activeFocus ? 1 : 0
                                        color: searchField.activeFocus
                                            ? RaohaneTheme.accent
                                            : RaohaneTheme.textMuted
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
                                }
                            }

                            NavButton {
                                icon: "casino"
                                onTriggered: {
                                    RaohaneWallpapers.stopPreview()
                                    RaohaneWallpapers.randomFromCurrentFolder()
                                    root.close()
                                }
                            }

                            NavButton {
                                icon: "close"
                                onTriggered: root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        RaohaneSurface {
                            Layout.preferredWidth: 176
                            Layout.fillHeight: true
                            surfaceRadius: 0
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            idleColor: RaohaneTheme.surfaceDeep
                            idleBorderColor: "transparent"
                            border.width: 0

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: RaohaneTheme.panelPadding
                                spacing: RaohaneTheme.spacingSmall

                                Text {
                                    Layout.leftMargin: RaohaneTheme.spacingSmall + 2
                                    text: qsTr("Wallpapers")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                LibraryButton {
                                    icon: "image"
                                    label: qsTr("Pictures")
                                    selected: root.picturesPath.length > 0
                                        && RaohaneWallpapers.effectiveDirectory === root.picturesPath
                                    onTriggered: {
                                        if (root.picturesPath.length > 0)
                                            RaohaneWallpapers.setDirectory(root.picturesPath)
                                    }
                                }

                                LibraryButton {
                                    icon: "wallpaper"
                                    label: qsTr("Wallpapers")
                                    selected: root.wallpapersPath.length > 0
                                        && RaohaneWallpapers.effectiveDirectory === root.wallpapersPath
                                    onTriggered: {
                                        if (root.wallpapersPath.length > 0)
                                            RaohaneWallpapers.setDirectory(root.wallpapersPath)
                                    }
                                }

                                LibraryButton {
                                    icon: "home"
                                    label: qsTr("Home")
                                    selected: root.homePath.length > 0
                                        && RaohaneWallpapers.effectiveDirectory === root.homePath
                                    onTriggered: {
                                        if (root.homePath.length > 0)
                                            RaohaneWallpapers.setDirectory(root.homePath)
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    Layout.topMargin: RaohaneTheme.spacingTiny
                                    Layout.bottomMargin: RaohaneTheme.spacingTiny
                                    color: RaohaneTheme.borderFaint
                                }

                                LibraryButton {
                                    icon: "arrow_upward"
                                    label: qsTr("Parent folder")
                                    onTriggered: RaohaneWallpapers.navigateUp()
                                }

                                LibraryButton {
                                    icon: "folder_open"
                                    label: qsTr("Browse")
                                    onTriggered: RaohaneWallpapers.openFallbackPicker(true, RaohaneWallpapers.effectiveDirectory)
                                }

                                Item { Layout.fillHeight: true }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: RaohaneTheme.spacingSmall + 2
                                    text: qsTr("%1 items").arg(RaohaneWallpapers.folderModel.count)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            color: RaohaneTheme.borderFaint
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: RaohaneTheme.panelPadding + 1
                            Layout.rightMargin: RaohaneTheme.panelPadding + 1
                            Layout.topMargin: RaohaneTheme.spacing + 2
                            Layout.bottomMargin: RaohaneTheme.spacing + 2
                            spacing: RaohaneTheme.spacing

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                spacing: RaohaneTheme.spacingSmall

                                NavButton { icon: "arrow_back"; onTriggered: RaohaneWallpapers.navigateBack() }
                                NavButton { icon: "arrow_forward"; onTriggered: RaohaneWallpapers.navigateForward() }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneWallpapers.effectiveDirectory
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                    elide: Text.ElideMiddle
                                }

                                RaohaneSurface {
                                    implicitWidth: countText.implicitWidth + RaohaneTheme.spacingLarge
                                    implicitHeight: 24
                                    surfaceRadius: RaohaneTheme.radiusSmall
                                    transparentIdle: true
                                    showSheen: false
                                    showInnerRim: false

                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        text: qsTr("%1 items").arg(RaohaneWallpapers.folderModel.count)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 7
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                GridView {
                                    id: gallery
                                    anchors.fill: parent
                                    clip: true
                                    model: RaohaneWallpapers.folderModel
                                    boundsBehavior: Flickable.StopAtBounds
                                    cellWidth: width / Math.max(1, width >= 650 ? 3 : 2)
                                    cellHeight: Math.max(158, Math.min(198, cellWidth * 0.69))

                                    ScrollBar.vertical: ScrollBar {
                                        id: galleryScroll
                                        policy: ScrollBar.AsNeeded
                                        width: 6
                                        background: Item {}
                                        contentItem: Rectangle {
                                            implicitWidth: 4
                                            radius: 2
                                            color: galleryScroll.pressed
                                                ? RaohaneTheme.accent
                                                : RaohaneTheme.borderStrong
                                            opacity: galleryScroll.active ? 0.78 : 0.26
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
                                        readonly property bool video: root.isVideo(filePath)
                                        readonly property bool selected: !isDirectory && filePath === root.pendingPath
                                        readonly property bool applied: !isDirectory && filePath === root.appliedPath()

                                        RaohaneSurface {
                                            id: card
                                            anchors.fill: parent
                                            anchors.margins: RaohaneTheme.spacingSmall - 1
                                            surfaceRadius: RaohaneTheme.radiusLarge
                                            active: cell.selected
                                            hovered: cellMouse.containsMouse
                                            pressed: cellMouse.pressed
                                            interactive: true
                                            raised: false
                                            showSheen: false
                                            showInnerRim: cell.selected
                                            hoverScale: 1
                                            pressedScale: 1
                                            idleBorderColor: RaohaneTheme.borderFaint
                                            hoverBorderColor: RaohaneTheme.borderStrong
                                            pressedBorderColor: RaohaneTheme.borderStrong
                                            activeBorderColor: RaohaneTheme.accentBorder
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                visible: !cell.isDirectory && !cell.video
                                                source: cell.filePath.length > 0 ? "file://" + cell.filePath : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: false
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                visible: cell.video
                                                color: RaohaneTheme.surfaceDeep

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: RaohaneTheme.spacingSmall

                                                    RaohaneIcon {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: "movie"
                                                        iconSize: 28
                                                        color: cellMouse.containsMouse
                                                            ? RaohaneTheme.accent
                                                            : RaohaneTheme.textMuted
                                                    }

                                                    Text {
                                                        width: Math.min(190, card.width - 26)
                                                        text: cell.fileName
                                                        color: RaohaneTheme.textMuted
                                                        font.pixelSize: 8
                                                        horizontalAlignment: Text.AlignHCenter
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
                                                    spacing: RaohaneTheme.spacingSmall + 1

                                                    RaohaneIcon {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: "folder"
                                                        iconSize: 30
                                                        fill: cellMouse.containsMouse ? 0.4 : 0
                                                        color: cellMouse.containsMouse
                                                            ? RaohaneTheme.accent
                                                            : RaohaneTheme.textMuted
                                                    }

                                                    Text {
                                                        width: Math.min(180, card.width - 26)
                                                        text: cell.fileName
                                                        color: RaohaneTheme.text
                                                        font.pixelSize: 8
                                                        font.weight: Font.Medium
                                                        horizontalAlignment: Text.AlignHCenter
                                                        elide: Text.ElideMiddle
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                visible: !cell.isDirectory && !cell.video
                                                gradient: Gradient {
                                                    GradientStop { position: 0.58; color: "#00000000" }
                                                    GradientStop { position: 1.0; color: "#b8000000" }
                                                }
                                            }

                                            RaohaneSurface {
                                                visible: cell.selected || cell.applied
                                                anchors {
                                                    top: parent.top
                                                    right: parent.right
                                                    margins: RaohaneTheme.spacingSmall + 2
                                                }
                                                width: 24
                                                height: 24
                                                surfaceRadius: RaohaneTheme.radiusSmall
                                                active: cell.selected
                                                raised: false
                                                showSheen: false
                                                showInnerRim: false
                                                idleColor: RaohaneTheme.surfaceRaised
                                                activeColor: RaohaneTheme.accent
                                                idleBorderColor: RaohaneTheme.borderStrong
                                                activeBorderColor: "transparent"

                                                RaohaneIcon {
                                                    anchors.centerIn: parent
                                                    text: cell.selected ? "check" : "wallpaper"
                                                    iconSize: 13
                                                    fill: 1
                                                    color: cell.selected
                                                        ? RaohaneTheme.background
                                                        : RaohaneTheme.accent
                                                }
                                            }

                                            RowLayout {
                                                visible: !cell.isDirectory
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    bottom: parent.bottom
                                                    leftMargin: RaohaneTheme.spacing + 1
                                                    rightMargin: RaohaneTheme.spacing + 1
                                                    bottomMargin: RaohaneTheme.spacingSmall + 2
                                                }
                                                spacing: RaohaneTheme.spacingSmall

                                                RaohaneIcon {
                                                    text: cell.video ? "movie" : "image"
                                                    iconSize: 12
                                                    color: cell.selected
                                                        ? RaohaneTheme.accent
                                                        : RaohaneTheme.text
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
                                                    if (!cell.isDirectory && RaohaneConfig.wallpaperPreview)
                                                        RaohaneWallpapers.startPreview(cell.filePath)
                                                }
                                                onExited: {
                                                    if (!cell.isDirectory && RaohaneConfig.wallpaperPreview && cell.filePath !== root.pendingPath)
                                                        RaohaneWallpapers.stopPreview()
                                                }
                                                onClicked: root.selectPath(cell.filePath, cell.isDirectory)
                                                onDoubleClicked: {
                                                    if (!cell.isDirectory) {
                                                        root.selectPath(cell.filePath, false)
                                                        root.applyPending()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    visible: RaohaneWallpapers.folderModel.count === 0
                                    spacing: RaohaneTheme.spacingSmall + 1

                                    RaohaneSurface {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 42
                                        height: 42
                                        surfaceRadius: RaohaneTheme.radiusLarge
                                        raised: false
                                        showSheen: false
                                        showInnerRim: false
                                        idleColor: RaohaneTheme.surfaceSubtle
                                        idleBorderColor: RaohaneTheme.borderFaint

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "image_not_supported"
                                            iconSize: 22
                                            color: RaohaneTheme.textFaint
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: qsTr("No wallpapers found")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: RaohaneTheme.borderFaint
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                spacing: RaohaneTheme.spacingSmall + 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.pendingPath.length > 0
                                        ? root.pendingPath.split("/").pop()
                                        : qsTr("Select a wallpaper")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    elide: Text.ElideMiddle
                                }

                                FooterButton {
                                    icon: "visibility"
                                    label: qsTr("Preview")
                                    enabled: root.pendingPath.length > 0
                                    onTriggered: root.previewPending()
                                }

                                FooterButton {
                                    icon: "check"
                                    label: qsTr("Apply")
                                    accent: true
                                    enabled: root.pendingPath.length > 0
                                    onTriggered: root.applyPending()
                                }
                            }
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
        hoverScale: 1
        pressedScale: 1
        onClicked: button.triggered()
    }

    component LibraryButton: RaohaneSurface {
        id: library

        required property string icon
        required property string label
        property bool selected: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 38
        surfaceRadius: RaohaneTheme.radius
        active: library.selected
        transparentIdle: !library.selected && !library.hovered
        showSheen: false
        showInnerRim: library.selected
        interactive: true
        hovered: libraryMouse.containsMouse || activeFocus
        pressed: libraryMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: "transparent"
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing
            anchors.rightMargin: RaohaneTheme.spacingSmall + 2
            spacing: RaohaneTheme.spacingSmall + 2

            RaohaneIcon {
                text: library.icon
                iconSize: 14
                fill: library.selected ? 1 : library.hovered ? 0.35 : 0
                color: library.selected || library.hovered
                    ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: library.label
                color: library.selected || library.hovered
                    ? RaohaneTheme.text
                    : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: library.selected ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: libraryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: library.forceActiveFocus()
            onClicked: library.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                library.triggered()
                event.accepted = true
            }
        }
    }

    component FooterButton: RaohaneSurface {
        id: footer

        required property string icon
        required property string label
        property bool accent: false
        signal triggered()

        implicitWidth: footerRow.implicitWidth + RaohaneTheme.spacingLarge + RaohaneTheme.spacingSmall
        implicitHeight: 34
        surfaceRadius: RaohaneTheme.radius
        active: footer.accent
        showSheen: false
        showInnerRim: footer.accent
        interactive: true
        hovered: footerMouse.containsMouse || activeFocus
        pressed: footerMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        Row {
            id: footerRow
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: footer.icon
                iconSize: 13
                fill: footer.accent ? 1 : footer.hovered ? 0.35 : 0
                color: footer.accent || footer.hovered
                    ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }

            Text {
                text: footer.label
                color: footer.accent || footer.hovered
                    ? RaohaneTheme.text
                    : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: footerMouse
            anchors.fill: parent
            enabled: footer.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: footer.forceActiveFocus()
            onClicked: footer.triggered()
        }

        Keys.onPressed: event => {
            if (!footer.enabled)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                footer.triggered()
                event.accepted = true
            }
        }
    }
}
