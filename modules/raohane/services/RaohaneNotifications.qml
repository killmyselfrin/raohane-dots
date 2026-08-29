pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import qs.modules.raohane.config

Singleton {
    id: root

    property bool silent: false
    property int unread: 0
    property int defaultTimeout: 7000
    property int nextId: 0
    property bool historyLoaded: false
    property list<NotificationEntry> list: []

    readonly property var popupList: root.list.filter(entry => entry.popup)
    readonly property bool popupInhibited: root.silent
    readonly property string historyPath: RaohanePaths.notificationsFile
    readonly property var latestTimeForApp: root.latestTimesForList(root.list)
    readonly property var groupsByAppName: root.groupsForList(root.list)
    readonly property var popupGroupsByAppName: root.groupsForList(root.popupList)
    readonly property var appNameList: root.appNamesForGroups(root.groupsByAppName)
    readonly property var popupAppNameList: root.appNamesForGroups(root.popupGroupsByAppName)

    signal initDone()
    signal notify(notification: var)
    signal discard(id: int)
    signal discardAll()
    signal timeout(id: int)

    component NotificationEntry: QtObject {
        required property int notificationId
        property var notification: null
        property var actions: []
        property bool popup: false
        property bool isTransient: false
        property string appIcon: ""
        property string appName: ""
        property string body: ""
        property string image: ""
        property string summary: ""
        property double time: 0
        property string urgency: "normal"
        property var timer: null
    }

    component NotificationTimer: Timer {
        required property int notificationId
        interval: root.defaultTimeout
        running: true
        repeat: false

        onTriggered: {
            const entry = root.entryById(notificationId)
            if (!entry) {
                destroy()
                return
            }

            entry.timer = null
            if (entry.isTransient)
                root.discardNotification(notificationId)
            else
                root.timeoutNotification(notificationId)
            destroy()
        }
    }

    Component {
        id: entryComponent
        NotificationEntry {}
    }

    Component {
        id: timerComponent
        NotificationTimer {}
    }

    function urgencyName(notification): string {
        let value = "normal"
        if (notification && notification.urgency !== undefined && notification.urgency !== null)
            value = String(notification.urgency).toLowerCase()
        if (value.includes("critical"))
            return "critical"
        if (value.includes("low"))
            return "low"
        return "normal"
    }

    function entryById(id: int): var {
        return root.list.find(entry => entry.notificationId === id) ?? null
    }

    function latestTimesForList(entries): var {
        const latest = {}
        for (const entry of entries) {
            const app = entry.appName || "Notification"
            latest[app] = Math.max(latest[app] || 0, entry.time || 0)
        }
        return latest
    }

    function groupsForList(entries): var {
        const groups = {}
        for (const entry of entries) {
            const app = entry.appName || "Notification"
            if (!groups[app]) {
                groups[app] = {
                    appName: app,
                    appIcon: entry.appIcon,
                    notifications: [],
                    time: 0
                }
            }
            groups[app].notifications.push(entry)
            groups[app].time = Math.max(groups[app].time, entry.time || 0)
        }
        return groups
    }

    function appNamesForGroups(groups): var {
        return Object.keys(groups).sort((a, b) => groups[b].time - groups[a].time)
    }

    function serializable(entry): var {
        return {
            notificationId: entry.notificationId,
            appIcon: entry.appIcon,
            appName: entry.appName,
            body: entry.body,
            image: entry.image,
            summary: entry.summary,
            time: entry.time,
            urgency: entry.urgency
        }
    }

    function saveHistory(): void {
        historyFile.setText(JSON.stringify(root.list.map(root.serializable), null, 2))
    }

    function refresh(): void {
        if (!root.historyLoaded)
            historyFile.reload()
    }

    function markAllRead(): void {
        root.unread = 0
    }

    function cancelTimeout(id: int): void {
        const entry = root.entryById(id)
        if (!entry || !entry.timer)
            return
        entry.timer.stop()
        entry.timer.destroy()
        entry.timer = null
    }

    function discardNotification(id: int): void {
        const index = root.list.findIndex(entry => entry.notificationId === id)
        if (index < 0)
            return

        const entry = root.list[index]
        root.cancelTimeout(id)

        if (entry.notification)
            entry.notification.dismiss()

        root.list.splice(index, 1)
        root.list = root.list.slice(0)
        root.saveHistory()
        root.discard(id)
        entry.destroy()
    }

    function discardAllNotifications(): void {
        const entries = root.list.slice(0)
        root.list = []
        root.unread = 0

        for (const entry of entries) {
            if (entry.timer) {
                entry.timer.stop()
                entry.timer.destroy()
            }
            if (entry.notification)
                entry.notification.dismiss()
            entry.destroy()
        }

        root.saveHistory()
        root.discardAll()
    }

    function timeoutNotification(id: int): void {
        const entry = root.entryById(id)
        if (!entry)
            return
        entry.popup = false
        root.list = root.list.slice(0)
        root.timeout(id)
    }

    function timeoutAll(): void {
        for (const entry of root.popupList.slice(0)) {
            root.cancelTimeout(entry.notificationId)
            entry.popup = false
            root.timeout(entry.notificationId)
        }
        root.list = root.list.slice(0)
    }

    function attemptInvokeAction(id: int, identifier: string): void {
        const entry = root.entryById(id)
        if (!entry || !entry.notification)
            return

        const action = entry.notification.actions.find(candidate => candidate.identifier === identifier)
        if (action)
            action.invoke()

        root.discardNotification(id)
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true

            const id = ++root.nextId
            const entry = entryComponent.createObject(root, {
                notificationId: id,
                notification: notification,
                actions: notification.actions.map(action => ({
                    identifier: action.identifier,
                    text: action.text
                })),
                popup: !root.silent,
                isTransient: notification.hints.transient ?? false,
                appIcon: notification.appIcon ?? "",
                appName: notification.appName ?? "",
                body: notification.body ?? "",
                image: notification.image ?? "",
                summary: notification.summary ?? "",
                time: Date.now(),
                urgency: root.urgencyName(notification)
            })

            if (entry.popup && notification.expireTimeout !== 0) {
                const timeout = notification.expireTimeout < 0
                    ? root.defaultTimeout
                    : notification.expireTimeout
                entry.timer = timerComponent.createObject(root, {
                    notificationId: id,
                    interval: timeout
                })
            }

            root.list = [...root.list, entry]
            root.unread++
            root.saveHistory()
            root.notify(entry)
        }
    }

    FileView {
        id: historyFile
        path: root.historyPath

        onLoaded: {
            if (root.historyLoaded)
                return

            try {
                const parsed = JSON.parse(historyFile.text())
                if (Array.isArray(parsed)) {
                    const liveEntries = root.list.slice(0)
                    const restored = []
                    let maxId = root.nextId

                    for (const saved of parsed) {
                        const id = Number(saved.notificationId) || ++maxId
                        maxId = Math.max(maxId, id)
                        restored.push(entryComponent.createObject(root, {
                            notificationId: id,
                            actions: [],
                            popup: false,
                            isTransient: false,
                            appIcon: saved.appIcon ?? "",
                            appName: saved.appName ?? "",
                            body: saved.body ?? "",
                            image: saved.image ?? "",
                            summary: saved.summary ?? "",
                            time: Number(saved.time) || Date.now(),
                            urgency: saved.urgency ?? "normal"
                        }))
                    }

                    root.nextId = maxId
                    root.list = [...restored, ...liveEntries]
                }
            } catch (error) {
                console.warn("[RaohaneNotifications] Could not parse history:", error)
            }

            root.historyLoaded = true
            root.initDone()
        }

        onLoadFailed: error => {
            root.historyLoaded = true
            if (error === FileViewError.FileNotFound)
                root.saveHistory()
            else
                console.warn("[RaohaneNotifications] Could not load history:", error)
            root.initDone()
        }
    }

    Component.onCompleted: root.refresh()
}
