pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: shellColumn.implicitHeight

    ColumnLayout {
        id: shellColumn
        width: parent.width
        spacing: 10

        RaohaneBarPreview {
            Layout.fillWidth: true
            orientation: editor.orientation
        }

        RaohaneBarStudio {
            id: editor
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }
    }
}
