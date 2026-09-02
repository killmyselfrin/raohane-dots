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
        contentHeight: pageColumn.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ColumnLayout {
            id: pageColumn
            x: 12
            y: 18
            width: parent.width - 24
            spacing: 14

            Text {
                Layout.fillWidth: true
                text: qsTr("Save the complete Raohane-owned setup as one portable file, then restore it after a reinstall or on another machine.")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                lineHeight: 1.25
                wrapMode: Text.WordWrap
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 104
                surfaceRadius: 16
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RaohaneSurface {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        surfaceRadius: 16
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "inventory_2"
                            iconSize: 25
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("What is included")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Wallpaper and lock wallpaper · theme and accent · keybinds · motion · bar and dock · monitor profiles · integrations · profile · notification/autostart/theme catalogs")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.2
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RaohaneSurface {
                    id: exportCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 196
                    surfaceRadius: 18
                    raised: false
                    showSheen: false
                    border.color: exportMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        RaohaneIcon {
                            text: "archive"
                            iconSize: 25
                            fill: 0.6
                            color: RaohaneTheme.accent
                        }

                        Text {
                            text: qsTr("Create backup")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Current external wallpaper and avatar files are copied into the archive so the backup stays portable.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.2
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }

                        RaohaneSurface {
                            Layout.preferredWidth: 138
                            Layout.preferredHeight: 34
                            surfaceRadius: 11
                            active: true
                            showSheen: false
                            opacity: RaohaneBackup.busy ? 0.5 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 7
                                RaohaneIcon { text: "save"; iconSize: 14; color: RaohaneTheme.accent }
                                Text {
                                    text: RaohaneBackup.busy && RaohaneBackup.operation === "export"
                                        ? qsTr("Saving…")
                                        : qsTr("Export backup")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: exportMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !RaohaneBackup.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exportDialog.open()
                    }
                }

                RaohaneSurface {
                    id: restoreCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 196
                    surfaceRadius: 18
                    raised: false
                    showSheen: false
                    border.color: restoreMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        RaohaneIcon {
                            text: "settings_backup_restore"
                            iconSize: 25
                            fill: 0.55
                            color: RaohaneTheme.accent
                        }

                        Text {
                            text: qsTr("Restore backup")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Choose a backup first. Nothing is replaced until you explicitly press Restore selected backup.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.2
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            spacing: 8

                            RaohaneSurface {
                                Layout.preferredWidth: 126
                                Layout.preferredHeight: 34
                                surfaceRadius: 11
                                active: root.selectedRestorePath.length === 0
                                showSheen: false
                                opacity: RaohaneBackup.busy ? 0.5 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    RaohaneIcon { text: "folder_open"; iconSize: 14; color: RaohaneTheme.accent }
                                    Text {
                                        text: qsTr("Choose backup")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !RaohaneBackup.busy
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: restoreDialog.open()
                                }
                            }

                            RaohaneSurface {
                                visible: root.selectedRestorePath.length > 0
                                Layout.preferredWidth: 154
                                Layout.preferredHeight: 34
                                surfaceRadius: 11
                                active: true
                                showSheen: false
                                opacity: RaohaneBackup.busy ? 0.5 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    RaohaneIcon { text: "restore"; iconSize: 14; color: RaohaneTheme.accent }
                                    Text {
                                        text: RaohaneBackup.busy && RaohaneBackup.operation === "restore"
                                            ? qsTr("Restoring…")
                                            : qsTr("Restore selected")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !RaohaneBackup.busy
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: RaohaneBackup.restoreBackup(root.selectedRestorePath)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: restoreMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }
                }
            }

            RaohaneSurface {
                visible: root.selectedRestorePath.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                surfaceRadius: 14
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10

                    RaohaneIcon {
                        text: "description"
                        iconSize: 18
                        color: RaohaneTheme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
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
                            font.pixelSize: 8
                            elide: Text.ElideMiddle
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 30
                        iconSize: 14
                        icon: "close"
                        transparentIdle: true
                        onClicked: root.selectedRestorePath = ""
                    }
                }
            }

            RaohaneSurface {
                visible: RaohaneBackup.statusMessage.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                surfaceRadius: 15
                raised: false
                showSheen: false
                border.color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 11

                    RaohaneIcon {
                        text: RaohaneBackup.busy
                            ? "progress_activity"
                            : RaohaneBackup.lastSucceeded ? "check_circle" : "error"
                        iconSize: 20
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
                        spacing: 3
                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.statusMessage
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.detailMessage
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }

                    RaohaneSurface {
                        visible: RaohaneBackup.lastSucceeded && RaohaneBackup.operation === "restore"
                        Layout.preferredWidth: 122
                        Layout.preferredHeight: 34
                        surfaceRadius: 11
                        active: true
                        showSheen: false

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 7
                            RaohaneIcon { text: "restart_alt"; iconSize: 14; color: RaohaneTheme.accent }
                            Text {
                                text: qsTr("Restart Raohane")
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneBackup.restartShell()
                        }
                    }
                }
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
}
