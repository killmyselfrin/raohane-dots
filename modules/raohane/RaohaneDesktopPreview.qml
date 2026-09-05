pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

// Configuration preview only: no compositor capture, video player or polling.
Item {
    id: root

    readonly property string wallpaperPath: RaohaneConfig.wallpaperPath
    readonly property bool videoWallpaper: RaohaneWallpapers.isVideo(root.wallpaperPath)
    readonly property int workspaceCount: Math.max(2, Math.min(12, RaohaneConfig.overviewWorkspaceCount))
    readonly property int workspaceColumns: Math.max(1, Math.min(RaohaneConfig.overviewColumns, root.workspaceCount))

    implicitHeight: previewColumn.implicitHeight

    ColumnLayout {
        id: previewColumn
        width: parent.width
        spacing: 10

        GridLayout {
            Layout.fillWidth: true
            columns: width >= 600 ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 222
                surfaceRadius: RaohaneTheme.radiusLarge
                showSheen: false
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: qsTr("Wallpaper preview")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: RaohaneTheme.surfaceSubtle
                        radius: 8
                        clip: true

                        Image {
                            id: wallpaperImage
                            anchors.fill: parent
                            source: root.videoWallpaper ? "" : RaohanePaths.fileUrl(root.wallpaperPath)
                            sourceSize: Qt.size(640, 360)
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.max(0, parent.width - 24)
                            visible: wallpaperImage.status !== Image.Ready
                            spacing: 6

                            RaohaneIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.videoWallpaper ? "movie" : "wallpaper"
                                iconSize: 24
                                color: RaohaneTheme.textMuted
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.videoWallpaper ? qsTr("Video wallpaper")
                                    : wallpaperImage.status === Image.Loading ? qsTr("Loading preview…")
                                    : root.wallpaperPath.length > 0 ? qsTr("Preview unavailable")
                                    : qsTr("No wallpaper selected")
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.wallpaperPath.length > 0
                            ? RaohanePaths.cleanPath(root.wallpaperPath).split("/").pop()
                            : qsTr("Choose a wallpaper to begin")
                        elide: Text.ElideMiddle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 222
                surfaceRadius: RaohaneTheme.radiusLarge
                showSheen: false
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: qsTr("Spaces layout preview")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Grid {
                            id: spacesGrid
                            readonly property int rowCount: Math.ceil(root.workspaceCount / columns)
                            readonly property real cellWidth: Math.max(1, Math.min(
                                (parent.width - (columns - 1) * spacing) / columns,
                                (parent.height - (rowCount - 1) * spacing) / rowCount * 16 / 9))
                            anchors.centerIn: parent
                            columns: root.workspaceColumns
                            spacing: 4

                            Repeater {
                                model: root.workspaceCount

                                delegate: Rectangle {
                                    required property int index
                                    width: spacesGrid.cellWidth
                                    height: width * 9 / 16
                                    radius: Math.min(6, height / 4)
                                    color: RaohaneTheme.surfaceSubtle
                                    border.width: 1
                                    border.color: RaohaneTheme.borderStrong

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(parent.index + 1)
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: Math.max(5, Math.min(10, parent.height * 0.6))
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("%1 workspaces · %2 columns").arg(root.workspaceCount).arg(root.workspaceColumns)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width >= 420 ? 3 : 1
            columnSpacing: 8
            rowSpacing: 8

            PreviewAction {
                label: qsTr("Choose wallpaper")
                icon: "wallpaper"
                onTriggered: {
                    RaohaneState.wallpaperSelectorTarget = "wallpaper"
                    RaohaneState.setPrimaryOpen("wallpaper", true)
                }
            }

            PreviewAction {
                label: qsTr("Open Spaces")
                icon: "view_quilt"
                onTriggered: RaohaneState.setPrimaryOpen("overview", true)
            }

            PreviewAction {
                label: qsTr("Desktop Widgets")
                icon: "widgets"
                onTriggered: RaohaneSettingsRouter.request("widgets", "")
            }
        }
    }

    component PreviewAction: RaohaneSurface {
        id: action
        required property string label
        required property string icon
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 36
        surfaceRadius: 10
        interactive: true
        transformMotion: false
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        showSheen: false
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: action.label
        Accessible.onPressAction: action.triggered()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            RaohaneIcon {
                text: action.icon
                iconSize: 14
                color: RaohaneTheme.accent
            }

            Text {
                Layout.fillWidth: true
                text: action.label
                color: RaohaneTheme.text
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                action.triggered()
                event.accepted = true
            }
        }
    }
}
