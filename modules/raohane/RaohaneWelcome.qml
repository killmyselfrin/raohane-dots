import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    property bool stateDirectoryReady: false
    property bool completionKnown: false
    property bool completed: false

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function maybeShow(): void {
        if (!root.completionKnown || root.completed || RaohaneState.screenLocked)
            return
        Qt.callLater(() => RaohaneState.setPrimaryOpen("welcome", true))
    }

    function markCompleted(): void {
        root.completed = true
        root.completionKnown = true
        if (root.stateDirectoryReady)
            welcomeStateFile.setText("completed\n")
    }

    function finish(): void {
        root.markCompleted()
        RaohaneState.setPrimaryOpen("welcome", false)
    }

    function openSettings(page: string): void {
        root.markCompleted()
        RaohaneState.settingsPage = page
        RaohaneState.setPrimaryOpen("settings", true)
    }

    function openWallpaper(): void {
        root.markCompleted()
        RaohaneState.wallpaperSelectorTarget = "wallpaper"
        RaohaneState.setPrimaryOpen("wallpaper", true)
    }

    function resetWelcome(): void {
        root.completed = false
        root.completionKnown = true
        if (root.stateDirectoryReady)
            welcomeStateFile.setText("")
        RaohaneState.setPrimaryOpen("welcome", true)
    }

    Process {
        id: ensureStateDirectory
        command: ["mkdir", "-p", RaohanePaths.stateDirectory]

        onExited: (exitCode, exitStatus) => {
            root.stateDirectoryReady = exitCode === 0
            if (!root.stateDirectoryReady) {
                console.warn("[RaohaneWelcome] Could not prepare state directory")
                root.completionKnown = true
                root.completed = false
                root.maybeShow()
                return
            }
            welcomeStateFile.reload()
        }
    }

    FileView {
        id: welcomeStateFile
        path: RaohanePaths.welcomeStateFile

        onLoaded: {
            if (!root.stateDirectoryReady)
                return
            root.completed = welcomeStateFile.text().trim() === "completed"
            root.completionKnown = true
            root.maybeShow()
        }

        onLoadFailed: error => {
            if (!root.stateDirectoryReady)
                return
            if (error !== FileViewError.FileNotFound)
                console.warn("[RaohaneWelcome] Could not read welcome state:", error)
            root.completed = false
            root.completionKnown = true
            root.maybeShow()
        }
    }

    Connections {
        target: RaohaneState
        function onScreenLockedChanged(): void {
            if (!RaohaneState.screenLocked)
                root.maybeShow()
        }
    }

    Component.onCompleted: ensureStateDirectory.running = true

    PanelWindow {
        id: panelWindow

        property bool entered: false

        visible: RaohaneState.welcomeOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            panelWindow.entered = false
            if (visible) {
                Qt.callLater(() => {
                    panelWindow.entered = true
                    workspace.forceActiveFocus()
                })
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0, 0, 0, 0.54)
                : Qt.rgba(0.18, 0.17, 0.15, 0.22)
            opacity: panelWindow.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
            }
        }

        RaohaneSurface {
            id: workspace

            width: Math.min(parent.width - 48, 980)
            height: Math.min(parent.height - 48, 590)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            focus: panelWindow.visible
            opacity: panelWindow.entered ? 1 : 0
            scale: panelWindow.entered ? 1 : 0.992

            transform: Translate {
                y: panelWindow.entered ? 0 : 12
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
            }

            Rectangle {
                z: 3
                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: 22
                    leftMargin: 28
                }
                width: 62
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            RaohaneIconButton {
                z: 10
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 18
                    rightMargin: 18
                }
                buttonSize: 32
                iconSize: 16
                icon: "close"
                transparentIdle: true
                showSheen: false
                onClicked: root.finish()
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 30

                Item {
                    Layout.preferredWidth: Math.min(330, workspace.width * 0.36)
                    Layout.fillHeight: true

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 30
                        }
                        spacing: 14

                        Text {
                            text: qsTr("WELCOME TO")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2.1
                        }

                        Text {
                            text: "Raohane"
                            color: RaohaneTheme.text
                            font.pixelSize: 44
                            font.weight: Font.DemiBold
                            font.letterSpacing: -1.2
                        }

                        Text {
                            width: parent.width
                            text: qsTr("A quieter way to use Hyprland.")
                            color: RaohaneTheme.text
                            font.pixelSize: 21
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Your shell is ready. Start with the essentials, then refine every detail whenever you want.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 14
                            lineHeight: 1.35
                            wrapMode: Text.WordWrap
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            bottomMargin: 10
                        }
                        spacing: 10

                        Text {
                            text: qsTr("CURRENT MOOD")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                        }

                        RaohaneSurface {
                            width: parent.width
                            height: 62
                            surfaceRadius: RaohaneTheme.radiusSmall
                            showSheen: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: 12
                                    color: RaohaneTheme.accentSoft
                                    border.width: 1
                                    border.color: RaohaneTheme.accentBorder

                                    RaohaneIcon {
                                        anchors.centerIn: parent
                                        text: "spa"
                                        iconSize: 19
                                        color: RaohaneTheme.accent
                                        fill: 0.18
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: RaohaneTheme.presetName
                                        color: RaohaneTheme.text
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: qsTr("Theme Library is ready")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Hyprland  ·  Quickshell"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 24
                    Layout.bottomMargin: 10
                    color: RaohaneTheme.borderFaint
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 28
                    Layout.rightMargin: 8
                    spacing: 10

                    Text {
                        text: qsTr("Make it yours")
                        color: RaohaneTheme.text
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        text: qsTr("Three good places to begin. Nothing here is permanent.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        surfaceRadius: RaohaneTheme.radius
                        interactive: true
                        hovered: themePointer.containsMouse
                        pressed: themePointer.pressed
                        showSheen: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 14
                                color: RaohaneTheme.accentSoft
                                border.width: 1
                                border.color: RaohaneTheme.accentBorder

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: "palette"
                                    iconSize: 22
                                    color: RaohaneTheme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: qsTr("Theme & style")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Choose a mood, accent and glass density")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIcon {
                                text: "arrow_forward"
                                iconSize: 18
                                color: RaohaneTheme.textFaint
                            }
                        }

                        MouseArea {
                            id: themePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSettings("themes")
                        }
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        surfaceRadius: RaohaneTheme.radius
                        interactive: true
                        hovered: wallpaperPointer.containsMouse
                        pressed: wallpaperPointer.pressed
                        showSheen: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 14
                                color: RaohaneTheme.surfaceSubtle
                                border.width: 1
                                border.color: RaohaneTheme.border

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: "wallpaper"
                                    iconSize: 22
                                    color: RaohaneTheme.accentSecondary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: qsTr("Wallpaper")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Pick the image that sets the atmosphere")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIcon {
                                text: "arrow_forward"
                                iconSize: 18
                                color: RaohaneTheme.textFaint
                            }
                        }

                        MouseArea {
                            id: wallpaperPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openWallpaper()
                        }
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        surfaceRadius: RaohaneTheme.radius
                        interactive: true
                        hovered: profilePointer.containsMouse
                        pressed: profilePointer.pressed
                        showSheen: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 14
                                color: RaohaneTheme.surfaceSubtle
                                border.width: 1
                                border.color: RaohaneTheme.border

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: "account_circle"
                                    iconSize: 22
                                    color: RaohaneTheme.accentSecondary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: qsTr("Profile")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Add your display name and avatar")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIcon {
                                text: "arrow_forward"
                                iconSize: 18
                                color: RaohaneTheme.textFaint
                            }
                        }

                        MouseArea {
                            id: profilePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSettings("profile")
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("You can change everything later in Settings.")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 186
                            Layout.preferredHeight: 42
                            surfaceRadius: RaohaneTheme.radiusSmall
                            active: true
                            interactive: true
                            hovered: continuePointer.containsMouse
                            pressed: continuePointer.pressed
                            showSheen: false

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: qsTr("Start using Raohane")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                RaohaneIcon {
                                    text: "arrow_forward"
                                    iconSize: 16
                                    color: RaohaneTheme.accent
                                }
                            }

                            MouseArea {
                                id: continuePointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.finish()
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.finish()
                    event.accepted = true
                }
            }
        }
    }

    IpcHandler {
        target: "welcome"

        function open(): void { RaohaneState.setPrimaryOpen("welcome", true) }
        function close(): void { root.finish() }
        function reset(): void { root.resetWelcome() }
        function status(): string { return RaohaneState.welcomeOpen ? "open" : "closed" }
        function completed(): bool { return root.completed }
    }
}
