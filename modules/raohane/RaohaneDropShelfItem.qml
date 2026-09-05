pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property string entryPath
    required property int itemIndex

    readonly property bool imageLike: /\.(png|jpe?g|webp|bmp|gif)$/i.test(root.entryPath)
    readonly property string fileName: root.entryPath.split("/").pop() || root.entryPath

    signal openRequested(string path)
    signal revealRequested(string path)
    signal removeRequested(int index)
    signal copyRequested(string path)

    width: 112
    height: 120
    surfaceRadius: 10
    raised: false
    interactive: true
    hovered: dragMouse.containsMouse || actionRow.hovered
    pressed: dragMouse.pressed
    showSheen: false
    hoverScale: 1
    pressedScale: 1
    color: hovered ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceDeep
    border.color: Drag.active ? RaohaneTheme.accentBorder
        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

    Drag.active: dragMouse.drag.active
    Drag.dragType: Drag.Automatic
    Drag.mimeData: ({ "text/uri-list": "file://" + root.entryPath })
    Drag.supportedActions: Qt.CopyAction

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 2
            topMargin: 8
            bottomMargin: 8
        }
        width: 2
        radius: 1
        color: RaohaneTheme.accent
        opacity: root.Drag.active ? 1 : root.hovered ? 0.42 : 0.16

        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 4

        RaohaneSurface {
            id: preview

            Layout.fillWidth: true
            Layout.preferredHeight: 73
            surfaceRadius: 8
            active: dragMouse.drag.active
            showSheen: false
            color: RaohaneTheme.surfaceSubtle
            border.color: dragMouse.drag.active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
            clip: true

            Image {
                id: previewImage

                anchors.fill: parent
                source: root.imageLike ? "file://" + root.entryPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: root.imageLike && status === Image.Ready
            }

            RaohaneIcon {
                anchors.centerIn: parent
                visible: !previewImage.visible
                text: root.entryPath.endsWith("/") ? "folder" : "draft"
                iconSize: 22
                fill: dragMouse.containsMouse ? 1 : 0
                symbolWeight: dragMouse.containsMouse ? 520 : 430
                color: dragMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted

                Behavior on color {
                    ColorAnimation { duration: RaohaneMotion.micro }
                }
            }

            MouseArea {
                id: dragMouse

                anchors.fill: parent
                hoverEnabled: true
                drag.target: root
                acceptedButtons: Qt.LeftButton
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onDoubleClicked: root.openRequested(root.entryPath)
                onReleased: {
                    if (root.Drag.active)
                        root.Drag.drop()
                    root.x = 0
                    root.y = 0
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.fileName
            color: RaohaneTheme.text
            font.pixelSize: 7
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
        }

        RowLayout {
            id: actionRow
            property bool hovered: openButton.hovered || revealButton.hovered || copyButton.hovered || removeButton.hovered

            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 0

            RaohaneIconButton {
                id: openButton
                Layout.fillWidth: true
                buttonSize: 22
                iconSize: 11
                icon: "open_in_new"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.openRequested(root.entryPath)
            }

            RaohaneIconButton {
                id: revealButton
                Layout.fillWidth: true
                buttonSize: 22
                iconSize: 11
                icon: "folder_open"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.revealRequested(root.entryPath)
            }

            RaohaneIconButton {
                id: copyButton
                Layout.fillWidth: true
                buttonSize: 22
                iconSize: 11
                icon: "content_copy"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.copyRequested(root.entryPath)
            }

            RaohaneIconButton {
                id: removeButton
                Layout.fillWidth: true
                buttonSize: 22
                iconSize: 11
                icon: "close"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.removeRequested(root.itemIndex)
            }
        }
    }
}
