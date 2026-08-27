pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool showDate: true
    property date now: new Date()

    implicitWidth: clockColumn.implicitWidth
    implicitHeight: clockColumn.implicitHeight

    readonly property string timeText: Qt.formatTime(root.now, "HH:mm")
    readonly property string dateText: Qt.formatDate(root.now, "ddd, d MMM")

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        id: clockColumn
        spacing: -2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.timeText
            color: RaohaneTheme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.showDate
            Layout.alignment: Qt.AlignHCenter
            text: root.dateText
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
        }
    }
}
