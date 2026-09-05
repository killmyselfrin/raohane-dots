pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property string selectedRestorePath: ""

    function shortPath(path: string): string {
        const clean = RaohanePaths.cleanPath(path)
        if (clean.length <= 62)
            return clean
        return "…" + clean.substring(clean.length - 61)
    }

    FileDialog {
        id: exportDialog
        title: qsTr("Save Raohane backup")
        fileMode: FileDialog.SaveFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        defaultSuffix: "raohane-backup"
        nameFilters: [qsTr("Raohane backup (*.raohane-backup)"), qsTr("All files (*)")]
        onAccepted: RaohaneBackup.exportBackup(selectedFile)
    }

    FileDialog {
        id: restoreDialog
        title: qsTr("Choose Raohane backup")
        fileMode: FileDialog.OpenFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        nameFilters: [qsTr("Raohane backup (*.raohane-backup)"), qsTr("All files (*)")]
        onAccepted: root.selectedRestorePath = RaohanePaths.cleanPath(selectedFile)
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + 34
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ColumnLayout {
            id: pageColumn

            y: 14
            width: Math.min(parent.width - 32, 860)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: qsTr("Save the complete Raohane-owned setup as one portable file, then restore it after a reinstall or on another machine.")
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                lineHeight: 1.2
                wrapMode: Text.WordWrap
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                surfaceRadius: 10
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 30
                        radius: 1
                        color: RaohaneTheme.accent
                    }

                    RaohaneIcon {
                        text: "inventory_2"
                        iconSize: 19
                        fill: 0.7
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("What is included")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Wallpaper and lock wallpaper · theme and accent · keybinds · motion · bar and dock · monitor profiles · integrations · profile · notification/autostart/theme catalogs")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                ToolPanel {
                    id: exportPanel
                    Layout.fillWidth: true
                    icon: "archive"
                    title: qsTr("Create backup")
                    detail: qsTr("Current external wallpaper and avatar files are copied into the archive so the backup stays portable.")

                    ActionButton {
                        Layout.alignment: Qt.AlignLeft
                        icon: "save"
                        label: RaohaneBackup.busy && RaohaneBackup.operation === "export"
                            ? qsTr("Saving…")
                            : qsTr("Export backup")
                        emphasized: true
                        enabled: !RaohaneBackup.busy
                        onTriggered: exportDialog.open()
                    }
                }

                ToolPanel {
                    id: restorePanel
                    Layout.fillWidth: true
                    icon: "settings_backup_restore"
                    title: qsTr("Restore backup")
                    detail: qsTr("Choose a backup first. Nothing is replaced until you explicitly press Restore selected backup.")

                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 7

                        ActionButton {
                            icon: "folder_open"
                            label: qsTr("Choose backup")
                            emphasized: root.selectedRestorePath.length === 0
                            enabled: !RaohaneBackup.busy
                            onTriggered: restoreDialog.open()
                        }

                        ActionButton {
                            visible: root.selectedRestorePath.length > 0
                            icon: "restore"
                            label: RaohaneBackup.busy && RaohaneBackup.operation === "restore"
                                ? qsTr("Restoring…")
                                : qsTr("Restore selected")
                            emphasized: true
                            enabled: !RaohaneBackup.busy
                            onTriggered: RaohaneBackup.restoreBackup(root.selectedRestorePath)
                        }
                    }
                }
            }

            RaohaneSurface {
                visible: root.selectedRestorePath.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                surfaceRadius: 9
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 9
                    spacing: 9

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 20
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.62
                    }

                    RaohaneIcon {
                        text: "description"
                        iconSize: 16
                        color: RaohaneTheme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Selected backup")
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.shortPath(root.selectedRestorePath)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            elide: Text.ElideMiddle
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 28
                        iconSize: 13
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: root.selectedRestorePath = ""
                    }
                }
            }

            RaohaneSurface {
                visible: RaohaneBackup.statusMessage.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                surfaceRadius: 10
                raised: false
                showSheen: false
                border.color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 26
                        radius: 1
                        color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        opacity: RaohaneBackup.busy || RaohaneBackup.lastSucceeded ? 1 : 0.5
                    }

                    RaohaneIcon {
                        text: RaohaneBackup.busy
                            ? "progress_activity"
                            : RaohaneBackup.lastSucceeded ? "check_circle" : "error"
                        iconSize: 18
                        fill: RaohaneBackup.lastSucceeded ? 1 : 0
                        color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accent : RaohaneTheme.textMuted

                        RotationAnimation on rotation {
                            running: RaohaneBackup.busy
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.statusMessage
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.detailMessage
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        visible: RaohaneBackup.lastSucceeded && RaohaneBackup.operation === "restore"
                        icon: "restart_alt"
                        label: qsTr("Restart Raohane")
                        emphasized: true
                        onTriggered: RaohaneBackup.restartShell()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Before every restore, Raohane automatically stores your current configuration in ~/.local/state/raohane/restore-points.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }
    }

    component ToolPanel: RaohaneSurface {
        id: toolPanel

        required property string icon
        required property string title
        required property string detail
        default property alias body: bodyColumn.data

        Layout.preferredHeight: 154
        surfaceRadius: 11
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 13
            anchors.bottomMargin: 13
            width: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.72
        }

        ColumnLayout {
            id: bodyColumn
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 13
            anchors.topMargin: 13
            anchors.bottomMargin: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RaohaneIcon {
                    text: toolPanel.icon
                    iconSize: 18
                    fill: 0.45
                    color: RaohaneTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: toolPanel.title
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: toolPanel.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                lineHeight: 1.15
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }
        }
    }

    component ActionButton: RaohaneSurface {
        id: actionButton

        required property string icon
        required property string label
        property bool emphasized: false
        signal triggered()

        implicitWidth: actionRow.implicitWidth + 20
        implicitHeight: 32
        surfaceRadius: 8
        active: emphasized
        transparentIdle: !emphasized
        raised: false
        showSheen: false
        interactive: enabled
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        opacity: enabled ? 1 : 0.48

        RowLayout {
            id: actionRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: actionButton.icon
                iconSize: 13
                fill: actionButton.emphasized ? 1 : 0
                color: actionButton.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: actionButton.label
                color: actionButton.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: actionButton.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: actionButton.triggered()
        }
    }
}
