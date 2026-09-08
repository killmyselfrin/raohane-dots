pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs.modules.raohane.services

Item {
    id: root

    property bool copied: false

    readonly property color statusColor: RaohaneGraphics.updating
        ? RaohaneTheme.info
        : RaohaneGraphics.updateAvailable
            ? RaohaneTheme.warning
            : RaohaneGraphics.status === "current"
                ? RaohaneTheme.success
                : RaohaneGraphics.status === "error"
                    ? RaohaneTheme.critical
                    : RaohaneTheme.info

    readonly property string statusIcon: RaohaneGraphics.checking || RaohaneGraphics.updating
        ? "progress_activity"
        : RaohaneGraphics.updateAvailable
            ? "system_update_alt"
            : RaohaneGraphics.status === "current"
                ? "verified"
                : RaohaneGraphics.status === "error"
                    ? "error"
                    : "info"

    readonly property string statusTitle: RaohaneGraphics.updating
        ? qsTr("Updating graphics stack…")
        : RaohaneGraphics.checking
            ? qsTr("Checking graphics stack…")
            : RaohaneGraphics.updateAvailable
                ? qsTr("Graphics updates are available")
                : RaohaneGraphics.status === "current"
                    ? qsTr("Graphics stack is up to date")
                    : RaohaneGraphics.status === "unverified"
                        ? qsTr("Some graphics packages need manual verification")
                        : RaohaneGraphics.status === "unsupported"
                            ? qsTr("Automatic package checks are not available here")
                            : RaohaneGraphics.status === "error"
                                ? qsTr("Graphics check needs attention")
                                : qsTr("Graphics status is not verified yet")

    readonly property string statusDetail: RaohaneGraphics.updating
        ? qsTr("Raohane is running the normal full system upgrade through Polkit. Keep the computer powered on until it finishes.")
        : RaohaneGraphics.checking
            ? qsTr("Raohane is detecting active GPUs, kernel drivers and installed graphics packages.")
            : RaohaneGraphics.errorText.length > 0
                ? RaohaneGraphics.errorText
                : RaohaneGraphics.updateAvailable
                    ? qsTr("Only packages that already belong to your active graphics stack are reported. Raohane will never switch driver families automatically.")
                    : RaohaneGraphics.status === "current"
                        ? qsTr("A fresh repository check found no pending updates for the installed graphics packages.")
                        : RaohaneGraphics.notes.length > 0
                            ? RaohaneGraphics.notes
                            : qsTr("Run a check to inspect the hardware and driver stack used by this session.")

    readonly property string checkSourceLabel: RaohaneGraphics.checkSource === "checkupdates"
        ? qsTr("Fresh Arch repository metadata")
        : RaohaneGraphics.checkSource === "pacman-local-db"
            ? qsTr("Local pacman sync database")
            : RaohaneGraphics.checkSource === "unsupported"
                ? qsTr("Hardware detection only")
                : qsTr("Not checked")

    readonly property color updateResultColor: RaohaneGraphics.updateStatus === "success"
        ? RaohaneTheme.success
        : RaohaneGraphics.updateStatus === "error"
            ? RaohaneTheme.critical
            : RaohaneGraphics.updateStatus === "cancelled"
                ? RaohaneTheme.warning
                : RaohaneTheme.info

    readonly property string updateResultIcon: RaohaneGraphics.updateStatus === "success"
        ? "check_circle"
        : RaohaneGraphics.updateStatus === "error"
            ? "error"
            : RaohaneGraphics.updateStatus === "cancelled"
                ? "cancel"
                : "progress_activity"

    readonly property string updateResultText: RaohaneGraphics.updateStatus === "running"
        ? qsTr("Installing system and graphics updates…")
        : RaohaneGraphics.updateStatus === "success"
            ? qsTr("Graphics update completed. Restart the computer if the kernel or GPU driver was updated.")
            : RaohaneGraphics.updateStatus === "cancelled"
                ? (RaohaneGraphics.updateErrorText.length > 0
                    ? RaohaneGraphics.updateErrorText
                    : qsTr("Driver update was cancelled."))
                : RaohaneGraphics.updateStatus === "error"
                    ? (RaohaneGraphics.updateErrorText.length > 0
                        ? RaohaneGraphics.updateErrorText
                        : qsTr("Driver update failed."))
                    : ""

    function refresh(force = false): void {
        RaohaneGraphics.checkNow(force)
    }

    Component.onCompleted: root.refresh(false)

    Timer {
        id: copiedTimer
        interval: 1400
        repeat: false
        onTriggered: root.copied = false
    }

    Flickable {
        id: graphicsFlick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 36
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.42
            }
        }

        ColumnLayout {
            id: contentColumn

            width: Math.min(parent.width - 40, 920)
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 126
                surfaceRadius: 14
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    width: 3
                    radius: 2
                    color: root.statusColor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 14

                    RaohaneSurface {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        surfaceRadius: 14
                        raised: false
                        active: true
                        showSheen: false
                        border.color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.45)

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.statusIcon
                            iconSize: 25
                            fill: 1
                            symbolWeight: 480
                            grade: 25
                            color: root.statusColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: root.statusTitle
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusDetail
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            lineHeight: 1.16
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        icon: "refresh"
                        label: RaohaneGraphics.checking ? qsTr("Checking…") : qsTr("Check again")
                        enabled: !RaohaneGraphics.checking && !RaohaneGraphics.updating
                        onClicked: root.refresh(true)
                    }
                }
            }

            SectionLabel { text: qsTr("Detected hardware") }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 760 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10

                InfoCard {
                    icon: "developer_board"
                    label: qsTr("GPU")
                    value: RaohaneGraphics.gpuSummary.length > 0 ? RaohaneGraphics.gpuSummary : qsTr("Detecting…")
                }

                InfoCard {
                    icon: "memory"
                    label: qsTr("Active driver")
                    value: RaohaneGraphics.driverSummary.length > 0 ? RaohaneGraphics.driverSummary : qsTr("Detecting…")
                }

                InfoCard {
                    icon: "database"
                    label: qsTr("Update source")
                    value: root.checkSourceLabel
                }

                InfoCard {
                    icon: "package_2"
                    label: qsTr("Pending graphics packages")
                    value: RaohaneGraphics.checking ? qsTr("Checking…") : String(RaohaneGraphics.updateCount)
                }
            }

            SectionLabel { text: qsTr("Update policy") }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: updateColumn.implicitHeight + 32
                surfaceRadius: 14
                raised: false
                showSheen: false
                border.color: RaohaneGraphics.updateAvailable ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                ColumnLayout {
                    id: updateColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        RaohaneSurface {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            surfaceRadius: 12
                            raised: false
                            active: RaohaneGraphics.updateAvailable
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: RaohaneGraphics.updateAvailable ? "system_update_alt" : "shield"
                                iconSize: 22
                                fill: RaohaneGraphics.updateAvailable ? 1 : 0
                                color: RaohaneGraphics.updateAvailable ? RaohaneTheme.warning : RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: RaohaneGraphics.updateAvailable
                                    ? qsTr("Update drivers safely")
                                    : qsTr("Driver families stay under your control")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneGraphics.updateAvailable
                                    ? qsTr("Arch-family systems require a full system upgrade. Raohane will update the installed graphics stack through Polkit without switching to another driver family.")
                                    : qsTr("Raohane detects NVIDIA, nouveau, AMD and Intel stacks, but never converts one driver family into another.")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                lineHeight: 1.16
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            spacing: 8

                            ActionButton {
                                visible: RaohaneGraphics.updateAvailable
                                icon: RaohaneGraphics.updating ? "progress_activity" : "system_update_alt"
                                label: RaohaneGraphics.updating ? qsTr("Updating…") : qsTr("Update drivers")
                                emphasized: true
                                enabled: RaohaneGraphics.canUpdate
                                onClicked: RaohaneGraphics.updateNow()
                            }

                            ActionButton {
                                visible: RaohaneGraphics.updateAvailable && RaohaneGraphics.updateCommand.length > 0
                                icon: root.copied ? "check" : "content_copy"
                                label: root.copied ? qsTr("Copied") : qsTr("Copy command")
                                enabled: !RaohaneGraphics.updating
                                onClicked: {
                                    Quickshell.clipboardText = RaohaneGraphics.updateCommand
                                    root.copied = true
                                    copiedTimer.restart()
                                }
                            }
                        }
                    }

                    Text {
                        visible: RaohaneGraphics.updateAvailable && RaohaneGraphics.packageSummary.length > 0
                        Layout.fillWidth: true
                        text: RaohaneGraphics.packageSummary
                        color: RaohaneTheme.warning
                        font.pixelSize: 9
                        font.family: "monospace"
                        wrapMode: Text.WordWrap
                    }

                    RaohaneSurface {
                        visible: RaohaneGraphics.updateStatus !== "idle"
                        Layout.fillWidth: true
                        Layout.preferredHeight: updateStateRow.implicitHeight + 22
                        surfaceRadius: 10
                        raised: false
                        showSheen: false
                        border.color: root.updateResultColor

                        RowLayout {
                            id: updateStateRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 9

                            RaohaneIcon {
                                text: root.updateResultIcon
                                iconSize: 17
                                color: root.updateResultColor
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.updateResultText
                                color: root.updateResultColor
                                font.pixelSize: 9
                                lineHeight: 1.15
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    RaohaneSurface {
                        visible: RaohaneGraphics.updateAvailable && RaohaneGraphics.updateCommand.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        surfaceRadius: 10
                        raised: false
                        showSheen: false
                        border.color: RaohaneTheme.borderFaint

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: RaohaneGraphics.updateCommand
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            RaohaneSurface {
                visible: RaohaneGraphics.notes.length > 0 && !RaohaneGraphics.updateAvailable
                Layout.fillWidth: true
                Layout.preferredHeight: noteText.implicitHeight + 28
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Text {
                    id: noteText
                    anchors.fill: parent
                    anchors.margins: 14
                    text: RaohaneGraphics.notes
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    lineHeight: 1.16
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    component SectionLabel: Text {
        Layout.topMargin: 6
        Layout.leftMargin: 3
        text: ""
        color: RaohaneTheme.textFaint
        font.pixelSize: 9
        font.weight: Font.DemiBold
        font.letterSpacing: 1.0
    }

    component InfoCard: RaohaneSurface {
        id: infoCard

        property string icon: "info"
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 82
        surfaceRadius: 12
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 11

            RaohaneSurface {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                surfaceRadius: 11
                raised: false
                active: true
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: infoCard.icon
                    iconSize: 19
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: infoCard.label
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: infoCard.value
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: button

        property string icon: ""
        property string label: ""
        property bool emphasized: false
        signal clicked()

        implicitWidth: buttonRow.implicitWidth + 22
        implicitHeight: 36
        radius: 10
        color: emphasized
            ? RaohaneTheme.accentSoft
            : actionMouse.containsMouse
                ? RaohaneTheme.surfaceHover
                : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: emphasized ? RaohaneTheme.accentBorder
            : actionMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
        opacity: enabled ? 1 : 0.45

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 7

            RaohaneIcon {
                text: button.icon
                iconSize: 15
                color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: button.label
                color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.clicked()
        }
    }
}
