pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.modules.raohane.services

// The cinematic mode uses the same FolderListModel as the normal grid.
// Only a handful of thumbnails are instantiated; applying wallpapers stays
// owned by RaohaneWallpaperSelector and RaohaneWallpapers.
Item {
    id: root

    property var folderModel: null
    property string selectedPath: ""
    property string appliedPath: ""
    property bool animateMotion: true

    // Highlighting a carousel card must not immediately decode a full
    // background or change the applied wallpaper. Only the selected item is
    // queued; rapid wheel/drags collapse into a single preview request.
    property string queuedPreviewPath: ""
    property string displayedPreviewPath: ""
    property string incomingPreviewPath: ""
    property real incomingPreviewOpacity: 0
    readonly property int previewDelay: animateMotion ? 165 : 50
    readonly property int previewFadeDuration: animateMotion ? 210 : 0

    signal entryChosen(string path, bool directory)
    signal entryHighlighted(string path)
    signal previewRequested(string path)
    signal applyRequested()

    readonly property int cardWidth: Math.min(505, Math.max(174, Math.round(width * 0.44)))
    readonly property int cardHeight: Math.max(180, Math.min(458, Math.round(height * 0.70)))

    function highlightPath(path: string, previewImmediately: bool = false): void {
        if (!path || RaohaneWallpapers.isVideo(path)) {
            previewTimer.stop()
            queuedPreviewPath = ""
            return
        }
        queuedPreviewPath = path
        if (previewImmediately) {
            previewTimer.stop()
            commitPreview()
        } else {
            previewTimer.restart()
        }
    }

    function commitPreview(): void {
        const path = queuedPreviewPath
        if (!path.length || RaohaneWallpapers.isVideo(path))
            return
        if (path === displayedPreviewPath && incomingPreviewPath.length === 0) {
            // Already decoded in this view; no new thumbnail load required.
            root.previewRequested(path)
            return
        }
        if (path !== incomingPreviewPath) {
            previewFade.stop()
            incomingPreviewOpacity = 0
            incomingPreviewPath = path
        }
    }

    function finishPreview(): void {
        displayedPreviewPath = incomingPreviewPath
        incomingPreviewPath = ""
        incomingPreviewOpacity = 0
    }

    Timer {
        id: previewTimer
        interval: root.previewDelay
        repeat: false
        onTriggered: root.commitPreview()
    }

    NumberAnimation {
        id: previewFade
        target: root
        property: "incomingPreviewOpacity"
        from: 0
        to: 0.18
        duration: root.previewFadeDuration
        easing.type: RaohaneMotion.easeStandard
        onFinished: root.finishPreview()
    }

    function focusCurrent(): void {
        const tile = carousel.currentItem
        // Folder navigation is explicit (click/double-click), never a
        // side effect of sliding across directories in the carousel.
        if (tile && tile.filePath.length > 0 && !tile.isDirectory) {
            root.entryHighlighted(tile.filePath)
            root.highlightPath(tile.filePath)
        } else {
            previewTimer.stop()
            root.queuedPreviewPath = ""
        }
    }

    function step(direction: int): void {
        if (direction > 0)
            carousel.incrementCurrentIndex()
        else
            carousel.decrementCurrentIndex()
    }

    onFolderModelChanged: {
        previewTimer.stop()
        queuedPreviewPath = ""
        carousel.currentIndex = 0
    }

    Connections {
        target: root.folderModel
        ignoreUnknownSignals: true
        function onFolderChanged(): void {
            previewTimer.stop()
            previewFade.stop()
            root.queuedPreviewPath = ""
            root.incomingPreviewPath = ""
            root.displayedPreviewPath = ""
            root.incomingPreviewOpacity = 0
            carousel.currentIndex = 0
        }
    }

    Component.onDestruction: previewTimer.stop()

    Rectangle {
        anchors.fill: parent
        radius: 18
        // Transparent presentation glass: the live desktop remains visible
        // between cinematic cards. The wallpaper previews themselves stay
        // fully opaque and legible.
        color: Qt.rgba(RaohaneTheme.background.r, RaohaneTheme.background.g,
            RaohaneTheme.background.b, RaohaneTheme.dark ? 0.10 : 0.18)
        border.color: RaohaneTheme.borderFaint
        clip: true

        // Two bounded asynchronous layers crossfade only after the incoming
        // image is decoded. This avoids flashes and redundant full-size loads
        // when the user flicks across several wallpapers.
        Image {
            anchors.fill: parent
            source: root.displayedPreviewPath.length > 0 ? "file://" + root.displayedPreviewPath : ""
            sourceSize.width: 1024
            sourceSize.height: 640
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            opacity: status === Image.Ready ? 0.18 : 0
        }

        Image {
            id: incomingPreview
            anchors.fill: parent
            source: root.incomingPreviewPath.length > 0 ? "file://" + root.incomingPreviewPath : ""
            sourceSize.width: 1024
            sourceSize.height: 640
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            opacity: status === Image.Ready ? root.incomingPreviewOpacity : 0
            onStatusChanged: {
                if (status === Image.Ready && root.incomingPreviewPath.length > 0) {
                    // Only switch the live desktop once the bounded preview
                    // has actually decoded, avoiding black frames on slow disks.
                    root.previewRequested(root.incomingPreviewPath)
                    previewFade.stop()
                    root.incomingPreviewOpacity = 0
                    previewFade.start()
                }
                if (status === Image.Error) {
                    previewFade.stop()
                    root.incomingPreviewPath = ""
                    root.incomingPreviewOpacity = 0
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: RaohaneTheme.dark ? "#48090d18" : "#70f1eff5" }
                GradientStop { position: 0.52; color: RaohaneTheme.dark ? "#26080b13" : "#38f6f4f9" }
                GradientStop { position: 1; color: RaohaneTheme.dark ? "#72080b12" : "#7cf7f5fa" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, Math.min(22, width * 0.035))
        spacing: 8

        // A small floating glass toolbar, not a second row of decorative
        // controls. Every arrow directly navigates the real wallpaper model.
        RaohaneSurface {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.width - 28, 480)
            Layout.preferredHeight: 48
            surfaceRadius: 16
            raised: true
            showSheen: true
            idleColor: Qt.rgba(RaohaneTheme.background.r,
                RaohaneTheme.background.g, RaohaneTheme.background.b,
                RaohaneTheme.dark ? 0.64 : 0.84)
            idleBorderColor: RaohaneTheme.borderStrong

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                spacing: 9

                NavigationButton {
                    glyph: "chevron_left"
                    enabled: carousel.currentIndex > 0
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    onTriggered: root.step(-1)
                }

                RaohaneIcon {
                    text: "auto_awesome"
                    iconSize: 16
                    color: RaohaneTheme.accent
                }

                Text {
                    text: qsTr("CINEMATIC")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.6
                    color: RaohaneTheme.text
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: carousel.count > 0
                        ? qsTr("%1 / %2").arg(carousel.currentIndex + 1).arg(carousel.count)
                        : qsTr("No images")
                    font.pixelSize: 10
                    color: RaohaneTheme.textMuted
                }

                NavigationButton {
                    glyph: "chevron_right"
                    enabled: carousel.currentIndex >= 0
                        && carousel.currentIndex < carousel.count - 1
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    onTriggered: root.step(1)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: carousel
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: root.folderModel
                interactive: true
                spacing: -Math.min(64, root.cardWidth * 0.12)
                clip: false
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapToItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - root.cardWidth / 2
                preferredHighlightEnd: width / 2 + root.cardWidth / 2
                cacheBuffer: root.cardWidth * 1.5
                currentIndex: -1

                header: Item { width: Math.max(0, carousel.width / 2 - root.cardWidth / 2); height: 1 }
                footer: Item { width: Math.max(0, carousel.width / 2 - root.cardWidth / 2); height: 1 }

                onCountChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                    if (count === 0) {
                        previewTimer.stop()
                        root.queuedPreviewPath = ""
                    }
                }
                onCurrentItemChanged: {
                    if (root.visible)
                        root.focusCurrent()
                }

                delegate: Item {
                    id: tile
                    // Named FolderListModel roles are provided directly by
                    // Qt. A required modelData object may be absent on some
                    // versions, causing every card to fail creation.
                    required property string filePath
                    required property string fileName
                    required property bool fileIsDir
                    required property int index

                    readonly property string title: fileName.length > 0
                        ? fileName : filePath.split("/").pop()
                    readonly property bool isDirectory: fileIsDir
                    readonly property bool video: RaohaneWallpapers.isVideo(filePath)
                    readonly property bool focused: ListView.isCurrentItem
                    readonly property bool applied: !isDirectory && root.appliedPath === filePath

                    width: root.cardWidth
                    height: carousel.height
                    z: focused ? 10 : 1

                    Item {
                        id: tileFace
                        width: tile.width - 7
                        height: root.cardHeight
                        anchors.centerIn: parent
                        scale: tile.focused ? 1 : 0.76
                        opacity: tile.focused ? 1 : 0.69

                        Behavior on scale {
                            enabled: root.animateMotion
                            NumberAnimation { duration: RaohaneMotion.selectionTravel; easing.type: RaohaneMotion.easeEmphasized }
                        }
                        Behavior on opacity {
                            enabled: root.animateMotion
                            NumberAnimation { duration: RaohaneMotion.micro }
                        }

                        transform: Rotation {
                            origin.x: tileFace.width / 2
                            origin.y: tileFace.height / 2
                            axis.x: 0; axis.y: 1; axis.z: 0
                            angle: tile.focused ? 0 : (tile.index < carousel.currentIndex ? 10 : -10)
                            Behavior on angle {
                                enabled: root.animateMotion
                                NumberAnimation { duration: RaohaneMotion.selectionTravel; easing.type: RaohaneMotion.easeEmphasized }
                            }
                        }

                        RaohaneSurface {
                            id: face
                            anchors.fill: parent
                            surfaceRadius: 18
                            raised: tile.focused
                            showSheen: tile.focused
                            showInnerRim: tile.focused
                            border.width: tile.focused ? 2 : 1
                            border.color: tile.focused ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: !tile.isDirectory && !tile.video && tile.filePath.length
                                    ? "file://" + tile.filePath : ""
                                sourceSize.width: 660
                                sourceSize.height: 460
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready && !tile.video && !tile.isDirectory
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: tile.video || tile.isDirectory
                                color: RaohaneTheme.surfaceDeep
                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: tile.isDirectory ? "folder" : "movie"
                                    iconSize: 48
                                    color: RaohaneTheme.accent
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.5; color: "#00000000" }
                                    GradientStop { position: 1; color: "#cc060915" }
                                }
                            }

                            RowLayout {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 13
                                }
                                spacing: 7

                                RaohaneIcon {
                                    text: tile.isDirectory ? "folder" : tile.video ? "movie" : "image"
                                    iconSize: 14
                                    color: "#eaeefc"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    minimumPixelSize: 9
                                    text: tile.title
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideMiddle
                                }

                                RaohaneIcon {
                                    visible: tile.applied
                                    text: "check_circle"
                                    iconSize: 18
                                    color: RaohaneTheme.accent
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (carousel.currentIndex === tile.index) {
                                        root.entryChosen(tile.filePath, tile.isDirectory)
                                        if (!tile.isDirectory)
                                            root.highlightPath(tile.filePath, true)
                                    } else {
                                        carousel.currentIndex = tile.index
                                    }
                                }
                                onDoubleClicked: {
                                    if (tile.isDirectory) {
                                        root.entryChosen(tile.filePath, true)
                                    } else {
                                        root.entryChosen(tile.filePath, false)
                                        root.applyRequested()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: carousel.count === 0
                spacing: 8

                RaohaneIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "image_not_supported"
                    iconSize: 34
                    color: RaohaneTheme.textFaint
                }

                Text {
                    text: qsTr("No wallpapers found in this folder")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 11
                }
            }

        }

        Text {
            Layout.fillWidth: true
            text: root.selectedPath.length > 0
                ? root.selectedPath.split("/").pop()
                : qsTr("Choose an image to preview")
            color: RaohaneTheme.text
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("Scroll or use the arrows to explore. Double-click to apply.")
            color: RaohaneTheme.textMuted
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    component NavigationButton: RaohaneSurface {
        id: nav
        required property string glyph
        signal triggered()

        implicitWidth: 38
        implicitHeight: 38
        surfaceRadius: 11
        opacity: enabled ? 1 : 0.4
        raised: false
        showSheen: false
        idleColor: Qt.rgba(RaohaneTheme.background.r,
            RaohaneTheme.background.g, RaohaneTheme.background.b,
            RaohaneTheme.dark ? 0.60 : 0.80)
        border.color: RaohaneTheme.borderFaint

        RaohaneIcon {
            anchors.centerIn: parent
            text: nav.glyph
            iconSize: 20
            color: RaohaneTheme.text
        }

        MouseArea {
            anchors.fill: parent
            enabled: nav.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: nav.triggered()
        }
    }
}
