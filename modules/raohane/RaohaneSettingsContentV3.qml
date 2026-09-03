pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property int currentPage: 0
    property string pendingSearch: ""
    property bool pageEntered: true
    readonly property bool compactNav: width < 860
    readonly property var pages: RaohaneSettingsPageRegistry.pages
    readonly property var currentPageInfo: root.pages[root.currentPage] ?? null

    function resolvePageIndex(requestedValue: string): int {
        return RaohaneSettingsPageRegistry.resolvePageIndex(requestedValue)
    }

    function activatePage(index: int): void {
        if (index < 0 || index >= root.pages.length)
            return
        const page = root.pages[index]
        if (page?.externalSurface) {
            RaohaneState.setPrimaryOpen(page.externalSurface, true)
            root.pendingSearch = ""
            return
        }
        if (root.currentPage === index) {
            Qt.callLater(root.configureLoadedPage)
            return
        }
        root.currentPage = index
    }

    function configureLoadedPage(): void {
        const page = root.currentPageInfo
        if (!pageLoader.item || !page)
            return
        if (pageLoader.item.hasOwnProperty("sectionKey"))
            pageLoader.item.sectionKey = page.key
        if (root.pendingSearch !== "" && typeof pageLoader.item.goTo === "function")
            pageLoader.item.goTo(root.pendingSearch)
        root.pendingSearch = ""
    }

    onCurrentPageChanged: {
        root.pageEntered = false
        pageReveal.restart()
        if (root.currentPageInfo?.key === "about" && RaohaneSystemInfo.cpu === "")
            RaohaneSystemInfo.refresh()
        Qt.callLater(root.configureLoadedPage)
    }

    Timer {
        id: pageReveal
        interval: 35
        onTriggered: root.pageEntered = true
    }

    Connections {
        target: RaohaneState

        function onSettingsPageChanged(): void {
            if (RaohaneState.settingsPage === "")
                return

            const parts = RaohaneState.settingsPage.split(":")
            const requested = parts[0]
            root.pendingSearch = parts.length > 1 ? parts.slice(1).join(":") : ""
            const index = root.resolvePageIndex(requested)
            if (index >= 0)
                root.activatePage(index)
            RaohaneState.settingsPage = ""
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        RaohaneSettingsNavigation {
            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth
            pages: root.pages
            currentPage: root.currentPage
            compact: root.compactNav
            onPageRequested: index => {
                root.pendingSearch = ""
                root.activatePage(index)
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: RaohaneTheme.borderFaint
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RaohaneSettingsPageHeader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    pageInfo: root.currentPageInfo
                    compact: root.compactNav
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    opacity: root.pageEntered ? 1 : 0
                    transform: Translate { y: root.pageEntered ? 0 : 6 }

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                    }

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 10
                        source: root.currentPageInfo?.source ?? ""
                        onLoaded: Qt.callLater(root.configureLoadedPage)
                    }
                }
            }
        }
    }
}
