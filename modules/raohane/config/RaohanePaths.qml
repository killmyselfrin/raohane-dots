pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell

Singleton {
    id: root

    function cleanPath(value): string {
        if (value === null || value === undefined)
            return ""
        let path = String(value)
        if (path.startsWith("file://"))
            path = path.substring(7)
        try {
            return decodeURIComponent(path)
        } catch (error) {
            return path
        }
    }

    function join(base: string, child: string): string {
        const left = root.cleanPath(base).replace(/\/+$/, "")
        const right = String(child ?? "").replace(/^\/+/, "")
        if (left.length === 0)
            return right
        if (right.length === 0)
            return left
        return left + "/" + right
    }

    readonly property string home: root.cleanPath(StandardPaths.standardLocations(StandardPaths.HomeLocation)[0] ?? "")
    readonly property string configRoot: root.cleanPath(StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0] ?? "")
    readonly property string stateRoot: root.cleanPath(StandardPaths.standardLocations(StandardPaths.StateLocation)[0] ?? "")
    readonly property string cacheRoot: root.cleanPath(StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] ?? "")
    readonly property string pictures: root.cleanPath(StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] ?? "")
    readonly property string downloads: root.cleanPath(StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0] ?? "")
    readonly property string music: root.cleanPath(StandardPaths.standardLocations(StandardPaths.MusicLocation)[0] ?? "")
    readonly property string videos: root.cleanPath(StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0] ?? "")
    readonly property string username: String(Quickshell.env("USER") ?? Quickshell.env("LOGNAME") ?? "")

    // Repository/runtime-owned roots.
    readonly property string assetsUrl: Quickshell.shellPath("assets")
    readonly property string scriptsPath: root.cleanPath(Quickshell.shellPath("scripts"))
    readonly property string defaultsPath: root.cleanPath(Quickshell.shellPath("defaults"))

    // Persistent Raohane namespaces. Native code must prefer these over the
    // inherited modules/common/Directories singleton.
    readonly property string configDirectory: root.join(root.configRoot, "raohane")
    readonly property string nativeConfigFile: root.join(root.configDirectory, "native.json")
    readonly property string compatibilityConfigFile: root.join(root.configDirectory, "config.json")
    readonly property string notificationsFile: root.join(root.configDirectory, "notifications.json")
    readonly property string stateDirectory: root.join(root.stateRoot, "raohane")
    readonly property string cacheDirectory: root.join(root.cacheRoot, "raohane")
    readonly property string coverArtDirectory: root.join(root.cacheDirectory, "media/coverart")
    readonly property string screenshotTempDirectory: "/tmp/raohane/screenshot"

    // Built-in assets are URLs because they are consumed directly by QML image
    // sources and must continue to work when the shell is installed elsewhere.
    readonly property string defaultAvatarUrl: Quickshell.shellPath("assets/images/default_avatar.svg")
    readonly property string defaultWallpaperUrl: Quickshell.shellPath("assets/images/default_wallpaper.png")
    readonly property string iconsUrl: Quickshell.shellPath("assets/icons")

    readonly property string accountsServiceAvatarPath: root.username.length > 0
        ? "/var/lib/AccountsService/icons/" + root.username
        : ""
    readonly property string userFacePath: root.join(root.home, ".face")
    readonly property string userFaceIconPath: root.join(root.home, ".face.icon")
}
