import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

// Native drag/drop transfer shelf. The old common-widget singleton and its
// Hyprland service chain are no longer required by the active panel family.
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
        implicitWidth: 380
        implicitHeight: 236

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

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Drop Shelf")
                        color: RaohaneTheme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: qsTr("%1 items").arg(RaohaneDropShelf.items.length)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                    }
                }

                ListView {
                    id: shelfList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 128
                    orientation: ListView.Horizontal
                    spacing: 8
                    clip: true
                    model: RaohaneDropShelf.items

                    delegate: Rectangle {
                        id: itemCard
                        required property string modelData

                        width: 108
                        height: 120
                        radius: 16
                        color: itemMouse.containsMouse ? "#24ffffff" : "#12ffffff"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        readonly property string entryPath: modelData
                        readonly property bool imageLike: /\.(png|jpe?g|webp|bmp|gif)$/i.test(entryPath)

                        Drag.active: itemMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.mimeData: ({ "text/uri-list": "file://" + entryPath })
                        Drag.supportedActions: Qt.CopyAction

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 78
                                radius: 12
                                color: RaohaneTheme.accentSoft
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: itemCard.imageLike ? "file://" + itemCard.entryPath : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: itemCard.imageLike && status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !itemCard.imageLike
                                    text: itemCard.entryPath.endsWith("/") ? "▣" : "◇"
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 25
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemCard.entryPath.split("/").pop()
                                color: RaohaneTheme.text
                                font.pixelSize: 9
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

                    Text {
                        anchors.centerIn: parent
                        visible: RaohaneDropShelf.items.length === 0
                        text: qsTr("Drop files here")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ShelfButton {
                        title: qsTr("Copy")
                        emphasized: true
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.copyAll()
                    }
                    ShelfButton {
                        title: qsTr("Clear")
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.clear()
                    }
                    ShelfButton {
                        title: qsTr("Close")
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
        property bool emphasized: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 19
        opacity: button.enabled ? 1 : 0.35
        color: emphasized ? RaohaneTheme.accentSoft
            : buttonMouse.containsMouse && button.enabled ? "#24ffffff" : "#12ffffff"
        border.width: 1
        border.color: emphasized ? RaohaneTheme.accent : RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: button.title
            color: emphasized ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: 10
            font.weight: Font.DemiBold
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
