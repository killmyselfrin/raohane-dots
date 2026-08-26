pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool packageManagerRunning: false
    property bool downloadRunning: false

    function refresh(): void {
        packageProbe.running = false
        downloadProbe.running = false
        packageProbe.running = true
        downloadProbe.running = true
    }

    Process {
        id: packageProbe
        command: ["bash", "-lc", "pidof pacman yay paru pikaur trizen >/dev/null 2>&1 || test -e /var/lib/pacman/db.lck"]
        onExited: (exitCode, exitStatus) => root.packageManagerRunning = exitCode === 0
    }

    Process {
        id: downloadProbe
        command: ["bash", "-lc", "pidof curl wget aria2c yt-dlp >/dev/null 2>&1 || find \"${HOME:-$HOME}/Downloads\" -maxdepth 1 -type f \\( -name '*.crdownload' -o -name '*.part' -o -name '*.download' \\) -print -quit 2>/dev/null | grep -q ."]
        onExited: (exitCode, exitStatus) => root.downloadRunning = exitCode === 0
    }
}
