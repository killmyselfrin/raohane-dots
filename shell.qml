//@ pragma ShellId raohane
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import qs.modules.raohane

ShellRoot {
    RaohaneBar {
        id: bar
    }

    IpcHandler {
        target: "contextIsland"

        function clear(): void { RaohaneContext.clear() }
        function recording(active: bool): void { RaohaneContext.recording = active }
        function microphone(active: bool): void { RaohaneContext.microphone = active }
        function camera(active: bool): void { RaohaneContext.camera = active }
        function media(title: string, artist: string): void {
            RaohaneContext.mediaTitle = title
            RaohaneContext.mediaArtist = artist
            RaohaneContext.mediaActive = title.length > 0
        }
        function window(title: string): void { RaohaneContext.windowTitle = title }
        function event(title: string, detail: string): void {
            RaohaneContext.showEvent(title, detail)
        }
        function status(): string { return RaohaneContext.statusJson() }
    }
}
