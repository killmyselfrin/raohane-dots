pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "arch-symbolic"
    property string username: "user"
    property string hostname: ""
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string logo: ""
    property string desktopEnvironment: "Hyprland"
    property string windowingSystem: "Wayland"
    property string cpu: ""
    property string gpu: ""
    property string memory: ""
    property string disk: ""
    property string shell: ""
    property string packages: ""
    property string installAge: ""
    property string kernelVersion: ""
    property double lastRefreshMs: 0

    readonly property int minimumRefreshInterval: 30000

    function refresh(force): void {
        if (systemProbe.running)
            return

        const forced = force === true
        const now = Date.now()
        if (!forced && root.lastRefreshMs > 0
                && now - root.lastRefreshMs < root.minimumRefreshInterval)
            return

        root.lastRefreshMs = now
        systemProbe.running = true
    }

    function refreshHostname(): void {
        if (!hostnameProbe.running)
            hostnameProbe.running = true
    }

    function applySnapshot(text: string): void {
        for (const rawLine of String(text ?? "").split("\n")) {
            const tab = rawLine.indexOf("\t")
            if (tab <= 0)
                continue
            const key = rawLine.slice(0, tab)
            const value = rawLine.slice(tab + 1).trim()
            switch (key) {
            case "CPU": root.cpu = value; break
            case "GPU": root.gpu = value; break
            case "MEMORY": root.memory = value; break
            case "DISK": root.disk = value; break
            case "SHELL": root.shell = value; break
            case "PACKAGES": root.packages = value; break
            case "INSTALL_AGE": root.installAge = value; break
            case "KERNEL": root.kernelVersion = value; break
            }
        }
    }

    function readOsRelease(): void {
        const text = osRelease.text()
        const prettyName = text.match(/^PRETTY_NAME="?(.+?)"?$/m)
        const name = text.match(/^NAME="?(.+?)"?$/m)
        const id = text.match(/^ID="?(.+?)"?$/m)
        const home = text.match(/^HOME_URL="?(.+?)"?$/m)
        const documentation = text.match(/^DOCUMENTATION_URL="?(.+?)"?$/m)
        const support = text.match(/^SUPPORT_URL="?(.+?)"?$/m)
        const bugs = text.match(/^BUG_REPORT_URL="?(.+?)"?$/m)
        const privacy = text.match(/^PRIVACY_POLICY_URL="?(.+?)"?$/m)
        const logoField = text.match(/^LOGO="?(.+?)"?$/m)

        root.distroName = prettyName ? prettyName[1] : (name ? name[1] : "Unknown")
        root.distroId = id ? id[1].toLowerCase() : "unknown"
        root.homeUrl = home ? home[1] : ""
        root.documentationUrl = documentation ? documentation[1] : ""
        root.supportUrl = support ? support[1] : ""
        root.bugReportUrl = bugs ? bugs[1] : ""
        root.privacyPolicyUrl = privacy ? privacy[1] : ""
        root.logo = logoField ? logoField[1] : ""

        switch (root.distroId) {
        case "arch":
        case "artix": root.distroIcon = "arch-symbolic"; break
        case "endeavouros": root.distroIcon = "endeavouros-symbolic"; break
        case "cachyos": root.distroIcon = "cachyos-symbolic"; break
        case "nixos": root.distroIcon = "nixos-symbolic"; break
        case "fedora": root.distroIcon = "fedora-symbolic"; break
        case "ubuntu":
        case "linuxmint":
        case "popos": root.distroIcon = "ubuntu-symbolic"; break
        case "debian":
        case "kali": root.distroIcon = "debian-symbolic"; break
        case "gentoo": root.distroIcon = "gentoo-symbolic"; break
        default: root.distroIcon = "arch-symbolic"; break
        }

        if (root.logo.length === 0)
            root.logo = root.distroIcon
    }

    FileView {
        id: osRelease
        path: "/etc/os-release"
        onLoaded: root.readOsRelease()
    }

    Process {
        id: usernameProbe
        running: true
        command: ["id", "-un"]
        stdout: SplitParser { onRead: data => root.username = data.trim() }
    }

    Process {
        id: hostnameProbe
        running: true
        command: ["hostname"]
        stdout: SplitParser { onRead: data => root.hostname = data.trim() }
    }

    // Static/about information is collected in one shell transaction instead
    // of spawning eight concurrent processes whenever About requests a refresh.
    // It intentionally uses a non-login shell: no user profile initialization
    // is needed for this deterministic system snapshot.
    Process {
        id: systemProbe
        command: [
            "bash", "-c",
            "cpu=$(awk -F: '/model name/ {gsub(/^ +/, \"\", $2); print $2; exit}' /proc/cpuinfo); "
                + "gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | head -1 | sed -E 's/^[^:]+: //; s/ \\(rev [^)]+\\)//; s/NVIDIA Corporation //; s/Advanced Micro Devices, Inc. \\[AMD\\/ATI\\] //; s/Intel Corporation //'); "
                + "memory=$(LC_ALL=C free -h | awk '/^Mem:/ {print $3 \" / \" $2}'); "
                + "disk=$(df -h / | awk 'NR==2 {print $3 \" / \" $2}'); "
                + "shell=$(basename \"${SHELL:-bash}\"); "
                + "pacman_count=$(pacman -Q 2>/dev/null | wc -l); "
                + "flatpak_count=$(flatpak list 2>/dev/null | wc -l || true); "
                + "if [ \"${flatpak_count:-0}\" -gt 0 ]; then packages=\"$pacman_count pacman, $flatpak_count flatpak\"; else packages=\"$pacman_count pacman\"; fi; "
                + "birth=$(stat -c %W / 2>/dev/null || echo 0); [ \"$birth\" -gt 0 ] || birth=$(stat -c %Y /); install_age=$((($(date +%s) - birth) / 86400)); "
                + "kernel=$(uname -r); "
                + "printf 'CPU\\t%s\\nGPU\\t%s\\nMEMORY\\t%s\\nDISK\\t%s\\nSHELL\\t%s\\nPACKAGES\\t%s\\nINSTALL_AGE\\t%s days\\nKERNEL\\t%s\\n' \"$cpu\" \"$gpu\" \"$memory\" \"$disk\" \"$shell\" \"$packages\" \"$install_age\" \"$kernel\""
        ]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applySnapshot(text)
        }
    }

    Component.onCompleted: {
        osRelease.reload()
        root.refresh(true)
    }
}
