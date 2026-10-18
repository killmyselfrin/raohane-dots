pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

// The desktop's two-step widget manager. It reuses the existing free-layout
// canvas, shared design tokens and RaohaneConfig rather than creating a second
// widget engine or a second fullscreen PanelWindow.
Item {
    id: root

    property string initialWidgetId: ""
    property string initialMonitorName: ""
    property string selectedWidgetId: RaohaneDesktopWidgetRegistry.definition(initialWidgetId)
        ? initialWidgetId : "clock"
    property string monitorName: initialMonitorName.length > 0 ? initialMonitorName : "default"

    readonly property var widgets: RaohaneDesktopWidgetRegistry.definitions()
    readonly property bool freeLayout: RaohaneConfig.desktopWidgetsLayout === "free"
    readonly property var selectedDefinition: RaohaneDesktopWidgetRegistry.definition(root.selectedWidgetId)

    signal backRequested()
    signal closeRequested()

    function selectWidget(id: string): void {
        if (!RaohaneDesktopWidgetRegistry.definition(id))
            return
        root.selectedWidgetId = id
        editor.selectedWidgetId = id
    }

    function enableFreeLayout(): void {
        RaohaneConfig.desktopWidgetsLayout = "free"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 13

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: 10

            RaohaneSurface {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                surfaceRadius: 11
                raised: false
                showSheen: false
                color: RaohaneTheme.surfaceSubtle

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "widgets"
                    iconSize: 21
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Desktop widgets")
                    color: RaohaneTheme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Pick a widget, then arrange it on your desktop")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            HeaderAction {
                icon: "arrow_back"
                title: qsTr("Back")
                onTriggered: root.backRequested()
            }

            HeaderAction {
                icon: "close"
                title: qsTr("Close")
                onTriggered: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 13

            ColumnLayout {
                Layout.preferredWidth: Math.min(340, Math.max(260, root.width * 0.39))
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("LIBRARY")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: qsTr("%1 widgets").arg(root.widgets.length)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: root.widgets

                        delegate: RaohaneSurface {
                            id: widgetCard

                            required property var modelData
                            readonly property string widgetId: String(modelData.id)
                            readonly property bool selected: root.selectedWidgetId === widgetId
                            readonly property bool widgetVisible: Boolean(RaohaneConfig[modelData.key])

                            Layout.fillWidth: true
                            Layout.preferredHeight: 154
                            surfaceRadius: 13
                            raised: selected
                            showSheen: selected
                            showInnerRim: true
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
                                        || event.key === Qt.Key_Enter) {
                                    root.selectWidget(widgetCard.widgetId)
                                    event.accepted = true
                                }
                            }
                            border.width: selected ? 2 : 1
                            border.color: selected ? RaohaneTheme.accentBorder
                                : widgetCard.activeFocus || cardMouse.containsMouse
                                    ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
                            color: selected ? RaohaneTheme.surfaceRaised
                                : RaohaneTheme.surfaceDeep

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    widgetCard.forceActiveFocus()
                                    root.selectWidget(widgetCard.widgetId)
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 11
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    RaohaneIcon {
                                        text: widgetCard.modelData.icon
                                        iconSize: 18
                                        color: widgetCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                    }

                                    Item { Layout.fillWidth: true }

                                    RaohaneSwitch {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 24
                                        checked: widgetCard.widgetVisible
                                        onToggled: value => RaohaneConfig[widgetCard.modelData.key] = value
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    radius: 8
                                    color: RaohaneTheme.backgroundElevated
                                    border.color: RaohaneTheme.borderFaint

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Rectangle {
                                            width: widgetCard.widgetId === "clock" ? 29 : 23
                                            height: 24
                                            radius: 6
                                            color: RaohaneTheme.surfaceSubtle
                                            border.color: RaohaneTheme.accentBorder

                                            RaohaneIcon {
                                                anchors.centerIn: parent
                                                iconSize: 14
                                                text: widgetCard.modelData.icon
                                                color: RaohaneTheme.accent
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 5

                                            Rectangle {
                                                width: 43
                                                height: 4
                                                radius: 2
                                                color: RaohaneTheme.textMuted
                                                opacity: 0.65
                                            }
                                            Rectangle {
                                                width: 29
                                                height: 4
                                                radius: 2
                                                color: RaohaneTheme.accent
                                                opacity: 0.48
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: widgetCard.modelData.title
                                    color: widgetCard.widgetVisible ? RaohaneTheme.text : RaohaneTheme.textMuted
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: widgetCard.widgetVisible ? qsTr("Visible") : qsTr("Hidden")
                                    color: widgetCard.widgetVisible ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 83
                    surfaceRadius: 12
                    raised: false
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: root.freeLayout ? qsTr("Free layout is on") : qsTr("Preset layout")
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: RaohaneTheme.text
                            }

                            RaohaneIcon {
                                text: root.freeLayout ? "check_circle" : "lock"
                                iconSize: 17
                                color: root.freeLayout ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.pixelSize: 9
                            color: RaohaneTheme.textMuted
                            text: root.freeLayout
                                ? qsTr("Drag to move and pull a corner to resize.")
                                : qsTr("Enable free layout to edit positions. Presets stay saved.")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.freeLayout
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.enableFreeLayout()
                    }
                }

                Item { Layout.fillHeight: true }

                FooterAction {
                    Layout.fillWidth: true
                    icon: "tune"
                    title: qsTr("Full Widget Studio")
                    onTriggered: RaohaneSettingsRouter.request("widgets", "")
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: RaohaneTheme.borderFaint
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("LIVE LAYOUT")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.monitorName
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        elide: Text.ElideMiddle
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 13
                    color: RaohaneTheme.surfaceDeep
                    border.color: RaohaneTheme.borderFaint
                    clip: true

                    Flickable {
                        id: editorScroll
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        contentWidth: width
                        contentHeight: editor.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        RaohaneFreeWidgetStudio {
                            id: editor
                            width: editorScroll.width
                            monitorName: root.monitorName
                            enabled: root.freeLayout
                            opacity: root.freeLayout ? 1 : 0.38
                            onMonitorNameChanged: root.monitorName = monitorName
                            onSelectedWidgetIdChanged: root.selectedWidgetId = selectedWidgetId
                            Component.onCompleted: selectedWidgetId = root.selectedWidgetId
                        }
                    }

                    // Preset layouts must be explicitly switched before editing
                    // individual widget coordinates, never silently overwritten.
                    Rectangle {
                        anchors.fill: parent
                        visible: !root.freeLayout
                        radius: 13
                        color: RaohaneTheme.surfaceDeep
                        opacity: 0.95

                        Column {
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 40, 300)
                            spacing: 15

                            RaohaneIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                iconSize: 32
                                text: "space_dashboard"
                                color: RaohaneTheme.accent
                            }

                            Text {
                                width: parent.width
                                text: qsTr("Your preset layout is protected")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                width: parent.width
                                text: qsTr("Switch to Free layout to drag and resize widgets independently.")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            FooterAction {
                                width: parent.width
                                icon: "dashboard_customize"
                                title: qsTr("Enable free layout")
                                onTriggered: root.enableFreeLayout()
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            RaohaneIcon {
                text: "info"
                iconSize: 14
                color: RaohaneTheme.textFaint
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Changes are saved automatically. Existing preset layouts remain available.")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Text {
                text: root.selectedDefinition?.title ?? ""
                color: RaohaneTheme.accent
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    component HeaderAction: RaohaneSurface {
        id: button

        required property string icon
        required property string title
        signal triggered()

        Layout.preferredWidth: 72
        Layout.preferredHeight: 32
        surfaceRadius: 9
        raised: false
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        hovered: pointer.containsMouse || activeFocus
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
                    || event.key === Qt.Key_Enter) {
                button.triggered()
                event.accepted = true
            }
        }
        color: hovered ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceDeep

        Row {
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: button.icon
                iconSize: 13
                color: RaohaneTheme.accent
            }
            Text {
                text: button.title
                font.pixelSize: 10
                color: RaohaneTheme.text
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    component FooterAction: RaohaneSurface {
        id: button

        required property string icon
        required property string title
        signal triggered()

        Layout.preferredHeight: 37
        surfaceRadius: 10
        raised: false
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        hovered: pointer.containsMouse || activeFocus
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
                    || event.key === Qt.Key_Enter) {
                button.triggered()
                event.accepted = true
            }
        }
        color: hovered ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle

        Row {
            anchors.centerIn: parent
            spacing: 8
            RaohaneIcon {
                text: button.icon
                iconSize: 15
                color: RaohaneTheme.accent
            }
            Text {
                text: button.title
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
