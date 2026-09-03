pragma Singleton

import QtQuick
import Quickshell

// Native transient drag/drop shelf backend. The shelf intentionally owns only
// session state: stale file paths should not survive a shell restart.
Singleton {
    id: root

    property var items: []
    property int maxItems: 30
    property bool open: false
    property real positionX: 20
    property real positionY: 220
    property string targetScreenName: ""

    function cleanPath(value): string {
        let path = String(value ?? "")
        if (path.startsWith("file://"))
            path = path.substring(7)
        try {
            path = decodeURIComponent(path)
        } catch (error) {
        }
        return path
    }

    function shellQuote(value): string {
        return "'" + String(value ?? "").replace(/'/g, "'\"'\"'") + "'"
    }

    function uriForPath(value): string {
        const path = root.cleanPath(value)
        return path.length > 0 ? "file://" + path : ""
    }

    function parentPath(value): string {
        let path = root.cleanPath(value).replace(/\/+$/, "")
        const separator = path.lastIndexOf("/")
        if (separator <= 0)
            return "/"
        return path.substring(0, separator)
    }

    function addItems(urls): void {
        const next = Array.from(root.items)
        for (const url of Array.from(urls ?? [])) {
            const path = root.cleanPath(url)
            if (path.length > 0 && !next.includes(path) && next.length < root.maxItems)
                next.push(path)
        }
        root.items = next
    }

    function removeAt(index: int): void {
        if (index < 0 || index >= root.items.length)
            return
        const next = root.items.slice()
        next.splice(index, 1)
        root.items = next
    }

    function removePath(value): void {
        const path = root.cleanPath(value)
        const index = root.items.indexOf(path)
        if (index >= 0)
            root.removeAt(index)
    }

    function show(urls, x: real, y: real): void {
        root.showOnScreen(urls, x, y, "")
    }

    function showOnScreen(urls, x: real, y: real, screenName): void {
        root.addItems(urls)
        if (Number.isFinite(Number(x)))
            root.positionX = Number(x)
        if (Number.isFinite(Number(y)))
            root.positionY = Number(y)
        root.targetScreenName = String(screenName ?? "")
        root.open = true
    }

    function openPath(value): void {
        const path = root.cleanPath(value)
        if (path.length > 0)
            Quickshell.execDetached(["xdg-open", path])
    }

    function revealPath(value): void {
        const path = root.cleanPath(value)
        if (path.length > 0)
            Quickshell.execDetached(["xdg-open", root.parentPath(path)])
    }

    function copyPaths(paths): void {
        const normalized = Array.from(paths ?? [])
            .map(path => root.cleanPath(path))
            .filter(path => path.length > 0)
        if (normalized.length === 0)
            return
        const uriList = normalized.map(path => root.uriForPath(path)).join("\n")
        Quickshell.execDetached([
            "bash", "-lc",
            "printf '%s' " + root.shellQuote(uriList) + " | wl-copy --type text/uri-list"
        ])
    }

    function copyPath(value): void {
        root.copyPaths([value])
    }

    function copyAll(): void {
        root.copyPaths(root.items)
    }

    function clear(): void {
        root.items = []
        root.open = false
    }

    function hide(): void {
        root.open = false
    }
}
