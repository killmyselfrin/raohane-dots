pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell

Singleton {
    function trimFileProtocol(value): string {
        const str = String(value ?? "")
        return str.startsWith("file://") ? str.slice(7) : str
    }

    // XDG Dirs, with "file://"
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
    readonly property string username: Quickshell.env("USER") ?? Quickshell.env("LOGNAME") ?? ""

    // Other dirs used by the shell, without "file://"
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string favicons: trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt: trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string tempImages: "/tmp/quickshell/media/images"
    property string booruPreviews: trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: trimFileProtocol(`${Directories.cache}/media/latex`)

    // Raohane owns its runtime namespace. The installer performs a one-time
    // migration from ~/.config/illogical-impulse when that legacy config exists.
    property string shellConfig: trimFileProtocol(`${Directories.config}/raohane`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`

    property string todoPath: trimFileProtocol(`${Directories.state}/user/todo.json`)
    property string notesPath: trimFileProtocol(`${Directories.state}/user/notes.txt`)
    property string desktopNotesPath: trimFileProtocol(`${Directories.state}/user/desktopnotes.txt`)
    property string conflictCachePath: trimFileProtocol(`${Directories.cache}/conflict-killer`)
    property string notificationsPath: trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath: trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string generatedWallpaperCategoryPath: trimFileProtocol(`${Directories.state}/user/generated/wallpaper/category.txt`)
    property string cliphistDecode: trimFileProtocol(`/tmp/quickshell/media/cliphist`)
    property string screenshotTemp: "/tmp/quickshell/media/screenshot"
    property string wallpaperSwitchScriptPath: trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts: Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts: trimFileProtocol(`${Directories.shellConfig}/ai/prompts`)
    property string userActions: trimFileProtocol(`${Directories.shellConfig}/actions`)
    property string aiChats: trimFileProtocol(`${Directories.state}/user/ai/chats`)
    property string aiTranslationScriptPath: trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath: trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: trimFileProtocol(`/var/lib/AccountsService/icons/${Directories.username}`)
    property string userAvatarPathRicersAndWeirdSystems: trimFileProtocol(`${Directories.home}/.face`)
    property string userAvatarPathRicersAndWeirdSystems2: trimFileProtocol(`${Directories.home}/.face.icon`)
    property string userPresetsPath: trimFileProtocol(`${Directories.shellConfig}/presets`)
    property string presetsScriptPath: trimFileProtocol(`${Directories.scriptPath}/presets.sh`)
    property string generatedLockMaterialThemePath: trimFileProtocol(`${Directories.state}/user/generated/colors-lock.json`)

    // Cleanup on init
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${userPresetsPath}`])
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
        Quickshell.execDetached(["mkdir", "-p", `${favicons}`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`])
        Quickshell.execDetached(["mkdir", "-p", `${aiChats}`])
        Quickshell.execDetached(["mkdir", "-p", `${userActions}`])
        Quickshell.execDetached(["rm", "-rf", `${tempImages}`])
    }
}
