pragma Singleton

import Quickshell
import qs.modules.raohane.services

// Temporary compatibility facade.
//
// Compatibility UI still importing qs.services.Notifications is routed into
// the single Raohane-owned NotificationServer. This file intentionally owns no
// notification daemon or persistent state and can be deleted with the legacy
// service namespace later in the standalone migration.
Singleton {
    id: root

    property bool silent: RaohaneNotifications.silent
    readonly property int unread: RaohaneNotifications.unread
    readonly property var list: RaohaneNotifications.list
    readonly property var popupList: RaohaneNotifications.popupList
    readonly property bool popupInhibited: RaohaneNotifications.popupInhibited
    readonly property string filePath: RaohaneNotifications.historyPath
    readonly property var latestTimeForApp: RaohaneNotifications.latestTimeForApp
    readonly property var groupsByAppName: RaohaneNotifications.groupsByAppName
    readonly property var popupGroupsByAppName: RaohaneNotifications.popupGroupsByAppName
    readonly property var appNameList: RaohaneNotifications.appNameList
    readonly property var popupAppNameList: RaohaneNotifications.popupAppNameList

    signal initDone()
    signal notify(notification: var)
    signal discard(id: int)
    signal discardAll()
    signal timeout(id: int)

    onSilentChanged: {
        if (RaohaneNotifications.silent !== root.silent)
            RaohaneNotifications.silent = root.silent
    }

    Connections {
        target: RaohaneNotifications

        function onSilentChanged(): void {
            if (root.silent !== RaohaneNotifications.silent)
                root.silent = RaohaneNotifications.silent
        }

        function onInitDone(): void { root.initDone() }
        function onNotify(notification): void { root.notify(notification) }
        function onDiscard(id): void { root.discard(id) }
        function onDiscardAll(): void { root.discardAll() }
        function onTimeout(id): void { root.timeout(id) }
    }

    function markAllRead(): void { RaohaneNotifications.markAllRead() }
    function discardNotification(id): void { RaohaneNotifications.discardNotification(id) }
    function discardAllNotifications(): void { RaohaneNotifications.discardAllNotifications() }
    function cancelTimeout(id): void { RaohaneNotifications.cancelTimeout(id) }
    function timeoutNotification(id): void { RaohaneNotifications.timeoutNotification(id) }
    function timeoutAll(): void { RaohaneNotifications.timeoutAll() }
    function attemptInvokeAction(id, identifier): void { RaohaneNotifications.attemptInvokeAction(id, identifier) }
    function refresh(): void { RaohaneNotifications.refresh() }
    function triggerListChange(): void {}
}
