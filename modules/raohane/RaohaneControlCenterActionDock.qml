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

    implicitHeight: 64
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    showInnerRim: false
    idleColor: RaohaneTheme.surfaceSubtle
    idleBorderColor: RaohaneTheme.borderFaint

    RowLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacingSmall
        spacing: RaohaneTheme.spacingTiny

        ActionButton {
            Layout.fillWidth: true
            icon: "screenshot_region"
            label: qsTr("Screenshot")
            onTriggered: root.screenshotRequested()
        }

        ActionButton {
            Layout.fillWidth: true
            icon: "translate"
            label: qsTr("Translator")
            onTriggered: root.translatorRequested()
        }

        ActionButton {
            Layout.fillWidth: true
            icon: "keyboard"
            label: qsTr("OSK")
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
            icon: "power_settings_new"
            label: qsTr("Power")
            accent: true
            onTriggered: root.powerRequested()
        }
    }

    component ActionButton: RaohaneSurface {
        id: action

        required property string icon
        required property string label
        property bool accent: false
        signal triggered()

        Layout.preferredHeight: 48
        surfaceRadius: RaohaneTheme.radiusSmall
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
        hoverColor: RaohaneTheme.surfaceHover
        hoverBorderColor: RaohaneTheme.borderStrong
        activeColor: RaohaneTheme.accentSoft
        activeBorderColor: RaohaneTheme.accentBorder

        Column {
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingTiny

            RaohaneIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.icon
                iconSize: 16
                fill: action.accent ? 1 : action.hovered ? 0.4 : 0
                symbolWeight: action.accent ? 560 : 450
                color: action.accent || action.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.label
                color: action.accent || action.hovered ? RaohaneTheme.text : RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.Medium
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
