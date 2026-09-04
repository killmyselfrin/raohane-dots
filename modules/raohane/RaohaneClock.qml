pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool showDate: true
    property bool active: true
    property date now: new Date()

    implicitWidth: clockRow.implicitWidth
    implicitHeight: Math.max(24, clockRow.implicitHeight)

    readonly property string timeText: Qt.formatTime(root.now, "HH:mm")
    readonly property string dateText: Qt.formatDate(root.now, "ddd d MMM")

    onActiveChanged: {
        if (active)
            root.now = new Date()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 7

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeText
            color: RaohaneTheme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: -0.15
        }

        Rectangle {
            visible: root.showDate
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 13
            color: RaohaneTheme.borderFaint
        }

        Text {
            visible: root.showDate
            Layout.alignment: Qt.AlignVCenter
            text: root.dateText
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: Font.Medium
        }
    }
}
