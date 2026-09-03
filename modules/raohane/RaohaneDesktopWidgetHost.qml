pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    required property string widgetId
    property bool compact: false
    property bool shown: true

    readonly property var definition: RaohaneDesktopWidgetRegistry.definition(root.widgetId)
    readonly property string configKey: String(root.definition?.key ?? "")
    readonly property bool enabled: root.configKey.length > 0 && Boolean(RaohaneConfig[root.configKey])

    Layout.fillWidth: true
    Layout.preferredHeight: root.enabled && root.shown ? contentLoader.height : 0
    implicitHeight: Layout.preferredHeight
    visible: root.enabled && root.shown

    Loader {
        id: contentLoader

        width: parent.width
        height: item?.implicitHeight ?? 0
        active: root.enabled && root.shown && root.definition !== null
        source: root.definition?.source ?? ""
    }

    Binding {
        target: contentLoader.item
        property: "compact"
        value: root.compact
        when: contentLoader.item !== null
    }
}
