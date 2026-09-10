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

    width: 126
    height: 136
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    active: root.Drag.active
    interactive: true
    hovered: dragMouse.containsMouse || actionRow.hovered
    pressed: dragMouse.pressed
    showSheen: false
    hoverScale: 1
    pressedScale: 1
    idleColor: RaohaneTheme.surfaceDeep
    hoverColor: RaohaneTheme.surfaceRaised
    pressedColor: RaohaneTheme.surfacePressed
    activeColor: RaohaneTheme.surfaceRaised
    idleBorderColor: RaohaneTheme.borderFaint
    hoverBorderColor: RaohaneTheme.borderStrong
    pressedBorderColor: RaohaneTheme.borderStrong
    activeBorderColor: RaohaneTheme.accentBorder
    showStateRail: true
    stateRailColor: RaohaneTheme.accent
    stateRailOpacity: root.Drag.active ? 1 : root.hovered ? 0.42 : 0.16
    stateRailWidth: 2
    stateRailLength: Math.max(34, height - 2 * RaohaneTheme.spacing)

    Drag.active: dragMouse.drag.active
    Drag.dragType: Drag.Automatic
    Drag.mimeData: ({ "text/uri-list": "file://" + root.entryPath })
    Drag.supportedActions: Qt.CopyAction

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacingSmall + 2
        spacing: RaohaneTheme.spacingSmall - 1

        RaohaneSurface {
            id: preview

            Layout.fillWidth: true
            Layout.preferredHeight: 82
            surfaceRadius: RaohaneTheme.radiusSmall
            active: dragMouse.drag.active
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            activeColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: RaohaneTheme.borderFaint
            activeBorderColor: RaohaneTheme.accentBorder
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
                iconSize: 24
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
            font.pixelSize: 8
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
        }

        RowLayout {
            id: actionRow
            property bool hovered: openButton.hovered || revealButton.hovered || copyButton.hovered || removeButton.hovered

            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 0

            RaohaneIconButton {
                id: openButton
                Layout.fillWidth: true
                buttonSize: 26
                iconSize: 12
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
                buttonSize: 26
                iconSize: 12
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
                buttonSize: 26
                iconSize: 12
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
                buttonSize: 26
                iconSize: 12
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
