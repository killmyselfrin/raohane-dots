pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// A large, quiet desktop anchor. No extra weather/network polling or custom
// font dependency: every label uses the native clock and shared theme.
RaohaneSurface {
    id: root

    property bool compact: false
    property date now: new Date()

    implicitHeight: root.compact ? 154 : 190
    surfaceRadius: RaohaneTheme.radiusHero
    raised: true
    showSheen: true
    showInnerRim: true
    idleColor: RaohaneTheme.surfaceRaised
    idleBorderColor: RaohaneTheme.borderFaint
    clip: true

    // A minute refresh is sufficient for an HH:mm widget. Stop the clock
    // when the desktop canvas or its persisted widget slot is hidden.
    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: root.surfaceRadius
        opacity: 0.25
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: RaohaneTheme.accentSoft }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 32
        radius: 2
        color: RaohaneTheme.accent
        opacity: 0.75
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 15 : 19
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            RaohaneIcon {
                text: "schedule"
                iconSize: 14
                color: RaohaneTheme.accent
            }

            Text {
                text: "RAOHANE"
                color: RaohaneTheme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.8
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDate(root.now, "ddd").toUpperCase()
                color: RaohaneTheme.textFaint
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: Qt.formatTime(root.now, "HH:mm")
            color: RaohaneTheme.text
            font.pixelSize: root.compact ? 52 : 70
            font.weight: Font.Light
            font.letterSpacing: -2.4
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: root.compact ? 1 : 5
            spacing: 9

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: RaohaneTheme.textMuted
                font.pixelSize: root.compact ? 10 : 12
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.75
            }
        }
    }
}
