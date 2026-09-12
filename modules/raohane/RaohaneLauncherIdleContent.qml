pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var pinnedApps: []
    property var idleActions: []

    signal pinnedRequested(var entry)
    signal actionRequested(var action)

    spacing: RaohaneTheme.spacing + 1

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: RaohaneTheme.spacingTiny
        Layout.rightMargin: RaohaneTheme.spacingTiny

        Text {
            text: qsTr("Pinned")
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }

        Item { Layout.fillWidth: true }

        Text {
            text: qsTr("Dock apps")
            color: RaohaneTheme.textFaint
            font.pixelSize: 7
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: RaohaneTheme.spacingSmall + 2

        Repeater {
            model: root.pinnedApps

            delegate: PinnedApp {
                required property var modelData
                Layout.fillWidth: true
                entry: modelData
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: RaohaneTheme.spacingTiny
        color: RaohaneTheme.borderFaint
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: RaohaneTheme.spacingTiny
        Layout.rightMargin: RaohaneTheme.spacingTiny

        Text {
            text: qsTr("Quick access")
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "/  >  =  :"
            color: RaohaneTheme.textFaint
            font.pixelSize: 8
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: RaohaneTheme.spacingSmall + 2
        rowSpacing: RaohaneTheme.spacingSmall + 2

        Repeater {
            model: root.idleActions

            delegate: QuickAction {
                required property var modelData
                Layout.fillWidth: true
                actionData: modelData
            }
        }
    }

    component PinnedApp: RaohaneSurface {
        id: app

        required property var entry

        Layout.preferredHeight: 76
        surfaceRadius: RaohaneTheme.radiusLarge
        transparentIdle: !app.hovered
        showSheen: false
        showInnerRim: false
        interactive: true
        hovered: appMouse.containsMouse || activeFocus
        pressed: appMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: "transparent"
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong

        Column {
            anchors.centerIn: parent
            width: Math.max(50, app.width - 2 * RaohaneTheme.spacingSmall)
            spacing: RaohaneTheme.spacingSmall - 1

            RaohaneSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                surfaceRadius: RaohaneTheme.radiusLarge
                active: app.hovered
                showSheen: false
                showInnerRim: false

                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(app.entry?.icon ?? "")
                    iconSize: 29
                    fallbackColor: app.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Text {
                width: parent.width
                text: String(app.entry?.name ?? qsTr("App"))
                color: app.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: appMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: app.forceActiveFocus()
            onClicked: root.pinnedRequested(app.entry)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.pinnedRequested(app.entry)
                event.accepted = true
            }
        }
    }

    component QuickAction: RaohaneSurface {
        id: actionCard

        required property var actionData

        Layout.preferredHeight: 58
        surfaceRadius: RaohaneTheme.radiusLarge
        showSheen: false
        showInnerRim: false
        raised: false
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        interactive: true
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        showStateRail: actionCard.hovered
        stateRailWidth: 3
        stateRailLength: 24
        stateRailOpacity: 0.72

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing + 2
            anchors.rightMargin: RaohaneTheme.spacing + 2
            spacing: RaohaneTheme.spacing + 1

            RaohaneSurface {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                surfaceRadius: RaohaneTheme.radius
                active: actionCard.hovered
                showSheen: false
                showInnerRim: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: actionCard.actionData?.iconName ?? "bolt"
                    iconSize: 17
                    fill: actionCard.hovered ? 1 : 0
                    symbolWeight: actionCard.hovered ? 540 : 430
                    color: actionCard.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                Text {
                    Layout.fillWidth: true
                    text: String(actionCard.actionData?.name ?? "")
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: String(actionCard.actionData?.type ?? "")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                text: "arrow_outward"
                iconSize: 12
                color: actionCard.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: actionCard.forceActiveFocus()
            onClicked: root.actionRequested(actionCard.actionData)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.actionRequested(actionCard.actionData)
                event.accepted = true
            }
        }
    }
}
