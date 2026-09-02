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

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 154
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: true
                showSheen: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    RaohaneSurface {
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 82
                        surfaceRadius: 27
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "dashboard_customize"
                            iconSize: 35
                            fill: 1
                            symbolWeight: 470
                            grade: 25
                            color: RaohaneTheme.accent
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
                            text: qsTr("A quiet, living desktop shell for Hyprland")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                        }

                        RaohaneSurface {
                            Layout.topMargin: 5
                            Layout.preferredWidth: versionText.implicitWidth + 18
                            Layout.preferredHeight: 27
                            surfaceRadius: 14
                            raised: false
                            showSheen: false

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
                            emphasized: root.copied
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

            Text {
                text: qsTr("Introduction")
                color: RaohaneTheme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.leftMargin: 3
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                surfaceRadius: 18
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 13

                    RaohaneSurface {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        surfaceRadius: 15
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "waving_hand"
                            iconSize: 22
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: qsTr("Welcome to Raohane")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Replay the animated welcome and guided interface tour from the beginning.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }

                    ActionButton {
                        icon: "replay"
                        label: qsTr("Show again")
                        emphasized: true
                        onClicked: RaohaneOnboardingState.reset()
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                surfaceRadius: 20
                raised: false
                showSheen: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 14

                    RaohaneSurface {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        surfaceRadius: 15
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "deployed_code"
                            iconSize: 23
                            fill: 1
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

            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
                spacing: 7

                RaohaneIcon {
                    text: "desktop_windows"
                    iconSize: 12
                    color: RaohaneTheme.textFaint
                }

                Text {
                    text: qsTr("Hyprland · Quickshell")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.weight: Font.Medium
                }
            }
        }
    }

    component InfoCard: RaohaneSurface {
        id: card

        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 72
        surfaceRadius: 17
        raised: false
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RaohaneSurface {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                surfaceRadius: 13
                raised: false
                showSheen: false

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

    component ActionButton: FocusScope {
        id: action

        required property string icon
        required property string label
        property bool emphasized: false
        signal clicked()

        implicitWidth: 118
        implicitHeight: 38
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 13
            raised: false
            active: action.emphasized
            hovered: actionMouse.containsMouse || action.activeFocus
            pressed: actionMouse.pressed
            interactive: true
            hoverScale: RaohaneMotion.subtleHoverScale
            pressedScale: RaohaneMotion.softPressScale
            showSheen: false

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                RaohaneIcon {
                    text: action.icon
                    iconSize: 15
                    fill: action.emphasized || actionMouse.containsMouse || action.activeFocus ? 1 : 0
                    color: action.emphasized || actionMouse.containsMouse || action.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: action.label
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.clicked()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                action.clicked()
                event.accepted = true
            }
        }
    }

    component LinkButton: FocusScope {
        id: link

        required property string icon
        required property string label
        signal clicked()

        Layout.preferredHeight: 48
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 15
            raised: false
            hovered: linkMouse.containsMouse || link.activeFocus
            pressed: linkMouse.pressed
            interactive: true
            hoverScale: RaohaneMotion.subtleHoverScale
            pressedScale: RaohaneMotion.softPressScale
            showSheen: false

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                RaohaneIcon {
                    text: link.icon
                    iconSize: 17
                    fill: linkMouse.containsMouse || link.activeFocus ? 1 : 0
                    color: linkMouse.containsMouse || link.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: link.label
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: linkMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: link.forceActiveFocus()
            onClicked: link.clicked()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                link.clicked()
                event.accepted = true
            }
        }
    }
}
