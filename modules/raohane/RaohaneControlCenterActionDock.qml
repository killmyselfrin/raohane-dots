pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    signal screenshotRequested()
    signal translatorRequested()
    signal oskRequested()
    signal wallpaperRequested()
    signal powerRequested()

    implicitHeight: 154
    surfaceRadius: RaohaneTheme.radiusHero
    raised: false
    showSheen: false
    showInnerRim: false
    idleColor: RaohaneTheme.surfaceSubtle
    idleBorderColor: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacing
        spacing: RaohaneTheme.spacingSmall

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            Text {
                text: qsTr("Shortcuts")
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            RaohaneIcon {
                text: "grid_view"
                iconSize: 13
                color: RaohaneTheme.textFaint
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: RaohaneTheme.spacingSmall
            rowSpacing: RaohaneTheme.spacingSmall

            ActionButton {
                Layout.fillWidth: true
                icon: "screenshot_region"
                label: qsTr("Screenshot")
                onTriggered: root.screenshotRequested()
            }

            ActionButton {
                Layout.fillWidth: true
                icon: "translate"
                label: qsTr("Translate")
                onTriggered: root.translatorRequested()
            }

            ActionButton {
                Layout.fillWidth: true
                icon: "keyboard"
                label: qsTr("Keyboard")
                onTriggered: root.oskRequested()
            }

            ActionButton {
                Layout.fillWidth: true
                icon: "wallpaper"
                label: qsTr("Wallpaper")
                onTriggered: root.wallpaperRequested()
            }

            ActionButton {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                icon: "power_settings_new"
                label: qsTr("Power")
                accent: true
                onTriggered: root.powerRequested()
            }
        }
    }

    component ActionButton: RaohaneSurface {
        id: action

        required property string icon
        required property string label
        property bool accent: false
        signal triggered()

        Layout.preferredHeight: 38
        surfaceRadius: RaohaneTheme.radius
        raised: false
        showSheen: false
        showInnerRim: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        active: action.accent
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        transparentIdle: !action.accent
        idleBorderColor: "transparent"
        hoverColor: RaohaneTheme.surfaceHover
        hoverBorderColor: "transparent"
        activeColor: RaohaneTheme.accentSoft
        activeBorderColor: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing
            anchors.rightMargin: RaohaneTheme.spacing
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: action.icon
                iconSize: 15
                fill: action.accent ? 1 : action.hovered ? 0.35 : 0
                symbolWeight: action.accent ? 560 : 440
                color: action.accent || action.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: action.label
                color: action.accent || action.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            RaohaneIcon {
                visible: action.accent
                text: "chevron_right"
                iconSize: 12
                color: RaohaneTheme.accent
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                action.triggered()
                event.accepted = true
            }
        }
    }
}
