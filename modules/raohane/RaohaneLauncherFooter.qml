pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: RaohaneTheme.spacingSmall

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: RaohaneTheme.borderFaint
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 22
        Layout.leftMargin: RaohaneTheme.spacingTiny
        Layout.rightMargin: RaohaneTheme.spacingTiny

        Text {
            text: "RAOHANE"
            color: RaohaneTheme.textMuted
            font.pixelSize: 7
            font.letterSpacing: 1.2
            font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "↑↓ navigate   ↵ open   esc close"
            color: RaohaneTheme.textFaint
            font.pixelSize: 7
        }
    }
}
