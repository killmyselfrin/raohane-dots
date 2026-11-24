pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import qs.modules.raohane
import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    readonly property string currentPath: RaohaneConfig.wallpaperPath.length > 0
        ? RaohaneConfig.wallpaperPath : RaohanePaths.defaultWallpaperPath
    readonly property bool currentIsVideo: RaohaneWallpapers.isVideo(root.currentPath)
    readonly property string currentPreviewSource: root.currentIsVideo
        ? RaohaneWallpapers.generatedVideoPosterUrl(root.currentPath)
        : RaohanePaths.fileUrl(root.currentPath)
    readonly property var transitionEffects: [
        { id: "fade", title: qsTr("Fade"), detail: qsTr("A quiet crossfade") },
        { id: "wipe", title: qsTr("Wipe"), detail: qsTr("Reveal from left to right") },
        { id: "circle", title: qsTr("Circle"), detail: qsTr("Expand from the center") },
        { id: "dissolve", title: qsTr("Dissolve"), detail: qsTr("Break into soft pixel blocks") }
    ]
    property bool directoryDialogOpen: false

    implicitHeight: Math.max(640, studioColumn.implicitHeight + 32)

    function chooseWallpaper(): void {
        RaohaneState.wallpaperSelectorTarget = "wallpaper"
        RaohaneState.setPrimaryOpen("wallpaper", true)
    }

    function chooseDirectory(): void {
        directoryDialog.open()
    }

    function selectEffect(effectId: string): void {
        RaohaneConfig.wallpaperTransitionEffect = effectId
        RaohaneConfig.wallpaperTransitionMode = "custom"
    }

    FileDialog {
        id: directoryDialog
        title: qsTr("Choose wallpaper directory")
        fileMode: FileDialog.OpenDirectory
        onAccepted: RaohaneWallpapers.setDirectory(RaohaneWallpapers.cleanPath(selectedFolder))
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: studioColumn.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: studioColumn
            width: Math.min(parent.width - 36, 1080)
            anchors.horizontalCenter: parent.horizontalCenter
            y: 16
            spacing: 12

            // Current wallpaper hero
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 204

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: RaohaneTheme.surfaceSubtle
                    border.color: RaohaneTheme.borderFaint
                    clip: true
                }

                Image {
                    anchors.fill: parent
                    source: root.currentPreviewSource
                    sourceSize: Qt.size(1500, 420)
                    asynchronous: true
                    cache: true
                    smooth: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#08090f00" }
                        GradientStop { position: 0.45; color: "#22080a12" }
                        GradientStop { position: 1.0; color: "#e6080a12" }
                    }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        RaohaneSurface {
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: 142
                            surfaceRadius: 17
                            active: true
                            interactive: true
                            showSheen: false
                            activeColor: RaohaneTheme.accent
                            activeBorderColor: "transparent"
                            Accessible.role: Accessible.Button
                            Accessible.name: qsTr("Select wallpaper")
                            Accessible.onPressAction: root.chooseWallpaper()
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 7
                                RaohaneIcon { text: "wallpaper"; iconSize: 14; color: RaohaneTheme.onAccent }
                                Text { text: qsTr("Select wallpaper"); color: RaohaneTheme.onAccent; font.pixelSize: 9; font.weight: Font.DemiBold }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseWallpaper() }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            Layout.maximumWidth: parent.width * 0.52
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: root.currentPath.length > 0 ? root.currentPath.split("/").pop() : qsTr("No wallpaper selected")
                                color: "#ffffff"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideMiddle
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.currentPath
                                color: "#c9cbd4"
                                font.pixelSize: 7
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.currentPreviewSource.length === 0
                    RaohaneIcon { Layout.alignment: Qt.AlignHCenter; text: "wallpaper"; iconSize: 28; color: RaohaneTheme.textMuted }
                    Text { Layout.alignment: Qt.AlignHCenter; text: qsTr("Wallpaper preview unavailable"); color: RaohaneTheme.textMuted; font.pixelSize: 9 }
                }
            }

            // Wallpaper directory
            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                surfaceRadius: 12
                showSheen: false
                idleColor: RaohaneTheme.surfaceSubtle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    RaohaneIcon { text: "folder_open"; iconSize: 18; color: RaohaneTheme.textMuted }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: qsTr("Wallpaper directory"); color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                        Text { Layout.fillWidth: true; text: RaohaneWallpapers.effectiveDirectory; color: RaohaneTheme.textMuted; font.pixelSize: 8; elide: Text.ElideMiddle }
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 32
                        surfaceRadius: 9
                        interactive: true
                        showSheen: false
                        hovered: folderButtonMouse.containsMouse
                        RaohaneIcon { anchors.centerIn: parent; text: "folder"; iconSize: 15; color: RaohaneTheme.text }
                        MouseArea { id: folderButtonMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseDirectory() }
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: Math.min(230, parent.width * 0.34)
                        Layout.preferredHeight: 32
                        surfaceRadius: 9
                        interactive: true
                        showSheen: false
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 8
                            Text { Layout.fillWidth: true; text: RaohaneWallpapers.effectiveDirectory.split("/").pop() || qsTr("Choose folder"); color: RaohaneTheme.text; font.pixelSize: 8; elide: Text.ElideMiddle }
                            RaohaneIcon { text: "expand_more"; iconSize: 14; color: RaohaneTheme.textMuted }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseDirectory() }
                    }
                }
            }

            // Transition header and Random / Custom set segmented switch
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: qsTr("Transition"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                    Text { text: qsTr("Choose how the next wallpaper is revealed"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                }

                RaohaneSurface {
                    Layout.preferredWidth: 210
                    Layout.preferredHeight: 34
                    surfaceRadius: 17
                    showSheen: false
                    idleColor: RaohaneTheme.surfaceSubtle

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 2
                        Repeater {
                            model: [{ id: "random", title: qsTr("Random") }, { id: "custom", title: qsTr("Custom set") }]
                            delegate: RaohaneSurface {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                surfaceRadius: 14
                                active: RaohaneConfig.wallpaperTransitionMode === modelData.id
                                showSheen: false
                                activeColor: RaohaneTheme.accent
                                activeBorderColor: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.title
                                    color: parent.active ? RaohaneTheme.onAccent : RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    font.weight: parent.active ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: RaohaneConfig.wallpaperTransitionMode = modelData.id
                                }
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 720 ? 3 : width >= 430 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: root.transitionEffects
                    delegate: RaohaneSurface {
                        id: effectCard
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 142
                        surfaceRadius: 12
                        showSheen: false
                        clip: true
                        active: RaohaneConfig.wallpaperTransitionMode === "custom"
                            && RaohaneConfig.wallpaperTransitionEffect === modelData.id
                        activeColor: RaohaneTheme.surfaceHover
                        activeBorderColor: RaohaneTheme.accentBorder

                        readonly property bool hoveredCard: effectMouse.containsMouse
                        property real previewProgress: 1

                        Rectangle {
                            anchors.fill: parent
                            color: RaohaneTheme.surfaceDeep
                            radius: 12
                        }

                        RaohaneWallpaperTransitionEffect {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: root.currentPreviewSource
                            effectType: effectCard.modelData.id
                            progress: effectCard.previewProgress
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 42
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#00000000" }
                                GradientStop { position: 1; color: "#dc080a12" }
                            }
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            spacing: 2
                            Text { text: effectCard.modelData.title; color: "#ffffff"; font.pixelSize: 9; font.weight: Font.DemiBold }
                            Text { text: effectCard.modelData.detail; color: "#c7c9d2"; font.pixelSize: 7 }
                        }

                        MouseArea {
                            id: effectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectEffect(effectCard.modelData.id)
                            onEntered: effectCard.previewProgress = 0
                            onExited: effectCard.previewProgress = 1
                        }

                        NumberAnimation on previewProgress {
                            running: effectCard.hoveredCard && RaohaneMotion.transformMotionEnabled
                            from: 0
                            to: 1
                            duration: 900
                            easing.type: Easing.InOutCubic
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Transition duration")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }

                Slider {
                    Layout.preferredWidth: 190
                    from: 0
                    to: 3000
                    stepSize: 100
                    value: RaohaneConfig.wallpaperTransitionDuration
                    onMoved: RaohaneConfig.wallpaperTransitionDuration = Math.round(value / 100) * 100
                }

                Text {
                    text: qsTr("%1 ms").arg(RaohaneConfig.wallpaperTransitionDuration)
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                }
            }
        }
    }
}
