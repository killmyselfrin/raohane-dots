pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool privacyActive: false
    property string systemIdentity: ""

    signal reloadRequested()
    signal closeRequested()

    readonly property bool compactFooter: root.width < 520

    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: RaohaneTheme.spacingSmall

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: root.privacyActive ? RaohaneTheme.critical : RaohaneTheme.success
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.privacyActive ? qsTr("Privacy activity") : qsTr("System ready")
            color: RaohaneTheme.textFaint
            font.pixelSize: 9
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            visible: !root.compactFooter && root.systemIdentity.length > 0
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.width * 0.36
            text: root.systemIdentity
            color: RaohaneTheme.textFaint
            font.pixelSize: 8
            elide: Text.ElideRight
        }

        FooterButton {
            icon: "restart_alt"
            onClicked: root.reloadRequested()
        }

        FooterButton {
            icon: "close"
            onClicked: root.closeRequested()
        }
    }

    component FooterButton: RaohaneIconButton {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        buttonSize: 32
        iconSize: 15
        transparentIdle: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
