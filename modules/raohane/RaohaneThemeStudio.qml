import QtQuick
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RaohaneThemeCatalog {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
