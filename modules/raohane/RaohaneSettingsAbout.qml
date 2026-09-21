pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.modules.raohane.services

Item {
    id: root

    property string version: "development"
    property bool copied: false

    readonly property bool compactLayout: width < 760
    readonly property string updateTitle: RaohaneUpdater.applying
        ? qsTr("Installing update…")
        : RaohaneUpdater.checking
            ? qsTr("Checking for updates…")
            : RaohaneUpdater.errorText.length > 0
                ? qsTr("Update check needs attention")
                : RaohaneUpdater.updateAvailable
                    ? qsTr("A new Raohane build is available")
                    : qsTr("Raohane is up to date")

    readonly property string updateDetail: RaohaneUpdater.applying
        ? qsTr("Raohane is validating the official archive, applying the runtime and will restart automatically when it is ready.")
        : RaohaneUpdater.errorText.length > 0
            ? RaohaneUpdater.errorText
            : RaohaneUpdater.updateAvailable
                ? qsTr("Update directly from the official main channel without opening a terminal or GitHub.")
                : qsTr("Updates are checked directly against the official Raohane repository.")

    readonly property string revisionSummary: {
        const current = RaohaneUpdater.currentShortRevision.length > 0 ? RaohaneUpdater.currentShortRevision : "—"
        const latest = RaohaneUpdater.latestShortRevision.length > 0 ? RaohaneUpdater.latestShortRevision : "—"
        const checked = RaohaneUpdater.lastCheckedText.length > 0
            ? qsTr(" · checked %1").arg(RaohaneUpdater.lastCheckedText)
            : ""
        return qsTr("%1 channel · current %2 · latest %3%4")
            .arg(RaohaneUpdater.channel)
            .arg(current)
            .arg(latest)
            .arg(checked)
    }

    readonly property color diagnosticColor: RaohaneDiagnostics.running
        ? RaohaneTheme.info
        : !RaohaneDiagnostics.hasResult
            ? RaohaneTheme.accent
            : RaohaneDiagnostics.lastOk ? RaohaneTheme.success : RaohaneTheme.critical

    readonly property string diagnosticTitle: RaohaneDiagnostics.running
        ? qsTr("Checking runtime health…")
        : !RaohaneDiagnostics.hasResult
            ? qsTr("Runtime health not checked")
            : RaohaneDiagnostics.lastOk
                ? qsTr("Runtime smoke passed")
                : qsTr("Runtime smoke needs attention")

    readonly property string diagnosticDetail: RaohaneDiagnostics.running
        ? qsTr("Checking live IPC and recent Quickshell/QML errors from the current Raohane session.")
        : !RaohaneDiagnostics.hasResult
            ? qsTr("Run the non-destructive smoke check to verify live IPC and recent runtime errors.")
            : RaohaneDiagnostics.lastOk
                ? qsTr("No high-signal QML or runtime failures were found in the current session.")
                : (RaohaneDiagnostics.errorText.length > 0
                    ? RaohaneDiagnostics.errorText
                    : qsTr("The current session reported a runtime problem. Copy the output for details."))

    readonly property string diagnosticSecondary: RaohaneDiagnostics.hasResult
        ? qsTr("Checked %1 · raohane validate smoke").arg(RaohaneDiagnostics.lastCheckedText || "—")
        : qsTr("This check does not lock the session, capture the screen or run destructive Phase 4 exercises.")

    function refresh(): void {
        RaohaneSystemInfo.refresh()
        versionFile.reload()
        RaohaneUpdater.checkNow(false)
    }

    function diagnosticsText(): string {
        const runtimeState = RaohaneDiagnostics.running
            ? "running"
            : !RaohaneDiagnostics.hasResult
                ? "not checked"
                : RaohaneDiagnostics.lastOk ? "pass" : "attention"
        const lines = [
            "Raohane " + root.version,
            RaohaneSystemInfo.distroName,
            "Kernel: " + RaohaneSystemInfo.kernelVersion,
            "CPU: " + RaohaneSystemInfo.cpu,
            "GPU: " + RaohaneSystemInfo.gpu,
            "Memory: " + RaohaneSystemInfo.memory,
            "Shell: " + RaohaneSystemInfo.shell,
            "Update channel: " + RaohaneUpdater.channel,
            "Revision: " + (RaohaneUpdater.currentRevision || "unknown"),
            "Session: Hyprland / Wayland",
            "Runtime smoke: " + runtimeState,
            "",
            "Diagnostic commands:",
            "raohane doctor all",
            "raohane validate smoke"
        ]
        if (RaohaneDiagnostics.lastOutput.length > 0)
            lines.push("", "Runtime smoke output:", RaohaneDiagnostics.lastOutput)
        return lines.join("\n")
    }

    function copyText(value: string): void {
        Quickshell.clipboardText = value
        root.copied = true
        copiedTimer.restart()
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
        id: aboutFlick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + RaohaneTheme.panelPadding * 3
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            anchors.right: parent.right
            anchors.rightMargin: RaohaneTheme.spacingTiny
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.42
            }
        }

        ColumnLayout {
            id: contentColumn

            width: Math.min(
                Math.max(0, parent.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 40)),
                960
            )
            anchors.top: parent.top
            anchors.topMargin: RaohaneTheme.spacingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                transparentIdle: true
                border.color: "transparent"
                showStateRail: false

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: RaohaneTheme.radiusSmall
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "dashboard_customize"
                            iconSize: 20
                            fill: 1
                            symbolWeight: 480
                            grade: 25
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingTiny

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.3
                        }

                        Text {
                            text: qsTr("A quiet, living desktop shell for Hyprland")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }

                        RowLayout {
                            Layout.topMargin: RaohaneTheme.spacingTiny
                            spacing: RaohaneTheme.spacingSmall

                            RaohaneSurface {
                                implicitWidth: versionText.implicitWidth + 18
                                implicitHeight: 24
                                surfaceRadius: RaohaneTheme.radiusSmall
                                raised: false
                                active: true
                                showSheen: false
                                border.color: RaohaneTheme.accentBorder

                                Text {
                                    id: versionText
                                    anchors.centerIn: parent
                                    text: qsTr("Version %1").arg(root.version)
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                text: qsTr("Hyprland · Quickshell")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 9
                                font.weight: Font.Medium
                            }
                        }
                    }

                    ActionButton {
                        icon: "refresh"
                        label: qsTr("Refresh")
                        enabled: !RaohaneUpdater.applying
                        onClicked: root.refresh()
                    }

                    ActionButton {
                        icon: root.copied ? "check" : "content_copy"
                        label: root.copied ? qsTr("Copied") : qsTr("Copy info")
                        emphasized: root.copied
                        onClicked: root.copyText(root.diagnosticsText())
                    }
                }
            }

            SectionLabel { text: qsTr("Updates") }

            InfoRail {
                icon: RaohaneUpdater.updateAvailable ? "system_update_alt" : "verified"
                title: root.updateTitle
                detail: root.updateDetail
                secondary: root.revisionSummary
                railColor: RaohaneUpdater.errorText.length > 0
                    ? RaohaneTheme.critical
                    : RaohaneUpdater.updateAvailable ? RaohaneTheme.warning : RaohaneTheme.accent

                ActionButton {
                    icon: "refresh"
                    label: qsTr("Check")
                    enabled: !RaohaneUpdater.checking && !RaohaneUpdater.applying
                    onClicked: RaohaneUpdater.checkNow(false)
                }

                ActionButton {
                    visible: RaohaneUpdater.updateAvailable || RaohaneUpdater.applying
                    icon: RaohaneUpdater.applying ? "progress_activity" : "download"
                    label: RaohaneUpdater.applying ? qsTr("Installing…") : qsTr("Update now")
                    emphasized: true
                    enabled: RaohaneUpdater.updateAvailable && !RaohaneUpdater.applying && !RaohaneUpdater.checking
                    onClicked: RaohaneUpdater.applyUpdate()
                }
            }

            InfoRail {
                icon: "autorenew"
                title: qsTr("Automatic updates")
                detail: qsTr("Check on startup and install a new main build automatically. Background checks during an active session never force a surprise restart.")
                secondary: qsTr("If a future build adds packages, Polkit may ask once for permission to install the missing official dependencies.")

                RaohaneSwitch {
                    checked: RaohaneUpdater.automaticUpdates
                    enabled: RaohaneUpdater.preferenceReady
                    onToggled: checked => RaohaneUpdater.setAutomaticUpdates(checked)
                }
            }

            SectionLabel { text: qsTr("Diagnostics") }

            InfoRail {
                icon: RaohaneDiagnostics.running ? "progress_activity"
                    : !RaohaneDiagnostics.hasResult ? "monitor_heart"
                    : RaohaneDiagnostics.lastOk ? "check_circle" : "error"
                title: root.diagnosticTitle
                detail: root.diagnosticDetail
                secondary: root.diagnosticSecondary
                railColor: root.diagnosticColor

                ActionButton {
                    icon: RaohaneDiagnostics.running ? "progress_activity" : "monitor_heart"
                    label: RaohaneDiagnostics.running ? qsTr("Checking…")
                        : RaohaneDiagnostics.hasResult ? qsTr("Check again") : qsTr("Run smoke check")
                    emphasized: !RaohaneDiagnostics.hasResult
                    enabled: !RaohaneDiagnostics.running
                    onClicked: RaohaneDiagnostics.runSmoke()
                }

                ActionButton {
                    visible: RaohaneDiagnostics.hasResult && RaohaneDiagnostics.lastOutput.length > 0
                    icon: root.copied ? "check" : "content_copy"
                    label: root.copied ? qsTr("Copied") : qsTr("Copy output")
                    onClicked: root.copyText(RaohaneDiagnostics.lastOutput)
                }
            }

            SectionLabel { text: qsTr("System") }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: systemList.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                border.color: RaohaneTheme.borderFaint
                clip: true

                Column {
                    id: systemList
                    width: parent.width
                    spacing: 0

                    SystemRow { width: parent.width; icon: "computer"; label: qsTr("Distribution"); value: RaohaneSystemInfo.distroName }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "terminal"; label: qsTr("Kernel"); value: RaohaneSystemInfo.kernelVersion }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "memory"; label: qsTr("CPU"); value: RaohaneSystemInfo.cpu }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "developer_board"; label: qsTr("GPU"); value: RaohaneSystemInfo.gpu }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "memory_alt"; label: qsTr("Memory"); value: RaohaneSystemInfo.memory }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "hard_drive"; label: qsTr("Disk"); value: RaohaneSystemInfo.disk }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "code"; label: qsTr("Shell"); value: RaohaneSystemInfo.shell }
                    RowDivider { width: parent.width }
                    SystemRow { width: parent.width; icon: "package_2"; label: qsTr("Packages"); value: RaohaneSystemInfo.packages }
                }
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
                detail: qsTr("Raohane owns its runtime, configuration, dependency graph and update path. No other desktop shell repository is required to install, run or update it.")
                secondary: qsTr("The updater follows the official Raohane main channel and validates the downloaded product payload before installation.")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacing

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
                    onClicked: root.copyText("raohane doctor all")
                }
            }
        }
    }

    component SectionLabel: Text {
        Layout.topMargin: RaohaneTheme.spacingTiny
        Layout.leftMargin: RaohaneTheme.spacingTiny
        color: RaohaneTheme.textFaint
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.1
    }

    component RowDivider: Rectangle {
        height: 1
        x: RaohaneTheme.panelPadding
        width: parent ? Math.max(0, parent.width - RaohaneTheme.panelPadding * 2) : 0
        color: RaohaneTheme.borderFaint
    }

    component SystemRow: Item {
        id: systemRow

        required property string icon
        required property string label
        required property string value

        height: 50

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacing

            RaohaneIcon {
                text: systemRow.icon
                iconSize: 16
                color: RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: systemRow.label
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.preferredWidth: Math.min(520, implicitWidth)
                text: systemRow.value.length > 0 ? systemRow.value : qsTr("Loading…")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    component InfoCard: RaohaneSurface {
        id: card

        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 62
        surfaceRadius: RaohaneTheme.radiusSmall
        raised: false
        showSheen: false
        idleColor: RaohaneTheme.surfaceSubtle
        border.color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                active: true
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: card.icon
                    iconSize: 17
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: card.label
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
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

    component InfoRail: RaohaneSurface {
        id: rail

        required property string icon
        required property string title
        required property string detail
        property string secondary: ""
        property color railColor: RaohaneTheme.accent
        default property alias actions: actionSlot.data

        Layout.fillWidth: true
        Layout.preferredHeight: secondary.length > 0 ? 82 : 70
        surfaceRadius: RaohaneTheme.radiusSmall
        raised: false
        showSheen: false
        showInnerRim: false
        transparentIdle: true
        border.color: "transparent"
        showStateRail: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacingLarge

            RaohaneSurface {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                active: true
                showSheen: false
                showInnerRim: false
                activeBorderColor: "transparent"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: rail.icon
                    iconSize: 19
                    fill: 0.72
                    color: rail.railColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingTiny

                Text {
                    text: rail.title
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: rail.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    lineHeight: 1.15
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: rail.secondary.length > 0
                    Layout.fillWidth: true
                    text: rail.secondary
                    color: rail.railColor
                    font.pixelSize: 8
                    lineHeight: 1.15
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                }
            }

            RowLayout {
                id: actionSlot
                spacing: RaohaneTheme.spacingSmall
            }
        }
    }

    component ActionButton: FocusScope {
        id: action

        required property string icon
        required property string label
        property bool emphasized: false
        signal clicked()

        implicitWidth: actionRow.implicitWidth + 24
        implicitHeight: 34
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro }
        }

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusSmall
            raised: false
            active: action.emphasized
            transparentIdle: !action.emphasized && !hovered
            hovered: actionMouse.containsMouse || action.activeFocus
            pressed: actionMouse.pressed
            interactive: true
            hoverScale: 1
            pressedScale: 1
            showSheen: false
            border.color: "transparent"

            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: RaohaneTheme.spacingSmall

                RaohaneIcon {
                    text: action.icon
                    iconSize: 14
                    fill: action.emphasized || actionMouse.containsMouse || action.activeFocus ? 1 : 0
                    color: action.emphasized || actionMouse.containsMouse || action.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted

                    Behavior on color {
                        ColorAnimation { duration: RaohaneMotion.micro }
                    }
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
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: action.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.clicked()
        }

        Keys.onPressed: event => {
            if (!action.enabled)
                return
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

        Layout.preferredHeight: 44
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusSmall
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
                spacing: RaohaneTheme.spacingSmall

                RaohaneIcon {
                    text: link.icon
                    iconSize: 15
                    fill: linkMouse.containsMouse || link.activeFocus ? 1 : 0
                    color: linkMouse.containsMouse || link.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted

                    Behavior on color {
                        ColorAnimation { duration: RaohaneMotion.micro }
                    }
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
