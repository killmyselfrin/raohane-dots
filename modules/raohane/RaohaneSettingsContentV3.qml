pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property int currentPage: 0
    property string pendingControl: ""
    readonly property bool compactNav: width < 860
    readonly property var pages: RaohaneSettingsPageRegistry.pages
    readonly property var currentPageInfo: root.pages[root.currentPage] ?? null
    readonly property bool pageOwnsHeader: Boolean(root.currentPageInfo?.hideHeader)

    function showPage(pageKey: string, controlKey: string): void {
        const index = RaohaneSettingsPageRegistry.resolvePageIndex(pageKey)
        if (index < 0 || index >= root.pages.length)
            return
        root.pendingControl = String(controlKey ?? "")
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
        if (root.pendingControl !== "" && typeof pageLoader.item.goTo === "function")
            pageLoader.item.goTo(root.pendingControl)
        root.pendingControl = ""
    }

    onCurrentPageChanged: {
        if (root.currentPageInfo?.key === "about" && RaohaneSystemInfo.cpu === "")
            RaohaneSystemInfo.refresh()
        Qt.callLater(root.configureLoadedPage)
    }

    Connections {
        target: RaohaneSettingsRouter

        function onPageRequested(pageKey: string, controlKey: string): void {
            root.showPage(pageKey, controlKey)
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
                if (index >= 0 && index < root.pages.length)
                    RaohaneSettingsRouter.request(root.pages[index].key, "")
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
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: !root.pageOwnsHeader
                    pageInfo: root.currentPageInfo
                    compact: root.compactNav
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

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
