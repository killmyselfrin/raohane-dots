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
        contentHeight: contentColumn.implicitHeight + 30
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn

            width: Math.min(parent.width - 32, 900)
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 106
                surfaceRadius: 11
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 14
                    anchors.bottomMargin: 14
                    width: 2
                    radius: 1
                    color: RaohaneTheme.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 12

                    RaohaneIcon {
                        text: "dashboard_customize"
                        iconSize: 28
                        fill: 1
                        symbolWeight: 470
                        grade: 25
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2.2
                        }

                        Text {
                            text: qsTr("A quiet, living desktop shell for Hyprland")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }

                        RowLayout {
                            Layout.topMargin: 4
                            spacing: 6

                            RaohaneSurface {
                                implicitWidth: versionText.implicitWidth + 16
                                implicitHeight: 24
                                surfaceRadius: 7
                                raised: false
                                showSheen: false
                                border.color: RaohaneTheme.accentBorder

                                Text {
                                    id: versionText
                                    anchors.centerIn: parent
                                    text: qsTr("Version %1").arg(root.version)
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                text: qsTr("Hyprland · Quickshell")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }
                    }

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

            SectionLabel { text: qsTr("System") }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 720 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                InfoCard { icon: "computer"; label: qsTr("Distribution"); value: RaohaneSystemInfo.distroName }
                InfoCard { icon: "terminal"; label: qsTr("Kernel"); value: RaohaneSystemInfo.kernelVersion }
                InfoCard { icon: "memory"; label: qsTr("CPU"); value: RaohaneSystemInfo.cpu }
                InfoCard { icon: "developer_board"; label: qsTr("GPU"); value: RaohaneSystemInfo.gpu }
                InfoCard { icon: "memory_alt"; label: qsTr("Memory"); value: RaohaneSystemInfo.memory }
                InfoCard { icon: "hard_drive"; label: qsTr("Disk"); value: RaohaneSystemInfo.disk }
                InfoCard { icon: "code"; label: qsTr("Shell"); value: RaohaneSystemInfo.shell }
                InfoCard { icon: "package_2"; label: qsTr("Packages"); value: RaohaneSystemInfo.packages }
            }

            SectionLabel { text: qsTr("Introduction") }

            InfoRail {
                icon: "waving_hand"
                title: qsTr("Welcome to Raohane")
                detail: qsTr("Replay the animated welcome and guided interface tour from the beginning.")

                ActionButton {
                    icon: "replay"
                    label: qsTr("Show again")
                    emphasized: true
                    onClicked: RaohaneOnboardingState.reset()
                }
            }

            InfoRail {
                icon: "deployed_code"
                title: qsTr("Standalone architecture")
                detail: qsTr("Raohane owns its runtime, configuration and dependency graph. No other desktop shell repository is required to install, run or update it.")
                secondary: qsTr("Update an existing checkout with: git pull --ff-only && ./install-raohane.sh")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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
        }
    }

    component SectionLabel: Text {
        Layout.leftMargin: 2
        color: RaohaneTheme.textFaint
        font.pixelSize: 8
        font.weight: Font.DemiBold
        font.letterSpacing: 1.1
    }

    component InfoCard: RaohaneSurface {
        id: card

        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        surfaceRadius: 9
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 10
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 18
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.42
            }

            RaohaneIcon {
                text: card.icon
                iconSize: 15
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: card.label
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: card.value.length > 0 ? card.value : qsTr("Loading…")
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }

    component InfoRail: RaohaneSurface {
        id: rail

        required property string icon
        required property string title
        required property string detail
        property string secondary: ""
        default property alias actions: actionSlot.data

        Layout.fillWidth: true
        Layout.preferredHeight: secondary.length > 0 ? 84 : 68
        surfaceRadius: 10
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 28
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.68
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            RaohaneIcon {
                text: rail.icon
                iconSize: 18
                fill: 0.7
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: rail.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: rail.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: rail.secondary.length > 0
                    Layout.fillWidth: true
                    text: rail.secondary
                    color: RaohaneTheme.accent
                    font.pixelSize: 8
                    wrapMode: Text.Wrap
                }
            }

            RowLayout {
                id: actionSlot
                spacing: 6
            }
        }
    }

    component ActionButton: FocusScope {
        id: action

        required property string icon
        required property string label
        property bool emphasized: false
        signal clicked()

        implicitWidth: actionRow.implicitWidth + 20
        implicitHeight: 32
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 8
            raised: false
            active: action.emphasized
            transparentIdle: !action.emphasized
            hovered: actionMouse.containsMouse || action.activeFocus
            pressed: actionMouse.pressed
            interactive: true
            hoverScale: 1
            pressedScale: 1
            showSheen: false

            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: 5

                RaohaneIcon {
                    text: action.icon
                    iconSize: 13
                    fill: action.emphasized || actionMouse.containsMouse || action.activeFocus ? 1 : 0
                    color: action.emphasized || actionMouse.containsMouse || action.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: action.label
                    color: RaohaneTheme.text
                    font.pixelSize: 8
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

        Layout.preferredHeight: 40
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 9
            raised: false
            transparentIdle: true
            hovered: linkMouse.containsMouse || link.activeFocus
            pressed: linkMouse.pressed
            interactive: true
            hoverScale: 1
            pressedScale: 1
            showSheen: false
            border.color: linkMouse.containsMouse || link.activeFocus
                ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                anchors.centerIn: parent
                spacing: 7

                RaohaneIcon {
                    text: link.icon
                    iconSize: 14
                    fill: linkMouse.containsMouse || link.activeFocus ? 1 : 0
                    color: linkMouse.containsMouse || link.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: link.label
                    color: RaohaneTheme.text
                    font.pixelSize: 8
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
