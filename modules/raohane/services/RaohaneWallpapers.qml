pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.modules.raohane.config

Singleton {
    id: root

    readonly property string picturesPath: root.cleanPath(StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] ?? "")
    readonly property string fallbackFolderPath: picturesPath.length > 0 ? `${picturesPath}/Wallpapers` : ""
    readonly property string defaultFolderPath: RaohaneConfig.wallpaperDirectory.length > 0
        ? RaohaneConfig.wallpaperDirectory
        : root.fallbackFolderPath
    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: root.cleanPath(folderModel.folder.toString())
    property alias folderModel: folderModel
    property string searchQuery: ""
    readonly property list<string> extensions: [
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg",
        "mp4", "webm", "mkv", "mov", "avi"
    ]
    property list<string> wallpapers: []
    property string previewPath: ""
    property string confirmedPath: RaohaneConfig.wallpaperPath

    property list<url> folderHistory: []
    property int currentFolderHistoryIndex: -1
    property bool historyNavigationLock: false

    readonly property string thumbgenScriptPath: Quickshell.shellPath("scripts/thumbnails/thumbgen.sh")
    readonly property string magickThumbnailScriptPath: Quickshell.shellPath("scripts/thumbnails/generate-thumbnails-magick.sh")
    readonly property bool thumbnailGenerationRunning: thumbnailProcess.running
    property real thumbnailGenerationProgress: 0

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load(): void {}

    function cleanPath(value): string {
        if (value === null || value === undefined)
            return ""
        let path = value.toString()
        if (path.startsWith("file://"))
            path = path.substring(7)
        try {
            return decodeURIComponent(path)
        } catch (error) {
            return path
        }
    }

    function parentDirectory(path: string): string {
        const clean = root.cleanPath(path).replace(/\/+$/, "")
        if (clean.length === 0 || clean === "/")
            return "/"
        const index = clean.lastIndexOf("/")
        return index <= 0 ? "/" : clean.substring(0, index)
    }

    function startPreview(path: string): void {
        const clean = root.cleanPath(path)
        if (clean.length > 0)
            root.previewPath = clean
    }

    function stopPreview(): void {
        root.previewPath = ""
    }

    function apply(path: string, darkMode = true): void {
        const clean = root.cleanPath(path)
        if (clean.length === 0)
            return

        root.confirmedPath = clean
        RaohaneConfig.wallpaperPath = clean
        root.changed()
    }

    function select(filePath: string, darkMode = true, onFileSelected = null): void {
        const clean = root.cleanPath(filePath)
        if (clean.length === 0)
            return

        selectProbe.filePath = clean
        selectProbe.darkMode = darkMode
        selectProbe.onFileSelected = onFileSelected
        selectProbe.exec(["test", "-d", clean])
    }

    function randomFromCurrentFolder(darkMode = true): void {
        if (root.wallpapers.length === 0)
            return
        const path = root.wallpapers[Math.floor(Math.random() * root.wallpapers.length)]
        root.apply(path, darkMode)
    }

    function getRandomWallpaperPath(excludePath = ""): string {
        const excluded = root.cleanPath(excludePath)
        const candidates = root.wallpapers.filter(path => path !== excluded)
        if (candidates.length === 0)
            return ""
        return candidates[Math.floor(Math.random() * candidates.length)]
    }

    function setDirectory(path): void {
        const clean = root.cleanPath(path).replace(/\/+$/, "") || "/"
        directoryProbe.pathToCheck = clean
        directoryProbe.exec(["test", "-d", clean])
    }

    function pushHistory(path): void {
        const resolved = path.toString()
        if (root.folderHistory[root.currentFolderHistoryIndex]?.toString() === resolved)
            return
        root.folderHistory = root.folderHistory.slice(0, root.currentFolderHistoryIndex + 1)
        root.folderHistory.push(path)
        root.currentFolderHistoryIndex = root.folderHistory.length - 1
    }

    function navigateUp(): void {
        if (folderModel.parentFolder)
            folderModel.folder = folderModel.parentFolder
    }

    function navigateBack(): void {
        if (root.currentFolderHistoryIndex <= 0)
            return
        root.currentFolderHistoryIndex--
        root.historyNavigationLock = true
        folderModel.folder = root.folderHistory[root.currentFolderHistoryIndex]
    }

    function navigateForward(): void {
        if (root.currentFolderHistoryIndex >= root.folderHistory.length - 1)
            return
        root.currentFolderHistoryIndex++
        root.historyNavigationLock = true
        folderModel.folder = root.folderHistory[root.currentFolderHistoryIndex]
    }

    function openFallbackPicker(darkMode = true, startDir = ""): void {
        filePicker.darkMode = darkMode
        const cleanStart = root.cleanPath(startDir)
        if (cleanStart.length > 0)
            filePicker.currentFolder = Qt.resolvedUrl(cleanStart)
        filePicker.open()
    }

    function generateThumbnail(size: string): void {
        if (!["normal", "large", "x-large", "xx-large"].includes(size))
            throw new Error("Invalid thumbnail size")
        if (root.effectiveDirectory.length === 0)
            return

        thumbnailProcess.directory = root.effectiveDirectory
        root.thumbnailGenerationProgress = 0
        thumbnailProcess.command = [
            "bash", "-c",
            `\"${root.thumbgenScriptPath}\" --size ${size} --machine_progress -d \"${root.effectiveDirectory}\" || \"${root.magickThumbnailScriptPath}\" --size ${size} -d \"${root.effectiveDirectory}\"`
        ]
        thumbnailProcess.running = true
    }

    Process {
        id: directoryProbe
        property string pathToCheck: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                folderModel.folder = Qt.resolvedUrl(directoryProbe.pathToCheck)
                RaohaneConfig.wallpaperDirectory = directoryProbe.pathToCheck
            }
        }
    }

    Process {
        id: selectProbe
        property string filePath: ""
        property bool darkMode: true
        property var onFileSelected: null

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.setDirectory(selectProbe.filePath)
                return
            }

            if (selectProbe.onFileSelected)
                selectProbe.onFileSelected(selectProbe.filePath)
            else
                root.apply(selectProbe.filePath, selectProbe.darkMode)
        }
    }

    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolderPath)
        caseSensitive: false
        nameFilters: root.extensions.map(extension => {
            const query = root.searchQuery.trim().replace(/\s+/g, "*")
            return query.length > 0 ? `*${query}*.${extension}` : `*.${extension}`
        })
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false

        onFolderChanged: {
            if (root.historyNavigationLock) {
                root.historyNavigationLock = false
            } else {
                root.pushHistory(folder)
            }
            const clean = root.cleanPath(folder.toString())
            if (clean.length > 0 && clean !== RaohaneConfig.wallpaperDirectory)
                RaohaneConfig.wallpaperDirectory = clean
        }

        onCountChanged: root.rebuildWallpaperList()
    }

    function rebuildWallpaperList(): void {
        const next = []
        for (let index = 0; index < folderModel.count; index++) {
            if (folderModel.get(index, "fileIsDir"))
                continue
            const path = root.cleanPath(folderModel.get(index, "filePath") || folderModel.get(index, "fileURL"))
            if (path.length > 0)
                next.push(path)
        }
        root.wallpapers = next
    }

    FileDialog {
        id: filePicker
        property bool darkMode: true
        title: qsTr("Choose a wallpaper")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            qsTr("Wallpapers (*.jpg *.jpeg *.png *.webp *.avif *.bmp *.svg *.mp4 *.webm *.mkv *.mov *.avi)"),
            qsTr("Images (*.jpg *.jpeg *.png *.webp *.avif *.bmp *.svg)"),
            qsTr("Videos (*.mp4 *.webm *.mkv *.mov *.avi)"),
            qsTr("All files (*)")
        ]
        onAccepted: root.apply(selectedFile.toString(), darkMode)
    }

    Process {
        id: thumbnailProcess
        property string directory: ""

        stdout: SplitParser {
            onRead: data => {
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) {
                    const completed = Number(match[1])
                    const total = Number(match[2])
                    root.thumbnailGenerationProgress = total > 0 ? completed / total : 0
                }
                match = data.match(/FILE (.+)/)
                if (match)
                    root.thumbnailGeneratedFile(match[1])
            }
        }

        onExited: (exitCode, exitStatus) => root.thumbnailGenerated(thumbnailProcess.directory)
    }

    Connections {
        target: RaohaneConfig
        function onWallpaperPathChanged(): void {
            root.confirmedPath = RaohaneConfig.wallpaperPath
        }
        function onWallpaperDirectoryChanged(): void {
            const configured = RaohaneConfig.wallpaperDirectory
            if (configured.length > 0 && root.cleanPath(folderModel.folder.toString()) !== configured)
                root.setDirectory(configured)
        }
    }

    IpcHandler {
        target: "raohaneWallpapers"

        function apply(path: string): void { root.apply(path) }
        function random(): void { root.randomFromCurrentFolder() }
    }

    Component.onCompleted: {
        root.folderHistory = [folderModel.folder]
        root.currentFolderHistoryIndex = 0
        root.rebuildWallpaperList()
    }
}
