pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell

Singleton {
    id: root

    property bool loading: false
    property bool instrumental: false
    property string plainLyrics: ""
    property var lines: []
    property string errorText: ""
    property string providerName: "LRCLIB"
    property int requestSerial: 0
    property var cache: ({})
    property var activeRequest: null

    readonly property bool syncedAvailable: lines.length > 0
    readonly property bool available: instrumental || syncedAvailable || plainLyrics.trim().length > 0
    readonly property int currentLineIndex: root.findCurrentLine(RaohaneMedia.position)
    readonly property var displayLines: syncedAvailable ? lines : root.makePlainLines(plainLyrics)

    function clear(): void {
        requestWatchdog.stop()
        if (root.activeRequest) {
            try { root.activeRequest.abort() } catch (error) {}
        }
        root.activeRequest = null
        root.loading = false
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = ""
    }

    function compactSpaces(value: string): string {
        return String(value ?? "").replace(/\s+/g, " ").trim()
    }

    function stripDecorators(value: string): string {
        return root.compactSpaces(String(value ?? "")
            .replace(/\s*[\[(](official\s+)?(audio|video|music\s+video|visuali[sz]er|lyrics?|lyric\s+video)[^\])]*[\])]/gi, "")
            .replace(/\s*[|·•]\s*(official\s+)?(audio|video|lyrics?|visuali[sz]er).*$/gi, ""))
    }

    function cleanArtist(value: string): string {
        return root.compactSpaces(root.stripDecorators(value)
            .replace(/\s*[-–—]\s*topic\s*$/i, "")
            .replace(/\s*[-–—]\s*vevo\s*$/i, "")
            .replace(/\s+topic\s*$/i, ""))
    }

    function cleanTitle(value: string): string {
        return root.stripDecorators(value)
    }

    function cleanAlbum(value: string): string {
        return root.stripDecorators(value)
    }

    function comparable(value: string): string {
        return root.compactSpaces(String(value ?? "")
            .toLowerCase()
            .replace(/[’‘`]/g, "'")
            .replace(/[^\p{L}\p{N}]+/gu, " "))
    }

    function metadata(): var {
        return {
            rawArtist: root.compactSpaces(RaohaneMedia.artist),
            rawTitle: root.compactSpaces(RaohaneMedia.title),
            rawAlbum: root.compactSpaces(RaohaneMedia.album),
            artist: root.cleanArtist(RaohaneMedia.artist),
            title: root.cleanTitle(RaohaneMedia.title),
            album: root.cleanAlbum(RaohaneMedia.album),
            duration: Math.round(Number(RaohaneMedia.length) || 0)
        }
    }

    function trackKey(): string {
        const meta = root.metadata()
        return [
            root.comparable(meta.artist),
            root.comparable(meta.title),
            root.comparable(meta.album),
            meta.duration
        ].join("|")
    }

    function scheduleLookup(): void {
        lookupTimer.restart()
    }

    function forceRefresh(): void {
        const key = root.trackKey()
        if (Object.prototype.hasOwnProperty.call(root.cache, key))
            delete root.cache[key]
        root.lookup()
    }

    function lookup(): void {
        const meta = root.metadata()

        root.requestSerial += 1
        const serial = root.requestSerial

        if (!RaohaneMedia.available || meta.artist.length === 0 || meta.title.length === 0) {
            root.clear()
            return
        }

        const key = root.trackKey()
        const cached = root.cache[key]
        if (cached) {
            root.applyRecord(cached, key)
            return
        }

        root.loading = true
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = ""

        // Start with the metadata exactly as the player published it. Browser
        // MPRIS often adds channel suffixes such as "- Topic", so a miss is
        // followed by normalized structured and keyword searches.
        root.requestExact(serial, key, meta.rawArtist, meta.rawTitle, meta.rawAlbum, meta.duration, () => {
            root.requestNormalizedSearch(serial, key, meta)
        })
    }

    function requestExact(serial: int, key: string, artist: string, title: string, album: string, duration: int, onMiss): void {
        if (serial !== root.requestSerial)
            return

        const params = [
            "artist_name=" + encodeURIComponent(artist),
            "track_name=" + encodeURIComponent(title)
        ]
        if (album.length > 0)
            params.push("album_name=" + encodeURIComponent(album))
        if (duration >= 1 && duration <= 3600)
            params.push("duration=" + duration)

        root.getJson(
            "https://lrclib.net/api/get?" + params.join("&"),
            serial,
            record => root.applyRecord(record, key),
            onMiss
        )
    }

    function requestNormalizedSearch(serial: int, key: string, meta): void {
        if (serial !== root.requestSerial)
            return

        const params = [
            "track_name=" + encodeURIComponent(meta.title),
            "artist_name=" + encodeURIComponent(meta.artist)
        ]
        if (meta.album.length > 0)
            params.push("album_name=" + encodeURIComponent(meta.album))

        root.getJson(
            "https://lrclib.net/api/search?" + params.join("&"),
            serial,
            records => {
                if (root.applyBestSearchRecord(records, key, meta))
                    return
                root.requestLooseSearch(serial, key, meta)
            },
            () => root.requestLooseSearch(serial, key, meta)
        )
    }

    function requestLooseSearch(serial: int, key: string, meta): void {
        if (serial !== root.requestSerial)
            return

        const query = root.compactSpaces(meta.artist + " " + meta.title)
        root.getJson(
            "https://lrclib.net/api/search?q=" + encodeURIComponent(query),
            serial,
            records => {
                if (!root.applyBestSearchRecord(records, key, meta))
                    root.finishNotFound(serial)
            },
            () => root.finishNotFound(serial)
        )
    }

    function applyBestSearchRecord(records, key: string, meta): bool {
        if (!Array.isArray(records) || records.length === 0)
            return false
        const best = root.chooseBestRecord(records, meta)
        if (!best)
            return false
        root.applyRecord(best, key)
        return true
    }

    function getJson(url: string, serial: int, onSuccess, onNotFound): void {
        if (serial !== root.requestSerial)
            return

        if (root.activeRequest) {
            try { root.activeRequest.abort() } catch (error) {}
        }

        const request = new XMLHttpRequest()
        root.activeRequest = request
        request.open("GET", url)
        request.setRequestHeader("Accept", "application/json")
        request.setRequestHeader("Lrclib-Client", "Raohane/0.10.0-dev (https://github.com/killmyselfrin/raohane-dots)")
        request.onreadystatechange = function() {
            if (request.readyState !== 4 || serial !== root.requestSerial)
                return

            requestWatchdog.stop()
            if (root.activeRequest === request)
                root.activeRequest = null

            if (request.status === 200) {
                try {
                    onSuccess(JSON.parse(request.responseText))
                } catch (error) {
                    root.loading = false
                    root.errorText = qsTr("Lyrics response could not be read")
                }
                return
            }

            if (request.status === 404 || request.status === 400) {
                onNotFound()
                return
            }

            root.loading = false
            root.errorText = request.status === 429
                ? qsTr("Lyrics service is busy. Try again shortly.")
                : qsTr("Could not load lyrics (HTTP %1)").arg(request.status)
        }
        requestWatchdog.restart()
        request.send()
    }

    function chooseBestRecord(records, meta): var {
        const wantedTitle = root.comparable(meta.title)
        const wantedArtist = root.comparable(meta.artist)
        const wantedAlbum = root.comparable(meta.album)
        const wantedDuration = Number(meta.duration) || 0

        let best = null
        let bestScore = Number.POSITIVE_INFINITY
        for (const record of records) {
            const recordTitle = root.comparable(record.trackName ?? record.name ?? "")
            const recordArtist = root.comparable(root.cleanArtist(record.artistName ?? ""))
            const recordAlbum = root.comparable(record.albumName ?? "")
            const recordDuration = Number(record.duration) || 0
            let score = 0

            if (recordTitle === wantedTitle)
                score -= 120
            else if (recordTitle.includes(wantedTitle) || wantedTitle.includes(recordTitle))
                score -= 45
            else
                score += 100

            if (recordArtist === wantedArtist)
                score -= 120
            else if (recordArtist.includes(wantedArtist) || wantedArtist.includes(recordArtist))
                score -= 35
            else
                score += 100

            if (wantedAlbum.length > 0) {
                if (recordAlbum === wantedAlbum)
                    score -= 24
                else if (recordAlbum.length > 0)
                    score += 10
            }

            if (wantedDuration > 0 && recordDuration > 0) {
                const durationDiff = Math.abs(wantedDuration - recordDuration)
                score += durationDiff <= 2 ? -30 : Math.min(90, durationDiff * 3)
            }

            const hasLyrics = Boolean(record.instrumental)
                || String(record.syncedLyrics ?? "").trim().length > 0
                || String(record.plainLyrics ?? "").trim().length > 0
            if (!hasLyrics)
                score += 200

            if (score < bestScore) {
                bestScore = score
                best = record
            }
        }

        // Do not accept a random same-title result from a loose query.
        return bestScore <= 80 ? best : null
    }

    function applyRecord(record, key: string): void {
        if (!record) {
            root.finishNotFound(root.requestSerial)
            return
        }

        const compact = {
            instrumental: Boolean(record.instrumental),
            plainLyrics: String(record.plainLyrics ?? ""),
            syncedLyrics: String(record.syncedLyrics ?? "")
        }
        root.cache[key] = compact
        root.instrumental = compact.instrumental
        root.plainLyrics = compact.plainLyrics
        root.lines = root.parseSyncedLyrics(compact.syncedLyrics)
        root.loading = false
        root.errorText = ""
    }

    function finishNotFound(serial: int): void {
        if (serial !== root.requestSerial)
            return
        requestWatchdog.stop()
        root.activeRequest = null
        root.loading = false
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = qsTr("Lyrics were not found for this track")
    }

    function parseSyncedLyrics(value: string): var {
        const result = []
        const rows = String(value ?? "").split(/\r?\n/)
        for (const row of rows) {
            const timestampPattern = /\[(\d{1,3}):(\d{2}(?:\.\d{1,3})?)\]/g
            const times = []
            let match = null
            while ((match = timestampPattern.exec(row)) !== null) {
                const minutes = Number(match[1]) || 0
                const seconds = Number(match[2]) || 0
                times.push(minutes * 60 + seconds)
            }
            if (times.length === 0)
                continue

            const text = row.replace(/\[[^\]]+\]/g, "").trim()
            if (text.length === 0)
                continue
            for (const time of times)
                result.push({ time: time, text: text })
        }
        result.sort((left, right) => left.time - right.time)
        return result
    }

    function makePlainLines(value: string): var {
        const result = []
        for (const row of String(value ?? "").split(/\r?\n/)) {
            const text = row.trim()
            if (text.length > 0)
                result.push({ time: -1, text: text })
        }
        return result
    }

    function findCurrentLine(position: real): int {
        if (!root.syncedAvailable)
            return -1
        const current = Number(position) || 0
        for (let index = root.lines.length - 1; index >= 0; --index) {
            if (current + 0.08 >= Number(root.lines[index].time))
                return index
        }
        return -1
    }

    Connections {
        target: RaohaneMedia

        function onTitleChanged(): void { root.scheduleLookup() }
        function onArtistChanged(): void { root.scheduleLookup() }
        function onAlbumChanged(): void { root.scheduleLookup() }
        function onLengthChanged(): void { root.scheduleLookup() }
        function onActivePlayerChanged(): void { root.scheduleLookup() }
    }

    Timer {
        id: lookupTimer
        interval: 450
        repeat: false
        onTriggered: root.lookup()
    }

    Timer {
        id: requestWatchdog
        interval: 12000
        repeat: false
        onTriggered: {
            if (root.activeRequest) {
                try { root.activeRequest.abort() } catch (error) {}
                root.activeRequest = null
            }
            root.loading = false
            root.errorText = qsTr("Lyrics request timed out. Try refresh.")
        }
    }

    Component.onCompleted: root.scheduleLookup()
}
