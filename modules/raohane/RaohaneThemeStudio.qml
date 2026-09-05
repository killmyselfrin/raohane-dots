import QtQuick
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RaohaneThemePresetManager {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 10
        }

        RaohaneThemeCatalog {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
