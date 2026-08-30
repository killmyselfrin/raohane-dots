import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    PanelWindow {
        id: shelfWindow

        visible: RaohaneDropShelf.open
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 372
        implicitHeight: 228

        anchors {
            top: true
            left: true
        }

        margins {
            left: Math.max(20, RaohaneDropShelf.positionX - implicitWidth / 2)
            top: Math.max(20, RaohaneDropShelf.positionY - implicitHeight - 30)
        }

        WlrLayershell.namespace: "quickshell:raohane-dropshelf"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: drag => drag.accepted = drag.hasUrls
            onDropped: drop => {
                if (!drop.hasUrls) {
                    drop.accepted = false
                    return
                }
                RaohaneDropShelf.addItems(drop.urls)
                drop.accept()
            }
        }

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 20
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "shelves"
                            iconSize: 15
                            color: RaohaneTheme.accent
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Drop Shelf")
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: qsTr("%1 items").arg(RaohaneDropShelf.items.length)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                ListView {
                    id: shelfList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 124
                    orientation: ListView.Horizontal
                    spacing: 7
                    clip: true
                    model: RaohaneDropShelf.items

                    delegate: RaohaneSurface {
                        id: itemCard
                        required property string modelData

                        width: 104
                        height: 116
                        surfaceRadius: 14
                        raised: false
                        hovered: itemMouse.containsMouse
                        showSheen: false

                        readonly property string entryPath: modelData
                        readonly property bool imageLike: /\.(png|jpe?g|webp|bmp|gif)$/i.test(entryPath)

                        Drag.active: itemMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.mimeData: ({ "text/uri-list": "file://" + entryPath })
                        Drag.supportedActions: Qt.CopyAction

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 5

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 76
                                radius: 11
                                color: RaohaneTheme.surfaceSubtle
                                border.width: 1
                                border.color: RaohaneTheme.border
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: itemCard.imageLike ? "file://" + itemCard.entryPath : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: itemCard.imageLike && status === Image.Ready
                                }

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    visible: !itemCard.imageLike
                                    text: itemCard.entryPath.endsWith("/") ? "folder" : "draft"
                                    iconSize: 24
                                    color: RaohaneTheme.textMuted
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemCard.entryPath.split("/").pop()
                                color: RaohaneTheme.text
                                font.pixelSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            drag.target: itemCard
                            cursorShape: Qt.OpenHandCursor
                            onReleased: {
                                if (itemCard.Drag.active)
                                    itemCard.Drag.drop()
                                itemCard.x = 0
                                itemCard.y = 0
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: RaohaneDropShelf.items.length === 0
                        spacing: 4

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "move_to_inbox"
                            iconSize: 24
                            color: RaohaneTheme.textFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Drop files here")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ShelfButton {
                        title: qsTr("Copy")
                        icon: "content_copy"
                        primary: true
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.copyAll()
                    }
                    ShelfButton {
                        title: qsTr("Clear")
                        icon: "delete_sweep"
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.clear()
                    }
                    ShelfButton {
                        title: qsTr("Close")
                        icon: "close"
                        onTriggered: RaohaneDropShelf.hide()
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dropShelf"
        function open(): void { RaohaneDropShelf.open = true }
        function close(): void { RaohaneDropShelf.hide() }
        function clear(): void { RaohaneDropShelf.clear() }
        function copyAll(): void { RaohaneDropShelf.copyAll() }
    }

    component ShelfButton: Rectangle {
        id: button
        required property string title
        required property string icon
        property bool primary: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: 10
        opacity: button.enabled ? 1 : 0.35
        color: buttonMouse.containsMouse && button.enabled ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: button.primary ? RaohaneTheme.accentBorder : RaohaneTheme.border

        Row {
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: button.icon
                iconSize: 13
                color: button.primary ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
            Text {
                text: button.title
                color: button.primary ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }
}
