pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// One minute source drives both faces. No second hand or continuous animation.
RaohaneSurface {
    id: root
    property bool compact: false
    property date now: new Date()
    readonly property bool narrow: width < 340

    implicitHeight: root.compact ? 154 : 190
    surfaceRadius: RaohaneTheme.radiusHero
    idleColor: RaohaneTheme.surfaceDeep
    idleBorderColor: RaohaneTheme.borderFaint
    showSheen: false
    showInnerRim: false
    clip: true

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 14 : 20
        spacing: 18

        Rectangle {
            id: dial
            visible: !root.narrow
            Layout.preferredWidth: root.compact ? 116 : 144
            Layout.preferredHeight: width
            radius: width / 2
            color: RaohaneTheme.accentSoft

            Repeater {
                model: 12
                Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 30
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        width: index % 3 === 0 ? 3 : 2
                        height: index % 3 === 0 ? 9 : 4
                        radius: 2
                        color: RaohaneTheme.accent
                        opacity: index % 3 === 0 ? 0.9 : 0.35
                    }
                }
            }
            Item {
                anchors.fill: parent
                rotation: (root.now.getHours() % 12 + root.now.getMinutes() / 60) * 30
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.27
                    width: 7
                    height: parent.height * 0.26
                    radius: 4
                    color: RaohaneTheme.text
                }
            }
            Item {
                anchors.fill: parent
                rotation: root.now.getMinutes() * 6
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.15
                    width: 4
                    height: parent.height * 0.38
                    radius: 3
                    color: RaohaneTheme.accent
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                color: RaohaneTheme.accent
            }
            Accessible.role: Accessible.StaticText
            Accessible.name: Qt.formatTime(root.now, "HH:mm")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 5
            Text {
                Layout.fillWidth: true
                text: root.now.toLocaleDateString(Qt.locale(RaohaneI18n.language), "dddd").toUpperCase()
                color: RaohaneTheme.accent
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Qt.formatTime(root.now, "HH:mm")
                color: RaohaneTheme.text
                font.pixelSize: root.compact ? 44 : 54
                minimumPixelSize: 24
                fontSizeMode: Text.Fit
                font.weight: Font.Bold
                font.letterSpacing: -2
            }
            Text {
                Layout.fillWidth: true
                text: root.now.toLocaleDateString(Qt.locale(RaohaneI18n.language), "d MMMM yyyy")
                color: RaohaneTheme.textMuted
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}
