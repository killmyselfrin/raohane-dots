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

    function refresh(): void {
        cpuProbe.running = false
        gpuProbe.running = false
        memoryProbe.running = false
        diskProbe.running = false
        shellProbe.running = false
        packageProbe.running = false
        installAgeProbe.running = false
        kernelProbe.running = false

        cpuProbe.running = true
        gpuProbe.running = true
        memoryProbe.running = true
        diskProbe.running = true
        shellProbe.running = true
        packageProbe.running = true
        installAgeProbe.running = true
        kernelProbe.running = true
    }

    function refreshHostname(): void {
        hostnameProbe.running = false
        hostnameProbe.running = true
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

    Process {
        id: cpuProbe
        command: ["bash", "-lc", "awk -F: '/model name/ {gsub(/^ +/, \"\", $2); print $2; exit}' /proc/cpuinfo"]
        stdout: SplitParser { onRead: data => root.cpu = data.trim() }
    }

    Process {
        id: gpuProbe
        command: ["bash", "-lc", "lspci 2>/dev/null | grep -Ei 'vga|3d|display' | head -1 | sed -E 's/^[^:]+: //; s/ \\(rev [^)]+\\)//; s/NVIDIA Corporation //; s/Advanced Micro Devices, Inc. \\[AMD\\/ATI\\] //; s/Intel Corporation //' "]
        stdout: SplitParser { onRead: data => root.gpu = data.trim() }
    }

    Process {
        id: memoryProbe
        command: ["bash", "-lc", "LC_ALL=C free -h | awk '/^Mem:/ {print $3 \" / \" $2}'"]
        stdout: SplitParser { onRead: data => root.memory = data.trim() }
    }

    Process {
        id: diskProbe
        command: ["bash", "-lc", "df -h / | awk 'NR==2 {print $3 \" / \" $2}'"]
        stdout: SplitParser { onRead: data => root.disk = data.trim() }
    }

    Process {
        id: shellProbe
        command: ["bash", "-lc", "basename \"${SHELL:-bash}\""]
        stdout: SplitParser { onRead: data => root.shell = data.trim() }
    }

    Process {
        id: packageProbe
        command: ["bash", "-lc", "pacman_count=$(pacman -Q 2>/dev/null | wc -l); flatpak_count=$(flatpak list 2>/dev/null | wc -l || true); if [ \"${flatpak_count:-0}\" -gt 0 ]; then printf '%s pacman, %s flatpak\\n' \"$pacman_count\" \"$flatpak_count\"; else printf '%s pacman\\n' \"$pacman_count\"; fi"]
        stdout: SplitParser { onRead: data => root.packages = data.trim() }
    }

    Process {
        id: installAgeProbe
        command: ["bash", "-lc", "birth=$(stat -c %W / 2>/dev/null || echo 0); if [ \"$birth\" -le 0 ]; then birth=$(stat -c %Y /); fi; echo $((($(date +%s) - birth) / 86400)) days"]
        stdout: SplitParser { onRead: data => root.installAge = data.trim() }
    }

    Process {
        id: kernelProbe
        command: ["uname", "-r"]
        stdout: SplitParser { onRead: data => root.kernelVersion = data.trim() }
    }

    Component.onCompleted: {
        osRelease.reload()
        root.refresh()
    }
}
