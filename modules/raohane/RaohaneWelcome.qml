pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    property int page: 0
    readonly property int pageCount: 4
    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var suggestedThemes: RaohaneTheme.presets.slice(0, 12)

    function open(): void {
        root.page = 0
        RaohaneState.setPrimaryOpen("welcome", true)
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("welcome", false)
    }

    function finish(): void {
        RaohaneConfig.welcomeCompleted = true
        RaohaneConfig.saveNow()
        root.close()
    }

    function maybeOpen(): void {
        if (RaohaneConfig.ready && !RaohaneConfig.welcomeCompleted && !RaohaneState.screenLocked)
            root.open()
    }

    Component.onCompleted: Qt.callLater(root.maybeOpen)

    Connections {
        target: RaohaneConfig
        function onReadyChanged(): void { Qt.callLater(root.maybeOpen) }
    }

    Connections {
        target: RaohaneState
        function onScreenLockedChanged(): void {
            if (!RaohaneState.screenLocked)
                Qt.callLater(root.maybeOpen)
        }
    }

    PanelWindow {
        id: welcomeWindow

        visible: RaohaneState.welcomeOpen
        screen: root.focusedScreen
        color: RaohaneTheme.background
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                root.page = 0
                welcomeCard.entered = false
                Qt.callLater(() => {
                    welcomeCard.entered = true
                    welcomeCard.forceActiveFocus()
                })
            } else {
                welcomeCard.entered = false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.background

            Rectangle {
                width: parent.width * 0.52
                height: width
                radius: width / 2
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: -width * 0.22
                    topMargin: -height * 0.42
                }
                color: RaohaneTheme.accentSoft
                opacity: 0.48
            }
        }

        ColumnLayout {
            id: welcomeCard
            property bool entered: false

            width: Math.min(parent.width - 96, 920)
            height: Math.min(parent.height - 96, 680)
            anchors.centerIn: parent
            spacing: 16
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.99
            focus: visible

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeStandard } }
            Behavior on scale { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RaohaneSurface {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    surfaceRadius: 14
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "spa"
                        iconSize: 22
                        fill: 1
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: qsTr("Welcome setup")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }
                }

                Repeater {
                    model: root.pageCount

                    Rectangle {
                        required property int index
                        width: index === root.page ? 26 : 7
                        height: 7
                        radius: 4
                        color: index <= root.page ? RaohaneTheme.accent : RaohaneTheme.borderStrong

                        Behavior on width { NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized } }
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.fillHeight: true
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.page === 0 ? introPage
                        : root.page === 1 ? themePage
                        : root.page === 2 ? shellPage
                        : readyPage
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Text {
                    text: qsTr("Step %1 of %2").arg(root.page + 1).arg(root.pageCount)
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                }

                Item { Layout.fillWidth: true }

                WelcomeAction {
                    visible: root.page > 0
                    icon: "arrow_back"
                    label: qsTr("Back")
                    onTriggered: root.page = Math.max(0, root.page - 1)
                }

                WelcomeAction {
                    icon: root.page === root.pageCount - 1 ? "done" : "arrow_forward"
                    label: root.page === root.pageCount - 1 ? qsTr("Enter Raohane") : qsTr("Continue")
                    selected: true
                    onTriggered: {
                        if (root.page === root.pageCount - 1)
                            root.finish()
                        else
                            root.page += 1
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.page === root.pageCount - 1)
                        root.finish()
                    else
                        root.page += 1
                    event.accepted = true
                } else if (event.key === Qt.Key_Left && root.page > 0) {
                    root.page -= 1
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape && RaohaneConfig.welcomeCompleted) {
                    root.close()
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "welcome"
            function open(): void { root.open() }
            function close(): void { root.close() }
            function reset(): void {
                RaohaneConfig.welcomeCompleted = false
                root.open()
            }
            function status(): string { return RaohaneConfig.welcomeCompleted ? "completed" : "pending" }
        }
    }

    Component {
        id: introPage

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 34

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("A calmer desktop,\nmade yours.")
                        color: RaohaneTheme.text
                        font.pixelSize: 32
                        font.weight: Font.Light
                        lineHeight: 1.08
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Choose a mood, arrange the shell and place native widgets. Every choice is saved live in Raohane's own configuration.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 11
                        lineHeight: 1.35
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "静けさの中で動く"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                        font.letterSpacing: 1
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 330
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 9

                    FeatureRow { icon: "palette"; title: qsTr("Themes"); detail: qsTr("Built-in and Serpantinum catalog") }
                    FeatureRow { icon: "dock_to_bottom"; title: qsTr("Shell layout"); detail: qsTr("Top, bottom or vertical bar") }
                    FeatureRow { icon: "widgets"; title: qsTr("Desktop widgets"); detail: qsTr("Clock, context, media and system") }
                }
            }
        }
    }

    Component {
        id: themePage

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                PageHeading {
                    title: qsTr("Choose the room's mood")
                    detail: qsTr("A short selection is shown here. The full catalog remains available in Settings → Themes.")
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 4
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: root.suggestedThemes

                        delegate: ThemeChoice {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            themeData: modelData
                            selected: RaohaneConfig.themePreset === String(modelData.id)
                            onTriggered: RaohaneConfig.themePreset = String(modelData.id)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: shellPage

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 18

                PageHeading {
                    title: qsTr("Shape the shell")
                    detail: qsTr("Choose the bar placement and whether the application dock belongs in your layout.")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    LayoutChoice {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        icon: "vertical_align_top"
                        title: qsTr("Top")
                        detail: qsTr("Horizontal bar above the workspace")
                        selected: !RaohaneConfig.barVertical && !RaohaneConfig.barBottom
                        onTriggered: {
                            RaohaneConfig.barVertical = false
                            RaohaneConfig.barBottom = false
                        }
                    }

                    LayoutChoice {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        icon: "vertical_align_bottom"
                        title: qsTr("Bottom")
                        detail: qsTr("Horizontal bar near the dock")
                        selected: !RaohaneConfig.barVertical && RaohaneConfig.barBottom
                        onTriggered: {
                            RaohaneConfig.barVertical = false
                            RaohaneConfig.barBottom = true
                        }
                    }

                    LayoutChoice {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        icon: "view_sidebar"
                        title: qsTr("Vertical")
                        detail: qsTr("Compact side-mounted bar")
                        selected: RaohaneConfig.barVertical
                        onTriggered: RaohaneConfig.barVertical = true
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66
                    surfaceRadius: 17
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 12

                        RaohaneIcon { text: "dock_to_bottom"; iconSize: 19; color: RaohaneTheme.accent }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: qsTr("Application dock"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                            Text { text: qsTr("Keep favorite and running applications close"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                        }
                        RaohaneSwitch { checked: RaohaneConfig.dockEnabled; onToggled: value => RaohaneConfig.dockEnabled = value }
                    }
                }
            }
        }
    }

    Component {
        id: readyPage

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 32

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 13

                    PageHeading {
                        title: qsTr("Your desktop is ready")
                        detail: qsTr("Two starter widgets are placed on the primary screen. Open Widget Studio any time to add, remove or arrange them.")
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        surfaceRadius: 15
                        active: true
                        showSheen: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            RaohaneIcon { text: "schedule"; iconSize: 17; color: RaohaneTheme.accent }
                            Text { Layout.fillWidth: true; text: qsTr("Clock + live context"); color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                            Text { text: qsTr("Included"); color: RaohaneTheme.accent; font.pixelSize: 8 }
                        }
                    }

                    Text {
                        text: qsTr("Display name (optional)")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        surfaceRadius: 12
                        hovered: nameField.activeFocus
                        border.color: nameField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border
                        showSheen: false

                        TextInput {
                            id: nameField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            text: RaohaneConfig.profileDisplayName
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            font.pixelSize: 10
                            onTextEdited: RaohaneConfig.profileDisplayName = text
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                RaohaneSurface {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    Layout.alignment: Qt.AlignCenter
                    surfaceRadius: 150
                    active: true
                    showSheen: false

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: 220
                        spacing: 9

                        RaohaneIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: "spa"
                            iconSize: 50
                            fill: 1
                            color: RaohaneTheme.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("RAOHANE")
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneTheme.presetName
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    component PageHeading: ColumnLayout {
        required property string title
        required property string detail
        spacing: 4

        Text { Layout.fillWidth: true; text: parent.title; color: RaohaneTheme.text; font.pixelSize: 21; font.weight: Font.DemiBold }
        Text { Layout.fillWidth: true; text: parent.detail; color: RaohaneTheme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap; lineHeight: 1.25 }
    }

    component FeatureRow: RaohaneSurface {
        id: feature
        required property string icon
        required property string title
        required property string detail

        Layout.fillWidth: true
        Layout.preferredHeight: 72
        surfaceRadius: 17
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 12
            RaohaneIcon { text: feature.icon; iconSize: 20; color: RaohaneTheme.accent }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: feature.title; color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: feature.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8; elide: Text.ElideRight }
            }
        }
    }

    component ThemeChoice: RaohaneSurface {
        id: choice
        required property var themeData
        property bool selected: false
        signal triggered()

        Layout.minimumHeight: 94
        surfaceRadius: 15
        active: selected
        interactive: true
        hovered: choiceMouse.containsMouse
        pressed: choiceMouse.pressed
        showSheen: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Rectangle { width: 24; height: 24; radius: 8; color: choice.themeData.background; border.width: 1; border.color: choice.themeData.borderStrong }
                Item { Layout.fillWidth: true }
                RaohaneIcon { visible: choice.selected; text: "check"; iconSize: 14; color: RaohaneTheme.accent }
            }
            Item { Layout.fillHeight: true }
            Text { Layout.fillWidth: true; text: choice.themeData.name; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: choice.themeData.tone; color: RaohaneTheme.textFaint; font.pixelSize: 7; elide: Text.ElideRight }
        }

        MouseArea { id: choiceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.triggered() }
    }

    component LayoutChoice: RaohaneSurface {
        id: choice
        required property string icon
        required property string title
        required property string detail
        property bool selected: false
        signal triggered()

        Layout.minimumHeight: 180
        surfaceRadius: 20
        active: selected
        interactive: true
        hovered: choiceMouse.containsMouse
        pressed: choiceMouse.pressed
        showSheen: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 8
            RaohaneIcon { text: choice.icon; iconSize: 28; fill: choice.selected ? 1 : 0; color: RaohaneTheme.accent }
            Item { Layout.fillHeight: true }
            Text { text: choice.title; color: RaohaneTheme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { Layout.fillWidth: true; text: choice.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8; wrapMode: Text.WordWrap }
            RaohaneIcon { visible: choice.selected; Layout.alignment: Qt.AlignRight; text: "check_circle"; iconSize: 18; fill: 1; color: RaohaneTheme.accent }
        }

        MouseArea { id: choiceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.triggered() }
    }

    component WelcomeAction: RaohaneSurface {
        id: action
        required property string icon
        required property string label
        property bool selected: false
        signal triggered()

        Layout.preferredWidth: actionRow.implicitWidth + 24
        Layout.preferredHeight: 38
        surfaceRadius: 12
        active: selected
        transparentIdle: !selected
        interactive: true
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        showSheen: false

        RowLayout {
            id: actionRow
            anchors.centerIn: parent
            spacing: 7
            Text { text: action.label; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
            RaohaneIcon { text: action.icon; iconSize: 14; color: RaohaneTheme.accent }
        }

        MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: action.triggered() }
    }
}
