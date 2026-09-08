import QtQuick
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RaohaneThemePresetManager {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 14
        }

        RaohaneThemeCatalog {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
