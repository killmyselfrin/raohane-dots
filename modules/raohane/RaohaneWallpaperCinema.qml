pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// The cinematic mode uses the same FolderListModel as the normal grid.
// Only a handful of thumbnails are instantiated; applying wallpapers stays
// owned by RaohaneWallpaperSelector and RaohaneWallpapers.
Item {
    id: root

    required property var folderModel
    property string selectedPath: ""
    property string appliedPath: ""
    property bool animateMotion: true

    signal entryChosen(string path, bool directory)
    signal applyRequested()

    readonly property int cardWidth: Math.min(350, Math.max(174, Math.round(width * 0.46)))
    readonly property int cardHeight: Math.max(180, Math.min(370, Math.round(height * 0.65)))

    function focusCurrent(): void {
        const tile = carousel.currentItem
        if (tile && tile.filePath.length > 0)
            root.entryChosen(tile.filePath, tile.isDirectory)
    }

    function step(direction: int): void {
        if (direction > 0)
            carousel.incrementCurrentIndex()
        else
            carousel.decrementCurrentIndex()
        root.focusCurrent()
    }

    onFolderModelChanged: carousel.currentIndex = 0

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: RaohaneTheme.background
        border.color: RaohaneTheme.borderFaint
        clip: true

        Image {
            anchors.fill: parent
            source: root.selectedPath.length > 0 && !RaohaneWallpapers.isVideo(root.selectedPath)
                ? "file://" + root.selectedPath : ""
            sourceSize.width: 1024
            sourceSize.height: 640
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            opacity: status === Image.Ready ? 0.19 : 0
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: RaohaneTheme.dark ? "#cf090d18" : "#e4f1eff5" }
                GradientStop { position: 0.52; color: RaohaneTheme.dark ? "#a9080b13" : "#a6f6f4f9" }
                GradientStop { position: 1; color: RaohaneTheme.dark ? "#ec080b12" : "#eaf7f5fa" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, Math.min(22, width * 0.035))
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 33
            spacing: 8

            RaohaneIcon {
                text: "auto_awesome"
                iconSize: 17
                color: RaohaneTheme.accent
            }

            Text {
                text: qsTr("CINEMATIC GALLERY")
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.7
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("%1 items").arg(root.folderModel?.count ?? 0)
                color: RaohaneTheme.textMuted
                font.pixelSize: 10
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
                spacing: -Math.min(42, root.cardWidth * 0.10)
                clip: false
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapToItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - root.cardWidth / 2
                preferredHighlightEnd: width / 2 + root.cardWidth / 2
                cacheBuffer: root.cardWidth
                currentIndex: -1

                header: Item { width: Math.max(0, carousel.width / 2 - root.cardWidth / 2); height: 1 }
                footer: Item { width: Math.max(0, carousel.width / 2 - root.cardWidth / 2); height: 1 }

                onCountChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                }
                onCurrentItemChanged: {
                    if (root.visible)
                        root.focusCurrent()
                }

                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index

                    readonly property string filePath: String(modelData.filePath ?? "")
                    readonly property string title: String(modelData.fileName ?? filePath.split("/").pop())
                    readonly property bool isDirectory: Boolean(modelData.fileIsDir ?? false)
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
                        scale: tile.focused ? 1 : 0.78
                        opacity: tile.focused ? 1 : 0.66

                        Behavior on scale {
                            enabled: root.animateMotion
                            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                        }
                        Behavior on opacity {
                            enabled: root.animateMotion
                            NumberAnimation { duration: RaohaneMotion.fast }
                        }

                        transform: Rotation {
                            origin.x: tileFace.width / 2
                            origin.y: tileFace.height / 2
                            axis.x: 0; axis.y: 1; axis.z: 0
                            angle: tile.focused ? 0 : (tile.index < carousel.currentIndex ? 10 : -10)
                            Behavior on angle {
                                enabled: root.animateMotion
                                NumberAnimation { duration: RaohaneMotion.standard }
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
                                    if (carousel.currentIndex === tile.index)
                                        root.entryChosen(tile.filePath, tile.isDirectory)
                                    else
                                        carousel.currentIndex = tile.index
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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 12

                NavigationButton { glyph: "chevron_left"; onTriggered: root.step(-1) }
                NavigationButton { glyph: "chevron_right"; onTriggered: root.step(1) }
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

        width: 38
        height: 38
        surfaceRadius: 12
        raised: false
        showSheen: false
        idleColor: RaohaneTheme.surfaceRaised
        border.color: RaohaneTheme.borderFaint

        RaohaneIcon {
            anchors.centerIn: parent
            text: nav.glyph
            iconSize: 20
            color: RaohaneTheme.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.triggered()
        }
    }
}
