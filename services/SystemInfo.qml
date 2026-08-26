pragma Singleton

import Quickshell
import qs.modules.raohane.services

Singleton {
    readonly property string distroName: RaohaneSystemInfo.distroName
    readonly property string distroId: RaohaneSystemInfo.distroId
    readonly property string distroIcon: RaohaneSystemInfo.distroIcon
    readonly property string username: RaohaneSystemInfo.username
    readonly property string hostname: RaohaneSystemInfo.hostname
    readonly property string homeUrl: RaohaneSystemInfo.homeUrl
    readonly property string documentationUrl: RaohaneSystemInfo.documentationUrl
    readonly property string supportUrl: RaohaneSystemInfo.supportUrl
    readonly property string bugReportUrl: RaohaneSystemInfo.bugReportUrl
    readonly property string privacyPolicyUrl: RaohaneSystemInfo.privacyPolicyUrl
    readonly property string logo: RaohaneSystemInfo.logo
    readonly property string desktopEnvironment: RaohaneSystemInfo.desktopEnvironment
    readonly property string windowingSystem: RaohaneSystemInfo.windowingSystem
    readonly property string cpu: RaohaneSystemInfo.cpu
    readonly property string gpu: RaohaneSystemInfo.gpu
    readonly property string memory: RaohaneSystemInfo.memory
    readonly property string disk: RaohaneSystemInfo.disk
    readonly property string shell: RaohaneSystemInfo.shell
    readonly property string packages: RaohaneSystemInfo.packages
    readonly property string installAge: RaohaneSystemInfo.installAge
    readonly property string kernelVersion: RaohaneSystemInfo.kernelVersion

    function refresh(): void { RaohaneSystemInfo.refresh() }
    function refreshHostname(): void { RaohaneSystemInfo.refreshHostname() }
}
