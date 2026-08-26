pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

import qs.modules.raohane.services

Singleton {
    id: root

    readonly property var folderModel: RaohaneWallpapers.folderModel
    readonly property url directory: RaohaneWallpapers.directory
    readonly property string effectiveDirectory: RaohaneWallpapers.effectiveDirectory
    property string searchQuery: RaohaneWallpapers.searchQuery
    readonly property var wallpapers: RaohaneWallpapers.wallpapers
    readonly property bool thumbnailGenerationRunning: RaohaneWallpapers.thumbnailGenerationRunning
    readonly property real thumbnailGenerationProgress: RaohaneWallpapers.thumbnailGenerationProgress
    readonly property string previewPath: RaohaneWallpapers.previewPath
    readonly property string confirmedPath: RaohaneWallpapers.confirmedPath

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    onSearchQueryChanged: {
        if (RaohaneWallpapers.searchQuery !== root.searchQuery)
            RaohaneWallpapers.searchQuery = root.searchQuery
    }

    function load(): void { RaohaneWallpapers.load() }
    function startPreview(path): void { RaohaneWallpapers.startPreview(path) }
    function stopPreview(): void { RaohaneWallpapers.stopPreview() }
    function openFallbackPicker(darkMode = true, startDir = ""): void { RaohaneWallpapers.openFallbackPicker(darkMode, startDir) }
    function apply(path, darkMode = true): void { RaohaneWallpapers.apply(path, darkMode) }
    function select(filePath, darkMode = true, onFileSelected = null): void { RaohaneWallpapers.select(filePath, darkMode, onFileSelected) }
    function randomFromCurrentFolder(darkMode = true): void { RaohaneWallpapers.randomFromCurrentFolder(darkMode) }
    function getRandomWallpaperPath(excludePath = ""): string { return RaohaneWallpapers.getRandomWallpaperPath(excludePath) }
    function setDirectory(path): void { RaohaneWallpapers.setDirectory(path) }
    function navigateUp(): void { RaohaneWallpapers.navigateUp() }
    function navigateBack(): void { RaohaneWallpapers.navigateBack() }
    function navigateForward(): void { RaohaneWallpapers.navigateForward() }
    function generateThumbnail(size: string): void { RaohaneWallpapers.generateThumbnail(size) }

    Connections {
        target: RaohaneWallpapers
        function onChanged(): void { root.changed() }
        function onThumbnailGenerated(directory: string): void { root.thumbnailGenerated(directory) }
        function onThumbnailGeneratedFile(filePath: string): void { root.thumbnailGeneratedFile(filePath) }
        function onSearchQueryChanged(): void {
            if (root.searchQuery !== RaohaneWallpapers.searchQuery)
                root.searchQuery = RaohaneWallpapers.searchQuery
        }
    }

    IpcHandler {
        target: "wallpapers"
        function apply(path: string): void { RaohaneWallpapers.apply(path) }
    }
}
