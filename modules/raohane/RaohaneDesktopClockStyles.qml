pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Two clock faces over the same one-minute time source as the classic face.
// No network, shell process, animated shader or new service subscription.
RaohaneSurface {
    id: root

    property bool compact: false
    property string faceStyle: "minimal"
    property date now: new Date()

    readonly property bool aurora: faceStyle === "aurora"

    implicitHeight: compact ? 154 : 190
    surfaceRadius: aurora ? 22 : 14
    raised: aurora
    showSheen: aurora
    showInnerRim: aurora
    idleColor: aurora ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceDeep
    idleBorderColor: aurora ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
    clip: true

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        visible: root.aurora
        radius: root.surfaceRadius
        opacity: 0.35
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: RaohaneTheme.accentSoft }
            GradientStop { position: 0.7; color: RaohaneTheme.surfaceRaised }
            GradientStop { position: 1; color: RaohaneTheme.accentSoft }
        }
    }

    // A quiet left rail adds a visual identity even with effects disabled.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.aurora ? 4 : 2
        height: parent.height - 42
        radius: width
        color: RaohaneTheme.accent
        opacity: root.aurora ? 0.9 : 0.35
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 14 : 19
        spacing: 2

        RowLayout {
            Layout.fillWidth: true

            RaohaneIcon {
                text: root.aurora ? "auto_awesome" : "schedule"
                iconSize: 14
                color: RaohaneTheme.accent
            }

            Text {
                text: root.aurora ? qsTr("AURORA CLOCK") : qsTr("TIME")
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.7
                color: RaohaneTheme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDate(root.now, "ddd").toUpperCase()
                font.pixelSize: 10
                color: RaohaneTheme.textFaint
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Qt.formatTime(root.now, "HH:mm")
                font.pixelSize: root.compact ? 52 : (root.aurora ? 74 : 68)
                font.weight: root.aurora ? Font.Light : Font.DemiBold
                font.letterSpacing: root.aurora ? -2.3 : -1.8
                color: RaohaneTheme.text
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.aurora
                width: 8
                height: 8
                radius: 4
                color: RaohaneTheme.accent
                opacity: 0.86
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Qt.formatDate(root.now, root.aurora ? "dddd · d MMMM yyyy" : "ddd, d MMM yyyy")
                font.pixelSize: root.compact ? 10 : 12
                color: root.aurora ? RaohaneTheme.accent : RaohaneTheme.textMuted
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.aurora
                Layout.preferredWidth: 42
                Layout.preferredHeight: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.7
            }
        }
    }
}
