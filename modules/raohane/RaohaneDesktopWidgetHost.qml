pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    required property string widgetId
    property bool compact: false
    property bool shown: true

    signal widgetMenuRequested(string widgetId, real screenX, real screenY)

    readonly property var definition: RaohaneDesktopWidgetRegistry.definition(root.widgetId)
    readonly property string configKey: String(root.definition?.key ?? "")
    readonly property bool widgetEnabled: root.configKey.length > 0 && Boolean(RaohaneConfig[root.configKey])
    readonly property string faceStyle: RaohaneConfig.desktopWidgetStyle(root.widgetId)

    Layout.fillWidth: true
    Layout.preferredHeight: root.widgetEnabled && root.shown ? contentLoader.height : 0
    implicitHeight: Layout.preferredHeight
    visible: root.widgetEnabled && root.shown

    Loader {
        id: contentLoader

        width: parent.width
        height: item?.implicitHeight ?? 0
        active: root.widgetEnabled && root.shown && root.definition !== null
        source: RaohaneDesktopWidgetRegistry.sourceFor(root.widgetId, root.faceStyle)
    }

    // Only right-clicks are intercepted. Media and other widget controls
    // continue receiving their normal left-button/touch interactions.
    MouseArea {
        anchors.fill: parent
        z: 50
        acceptedButtons: Qt.RightButton
        enabled: root.widgetEnabled && root.shown && !RaohaneState.desktopWidgetEditMode
        onClicked: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y)
            root.widgetMenuRequested(root.widgetId, p.x, p.y)
        }
    }

    Binding {
        target: contentLoader.item
        property: "compact"
        value: root.compact
        when: contentLoader.item !== null
    }
    Binding {
        target: contentLoader.item
        property: "faceStyle"
        value: root.faceStyle
        when: contentLoader.item !== null && root.faceStyle !== "classic"
    }
}
