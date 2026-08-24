pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

Singleton {
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

    // Raohane-owned runtime roots, without "file://".
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/raohane`)
    property string shellState: FileUtils.trimFileProtocol(`${Directories.state}/raohane`)
    property string shellCache: FileUtils.trimFileProtocol(`${Directories.cache}/raohane`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`

    property string favicons: `${Directories.shellCache}/media/favicons`
    property string coverArt: `${Directories.shellCache}/media/coverart`
    property string tempImages: "/tmp/raohane/media/images"
    property string booruPreviews: `${Directories.shellCache}/media/boorus`
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: `${Directories.shellCache}/media/latex`
    property string todoPath: `${Directories.shellState}/user/todo.json`
    property string notesPath: `${Directories.shellState}/user/notes.txt`
    property string desktopNotesPath: `${Directories.shellState}/user/desktopnotes.txt`
    property string conflictCachePath: `${Directories.shellCache}/conflict-killer`
    property string notificationsPath: `${Directories.shellCache}/notifications/notifications.json`
    property string generatedMaterialThemePath: `${Directories.shellState}/user/generated/colors.json`
    property string generatedWallpaperCategoryPath: `${Directories.shellState}/user/generated/wallpaper/category.txt`
    property string cliphistDecode: "/tmp/raohane/media/cliphist"
    property string screenshotTemp: "/tmp/raohane/media/screenshot"
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts: Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts: `${Directories.shellConfig}/ai/prompts`
    property string userActions: `${Directories.shellConfig}/actions`
    property string aiChats: `${Directories.shellState}/user/ai/chats`
    property string aiTranslationScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${SystemInfo.username}`)
    property string userAvatarPathRicersAndWeirdSystems: FileUtils.trimFileProtocol(`${Directories.home}.face`)
    property string userAvatarPathRicersAndWeirdSystems2: FileUtils.trimFileProtocol(`${Directories.home}.face.icon`)
    property string userPresetsPath: `${Directories.shellConfig}/presets`
    property string presetsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/presets.sh`)
    property string generatedLockMaterialThemePath: `${Directories.shellState}/user/generated/colors-lock.json`

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${userPresetsPath}`])
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
        Quickshell.execDetached(["mkdir", "-p", `${shellState}`])
        Quickshell.execDetached(["mkdir", "-p", `${shellCache}`])
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
