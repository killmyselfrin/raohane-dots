import QtQuick
import QtQuick.Layouts
import "osk/layouts.js" as Layouts

Item {
    id: root

    property string layoutName: Layouts.defaultLayout
    readonly property var layouts: Layouts.byName
    readonly property var currentLayout: layouts[layoutName] ?? layouts[Layouts.defaultLayout]
    readonly property var layoutNames: Object.keys(layouts)

    implicitWidth: keyRows.implicitWidth
    implicitHeight: keyRows.implicitHeight

    function cycleLayout(): void {
        if (layoutNames.length < 2)
            return
        const current = Math.max(0, layoutNames.indexOf(layoutName))
        layoutName = layoutNames[(current + 1) % layoutNames.length]
    }

    ColumnLayout {
        id: keyRows
        anchors.fill: parent
        spacing: 5

        Repeater {
            model: root.currentLayout?.keys ?? []

            delegate: RowLayout {
                required property var modelData
                spacing: 5

                Repeater {
                    model: modelData

                    delegate: RaohaneOskKey {
                        required property var modelData
                        keyData: modelData
                    }
                }
            }
        }
    }
}
