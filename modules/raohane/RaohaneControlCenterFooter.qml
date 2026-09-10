pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool privacyActive: false
    property string systemIdentity: ""

    signal reloadRequested()
    signal closeRequested()

    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: RaohaneTheme.spacingSmall

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.privacyActive ? RaohaneTheme.critical : RaohaneTheme.success
        }

        Text {
            Layout.fillWidth: true
            text: root.privacyActive ? qsTr("Privacy activity") : qsTr("System ready")
            color: RaohaneTheme.textFaint
            font.pixelSize: 8
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            visible: root.systemIdentity.length > 0
            text: root.systemIdentity
            color: RaohaneTheme.textFaint
            font.pixelSize: 7
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
