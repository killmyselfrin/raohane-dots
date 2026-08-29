pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.modules.raohane.services

Item {
    id: root

    property string version: "development"
    property bool copied: false

    function refresh(): void {
        RaohaneSystemInfo.refresh()
        versionFile.reload()
    }

    function diagnosticsText(): string {
        return [
            "Raohane " + root.version,
            RaohaneSystemInfo.distroName,
            "Kernel: " + RaohaneSystemInfo.kernelVersion,
            "CPU: " + RaohaneSystemInfo.cpu,
            "GPU: " + RaohaneSystemInfo.gpu,
            "Memory: " + RaohaneSystemInfo.memory,
            "Shell: " + RaohaneSystemInfo.shell,
            "Session: Hyprland / Wayland",
            "",
            "Diagnostic command:",
            "raohane doctor all"
        ].join("\n")
    }

    Component.onCompleted: root.refresh()

    FileView {
        id: versionFile
        path: Quickshell.shellPath("VERSION")

        onLoaded: {
            const value = versionFile.text().trim()
            root.version = value.length > 0 ? value : "development"
        }
    }

    Timer {
        id: copiedTimer
        interval: 1400
        repeat: false
        onTriggered: root.copied = false
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 34
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 154
                radius: 24
                color: "#79191523"
                border.width: 1
                border.color: RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    Rectangle {
                        width: 82
                        height: 82
                        radius: 27
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: "ラ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 34
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: "Raohane"
                            color: RaohaneTheme.text
                            font.pixelSize: 27
                            font.weight: Font.Bold
                        }

                        Text {
                            text: qsTr("A living desktop shell for Hyprland")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.topMargin: 5
                            width: versionText.implicitWidth + 18
                            height: 27
                            radius: 14
                            color: "#20ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                id: versionText
                                anchors.centerIn: parent
                                text: qsTr("Version %1").arg(root.version)
                                color: RaohaneTheme.accent
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 8

                        ActionButton {
                            icon: "refresh"
                            label: qsTr("Refresh")
                            onClicked: root.refresh()
                        }

                        ActionButton {
                            icon: root.copied ? "check" : "content_copy"
                            label: root.copied ? qsTr("Copied") : qsTr("Diagnostics")
                            onClicked: {
                                Quickshell.clipboardText = root.diagnosticsText()
                                root.copied = true
                                copiedTimer.restart()
                            }
                        }
                    }
                }
            }

            Text {
                text: qsTr("System")
                color: RaohaneTheme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.leftMargin: 3
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 720 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10

                InfoCard { icon: "computer"; label: qsTr("Distribution"); value: RaohaneSystemInfo.distroName }
                InfoCard { icon: "terminal"; label: qsTr("Kernel"); value: RaohaneSystemInfo.kernelVersion }
                InfoCard { icon: "memory"; label: qsTr("CPU"); value: RaohaneSystemInfo.cpu }
                InfoCard { icon: "developer_board"; label: qsTr("GPU"); value: RaohaneSystemInfo.gpu }
                InfoCard { icon: "memory_alt"; label: qsTr("Memory"); value: RaohaneSystemInfo.memory }
                InfoCard { icon: "hard_drive"; label: qsTr("Disk"); value: RaohaneSystemInfo.disk }
                InfoCard { icon: "code"; label: qsTr("Shell"); value: RaohaneSystemInfo.shell }
                InfoCard { icon: "package_2"; label: qsTr("Packages"); value: RaohaneSystemInfo.packages }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                radius: 20
                color: "#61171320"
                border.width: 1
                border.color: RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 14

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 15
                        color: RaohaneTheme.accentSoft

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "deployed_code"
                            iconSize: 23
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: qsTr("Standalone architecture")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Raohane owns its runtime, configuration and dependency graph. No other desktop shell repository is required to install, run or update it.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Update an existing checkout with: git pull --ff-only && ./install-raohane.sh")
                            color: RaohaneTheme.accent
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                LinkButton {
                    Layout.fillWidth: true
                    icon: "code"
                    label: qsTr("Raohane repository")
                    onClicked: Qt.openUrlExternally("https://github.com/killmyselfrin/raohane-dots")
                }

                LinkButton {
                    Layout.fillWidth: true
                    icon: "monitor_heart"
                    label: qsTr("Copy doctor command")
                    onClicked: {
                        Quickshell.clipboardText = "raohane doctor all"
                        root.copied = true
                        copiedTimer.restart()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                horizontalAlignment: Text.AlignHCenter
                text: "RAOHANE / HYPRLAND / QUICKSHELL"
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                font.letterSpacing: 1.0
                font.weight: Font.DemiBold
            }
        }
    }

    component InfoCard: Rectangle {
        id: card
        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 72
        radius: 17
        color: "#5c17141f"
        border.width: 1
        border.color: RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: 13
                color: "#1cffffff"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: card.icon
                    iconSize: 18
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                Text {
                    text: card.label
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }

                Text {
                    Layout.fillWidth: true
                    text: card.value.length > 0 ? card.value : qsTr("Loading…")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: action
        required property string icon
        required property string label
        signal clicked()

        width: 118
        height: 38
        radius: 13
        color: actionMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
        border.width: 1
        border.color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: action.icon
                iconSize: 15
                color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: action.label
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component LinkButton: Rectangle {
        id: link
        required property string icon
        required property string label
        signal clicked()

        Layout.preferredHeight: 48
        radius: 15
        color: linkMouse.containsMouse ? RaohaneTheme.accentSoft : "#4c17141f"
        border.width: 1
        border.color: linkMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            RaohaneIcon {
                text: link.icon
                iconSize: 17
                color: linkMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: link.label
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: linkMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }
}
