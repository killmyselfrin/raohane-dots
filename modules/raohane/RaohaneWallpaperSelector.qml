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
    property string targetScreenName: ""
    property bool studioExpanded: false

    function isVideo(path: string): bool {
        return RaohaneWallpapers.isVideo(path)
    }

    function appliedPath(): string {
        return RaohaneState.wallpaperSelectorTarget === "lockWall"
            ? RaohaneConfig.lockWallpaperPath
            : RaohaneConfig.wallpaperPathForScreen(root.targetScreenName)
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
            RaohaneWallpapers.startPreview(path, root.targetScreenName)
    }

    function previewPending(): void {
        if (root.pendingPath.length > 0)
            RaohaneWallpapers.startPreview(root.pendingPath, root.targetScreenName)
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
            // Keep the selector open until the file probe has validated the
            // chosen path; a bad selection must not close the UI.
            RaohaneWallpapers.select(path, true, finalPath => {
                RaohaneWallpapers.apply(finalPath, true, root.targetScreenName)
                root.close()
            })
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
                // Let the actual wallpaper show around the selector instead
                // of covering the desktop in an opaque full-screen scrim.
                color: RaohaneTheme.dark
                    ? Qt.rgba(0.01, 0.015, 0.035, 0.24)
                    : Qt.rgba(0.18, 0.17, 0.15, 0.10)
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
                property bool cinematicMode: true

                width: Math.max(1, Math.min(parent.width - 32, cinematicMode ? 1400 : 1040))
                height: Math.max(1, Math.min(parent.height - 48, cinematicMode ? 790 : 720))
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: !cinematicMode
                showSheen: !cinematicMode
                showInnerRim: !cinematicMode
                transparentIdle: cinematicMode
                // Cinematic is an immersive overlay on the real wallpaper,
                // while Grid retains a denser glass panel for search/folders.
                // Only material alpha changes: thumbnails/buttons stay crisp.
                idleColor: Qt.rgba(RaohaneTheme.background.r,
                    RaohaneTheme.background.g, RaohaneTheme.background.b,
                    cinematicMode ? (RaohaneTheme.dark ? 0.10 : 0.20)
                        : (RaohaneTheme.dark ? 0.53 : 0.76))
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
                    } else if (selector.cinematicMode && event.key === Qt.Key_Left) {
                        if (cinemaLoader.item)
                            cinemaLoader.item.step(-1)
                        event.accepted = true
                    } else if (selector.cinematicMode && event.key === Qt.Key_Right) {
                        if (cinemaLoader.item)
                            cinemaLoader.item.step(1)
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
                                idleColor: Qt.rgba(RaohaneTheme.background.r,
                                    RaohaneTheme.background.g, RaohaneTheme.background.b,
                                    RaohaneTheme.dark ? 0.42 : 0.68)
                                activeColor: Qt.rgba(RaohaneTheme.background.r,
                                    RaohaneTheme.background.g, RaohaneTheme.background.b,
                                    RaohaneTheme.dark ? 0.65 : 0.84)
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

                            FooterButton {
                                icon: "tune"
                                label: qsTr("Studio")
                                accent: root.studioExpanded
                                onTriggered: root.studioExpanded = !root.studioExpanded
                            }

                            FooterButton {
                                icon: selector.cinematicMode ? "grid_view" : "view_carousel"
                                label: selector.cinematicMode ? qsTr("Grid") : qsTr("Cinematic")
                                onTriggered: selector.cinematicMode = !selector.cinematicMode
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

                    // Saved folders, quick favorites, source and timing controls
                    // share the normal wallpaper picker instead of creating a
                    // second wallpaper manager or an always-active overlay.
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.studioExpanded
                        spacing: 6
                        Layout.leftMargin: 14
                        Layout.rightMargin: 14

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StudioChip {
                                glyph: RaohaneWallpapers.isFavorite(root.pendingPath) ? "star" : "star_border"
                                title: qsTr("Favorite")
                                enabled: root.pendingPath.startsWith("/")
                                onTriggered: RaohaneWallpapers.toggleFavorite(root.pendingPath)
                            }
                            StudioChip {
                                glyph: "create_new_folder"
                                title: qsTr("Save collection")
                                onTriggered: RaohaneWallpapers.saveCurrentCollection()
                            }
                            StudioChip {
                                glyph: "palette"
                                title: RaohaneConfig.wallpaperAdaptiveAccent
                                    ? qsTr("Adaptive on") : qsTr("Adaptive off")
                                onTriggered: RaohaneConfig.wallpaperAdaptiveAccent =
                                    !RaohaneConfig.wallpaperAdaptiveAccent
                            }

                            Text {
                                text: qsTr("Monitor")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                            ComboBox {
                                id: targetMonitorChoice
                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 30
                                enabled: RaohaneState.wallpaperSelectorTarget !== "lockWall"
                                model: [qsTr("All monitors")].concat(
                                    Quickshell.screens.map(screen => String(screen.name)))
                                currentIndex: Math.max(0, model.indexOf(root.targetScreenName.length
                                    ? root.targetScreenName : qsTr("All monitors")))
                                onActivated: index => {
                                    root.targetScreenName = index > 0
                                        ? String(Quickshell.screens[index - 1]?.name ?? "") : ""
                                    RaohaneWallpapers.stopPreview()
                                    root.resetPending()
                                }
                            }

                            Text {
                                text: qsTr("Auto")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                            ComboBox {
                                Layout.preferredWidth: 112
                                Layout.preferredHeight: 30
                                model: [qsTr("Off"), qsTr("5 min"), qsTr("15 min"), qsTr("1 hour")]
                                currentIndex: RaohaneConfig.wallpaperChangeInterval === 300000 ? 1
                                    : RaohaneConfig.wallpaperChangeInterval === 900000 ? 2
                                    : RaohaneConfig.wallpaperChangeInterval === 3600000 ? 3 : 0
                                onActivated: index => {
                                    const intervals = [0, 300000, 900000, 3600000]
                                    RaohaneConfig.wallpaperChangeInterval = intervals[index]
                                }
                            }
                            ComboBox {
                                Layout.preferredWidth: 125
                                Layout.preferredHeight: 30
                                model: [qsTr("Folder"), qsTr("Favorites")]
                                currentIndex: RaohaneConfig.wallpaperAutoSource === "favorites" ? 1 : 0
                                onActivated: index => RaohaneConfig.wallpaperAutoSource =
                                    index === 1 ? "favorites" : "folder"
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            contentWidth: shortcuts.implicitWidth
                            contentHeight: height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Row {
                                id: shortcuts
                                spacing: 6
                                height: parent.height

                                Repeater {
                                    model: RaohaneConfig.wallpaperCollections
                                    delegate: StudioChip {
                                        required property var modelData
                                        glyph: "folder"
                                        title: modelData.name
                                        onTriggered: RaohaneWallpapers.setDirectory(modelData.path)
                                    }
                                }
                                Repeater {
                                    model: RaohaneConfig.wallpaperFavorites
                                    delegate: StudioChip {
                                        required property string modelData
                                        glyph: "star"
                                        title: modelData.split("/").pop()
                                        onTriggered: root.selectPath(modelData, false)
                                    }
                                }
                                Text {
                                    visible: RaohaneConfig.wallpaperCollections.length === 0
                                        && RaohaneConfig.wallpaperFavorites.length === 0
                                    text: qsTr("Star an image or save a folder to build your library")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        RaohaneSurface {
                            visible: !selector.cinematicMode
                            Layout.preferredWidth: visible ? 176 : 0
                            Layout.fillHeight: true
                            surfaceRadius: 0
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            idleColor: Qt.rgba(RaohaneTheme.background.r,
                                RaohaneTheme.background.g, RaohaneTheme.background.b,
                                RaohaneTheme.dark ? 0.34 : 0.64)
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
                            visible: !selector.cinematicMode
                            Layout.fillHeight: true
                            Layout.preferredWidth: visible ? 1 : 0
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

                                // A URL loader prevents a faulty optional carousel
                                // from breaking startup of the existing grid.
                                Loader {
                                    id: cinemaLoader
                                    anchors.fill: parent
                                    active: selector.cinematicMode
                                    visible: selector.cinematicMode
                                    // The URL is constant. Toggling active only
                                    // creates/destroys the item; deriving source
                                    // from active creates an unnecessary cycle.
                                    source: Qt.resolvedUrl("RaohaneWallpaperCinema.qml")
                                    // The model may select its first item before
                                    // Connections attaches to the new Loader item.
                                    onLoaded: {
                                        // Pass the real Qt model explicitly at creation
                                        // time. Relying on later Binding evaluation may
                                        // leave the ListView without delegates.
                                        if (item) {
                                            item.folderModel = RaohaneWallpapers.folderModel
                                            item.width = cinemaLoader.width
                                            item.height = cinemaLoader.height
                                        }
                                        Qt.callLater(() => {
                                            if (selector.cinematicMode && cinemaLoader.item)
                                                cinemaLoader.item.focusCurrent()
                                        })
                                        cinemaHealthCheck.restart()
                                    }
                                    onStatusChanged: {
                                        if (status === Loader.Error && selector.cinematicMode) {
                                            console.warn("[Raohane] Cinematic gallery unavailable, restoring grid")
                                            // Changing active synchronously from its own
                                            // statusChanged notification triggers a
                                            // re-entrant binding loop on this Qt version.
                                            Qt.callLater(() => {
                                                if (selector.cinematicMode
                                                        && cinemaLoader.status === Loader.Error)
                                                    selector.cinematicMode = false
                                            })
                                        }
                                    }
                                }

                                // A QML type can report Loader.Ready while a
                                // ListView failed to create delegates (for
                                // example, incorrect required model roles).
                                // Never strand the user in an empty gallery.
                                Timer {
                                    id: cinemaHealthCheck
                                    interval: 1200
                                    repeat: false
                                    onTriggered: {
                                        const gallery = cinemaLoader.item
                                        if (selector.cinematicMode && gallery
                                                && RaohaneWallpapers.folderModel.count > 0
                                                && (!gallery.hasCurrentCard || gallery.width < 2 || gallery.height < 2)) {
                                            console.warn("[Raohane] Cinematic cards are unavailable; reverting to Grid")
                                            selector.cinematicMode = false
                                        }
                                    }
                                }

                                Binding {
                                    target: cinemaLoader.item
                                    property: "folderModel"
                                    value: RaohaneWallpapers.folderModel
                                    when: cinemaLoader.item !== null
                                }
                                // Force real viewport dimensions even if a
                                // dynamically instantiated root Item has no
                                // implicit size. A zero-size carousel produces
                                // the exact blank picker shown in the report.
                                Binding {
                                    target: cinemaLoader.item
                                    property: "width"
                                    value: cinemaLoader.width
                                    when: cinemaLoader.item !== null
                                }
                                Binding {
                                    target: cinemaLoader.item
                                    property: "height"
                                    value: cinemaLoader.height
                                    when: cinemaLoader.item !== null
                                }
                                Binding {
                                    target: cinemaLoader.item
                                    property: "selectedPath"
                                    value: root.pendingPath
                                    when: cinemaLoader.item !== null
                                }
                                Binding {
                                    target: cinemaLoader.item
                                    property: "appliedPath"
                                    value: root.appliedPath()
                                    when: cinemaLoader.item !== null
                                }
                                Binding {
                                    target: cinemaLoader.item
                                    property: "animateMotion"
                                    value: RaohaneMotion.transformMotionEnabled && !RaohanePerformance.gameModeActive
                                    when: cinemaLoader.item !== null
                                }
                                Connections {
                                    target: cinemaLoader.item
                                    ignoreUnknownSignals: true
                                    function onEntryChosen(path: string, directory: bool): void {
                                        root.selectPath(path, directory)
                                    }
                                    // Browsing updates the pending selection immediately,
                                    // but live wallpaper decoding happens only after the
                                    // cinematic debounce (or an explicit click).
                                    function onEntryHighlighted(path: string): void {
                                        if (path.length > 0)
                                            root.pendingPath = path
                                    }
                                    function onPreviewRequested(path: string): void {
                                        if (RaohaneConfig.wallpaperPreview
                                                && RaohaneState.wallpaperSelectorOpen
                                                && root.pendingPath === path)
                                            RaohaneWallpapers.startPreview(path, root.targetScreenName)
                                    }
                                    function onApplyRequested(): void {
                                        root.applyPending()
                                    }
                                }

                                GridView {
                                    id: gallery
                                    anchors.fill: parent
                                    clip: true
                                    visible: !selector.cinematicMode
                                    model: selector.cinematicMode ? null : RaohaneWallpapers.folderModel
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
                                                source: !cell.isDirectory && !cell.video && cell.filePath.length > 0
                                                    ? "file://" + cell.filePath
                                                    : ""
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
                                    visible: !selector.cinematicMode && RaohaneWallpapers.folderModel.count === 0
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
                                    visible: root.isVideo(root.pendingPath)
                                        && RaohaneWallpapers.previewPath === root.pendingPath
                                    icon: RaohaneWallpapers.videoPreviewPaused ? "play_arrow" : "pause"
                                    label: RaohaneWallpapers.videoPreviewPaused
                                        ? qsTr("Resume") : qsTr("Pause")
                                    onTriggered: RaohaneWallpapers.videoPreviewPaused =
                                        !RaohaneWallpapers.videoPreviewPaused
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

    component StudioChip: RaohaneSurface {
        id: chip
        required property string glyph
        required property string title
        signal triggered()
        implicitWidth: Math.min(200, chipLabel.implicitWidth + 43)
        implicitHeight: 30
        surfaceRadius: 10
        showSheen: false
        raised: false
        idleColor: RaohaneTheme.surfaceDeep
        idleBorderColor: RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 6
            RaohaneIcon {
                text: chip.glyph
                iconSize: 14
                color: RaohaneTheme.accent
            }
            Text {
                id: chipLabel
                text: chip.title
                color: RaohaneTheme.text
                font.pixelSize: 10
                elide: Text.ElideRight
                width: Math.min(155, implicitWidth)
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: chip.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.triggered()
        }
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
