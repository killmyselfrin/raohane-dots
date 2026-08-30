pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml

QtObject {
    id: root

    property bool loading: false
    property bool instrumental: false
    property string plainLyrics: ""
    property var lines: []
    property string errorText: ""
    property string providerName: "LRCLIB"
    property int requestSerial: 0
    property var cache: ({})

    readonly property bool syncedAvailable: lines.length > 0
    readonly property bool available: instrumental || syncedAvailable || plainLyrics.trim().length > 0
    readonly property int currentLineIndex: root.findCurrentLine(RaohaneMedia.position)
    readonly property var displayLines: syncedAvailable ? lines : root.makePlainLines(plainLyrics)

    function clear(): void {
        root.loading = false
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = ""
    }

    function trackKey(): string {
        return [
            String(RaohaneMedia.artist ?? "").trim().toLowerCase(),
            String(RaohaneMedia.title ?? "").trim().toLowerCase(),
            String(RaohaneMedia.album ?? "").trim().toLowerCase(),
            Math.round(Number(RaohaneMedia.length) || 0)
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
        const artist = String(RaohaneMedia.artist ?? "").trim()
        const title = String(RaohaneMedia.title ?? "").trim()

        root.requestSerial += 1
        const serial = root.requestSerial

        if (!RaohaneMedia.available || artist.length === 0 || title.length === 0) {
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
        root.requestExact(serial, key)
    }

    function requestExact(serial: int, key: string): void {
        const params = [
            "artist_name=" + encodeURIComponent(String(RaohaneMedia.artist ?? "").trim()),
            "track_name=" + encodeURIComponent(String(RaohaneMedia.title ?? "").trim())
        ]
        const album = String(RaohaneMedia.album ?? "").trim()
        const duration = Math.round(Number(RaohaneMedia.length) || 0)
        if (album.length > 0)
            params.push("album_name=" + encodeURIComponent(album))
        if (duration >= 1 && duration <= 3600)
            params.push("duration=" + duration)

        root.getJson(
            "https://lrclib.net/api/get?" + params.join("&"),
            serial,
            record => root.applyRecord(record, key),
            () => root.requestSearch(serial, key)
        )
    }

    function requestSearch(serial: int, key: string): void {
        if (serial !== root.requestSerial)
            return

        const params = [
            "track_name=" + encodeURIComponent(String(RaohaneMedia.title ?? "").trim()),
            "artist_name=" + encodeURIComponent(String(RaohaneMedia.artist ?? "").trim())
        ]
        const album = String(RaohaneMedia.album ?? "").trim()
        if (album.length > 0)
            params.push("album_name=" + encodeURIComponent(album))

        root.getJson(
            "https://lrclib.net/api/search?" + params.join("&"),
            serial,
            records => {
                if (!Array.isArray(records) || records.length === 0) {
                    root.finishNotFound(serial)
                    return
                }
                root.applyRecord(root.chooseBestRecord(records), key)
            },
            () => root.finishNotFound(serial)
        )
    }

    function getJson(url: string, serial: int, onSuccess, onNotFound): void {
        const request = new XMLHttpRequest()
        request.open("GET", url)
        request.setRequestHeader("Accept", "application/json")
        request.setRequestHeader("Lrclib-Client", "Raohane/0.10.0-dev (https://github.com/killmyselfrin/raohane-dots)")
        request.onreadystatechange = function() {
            if (request.readyState !== 4 || serial !== root.requestSerial)
                return

            if (request.status === 200) {
                try {
                    onSuccess(JSON.parse(request.responseText))
                } catch (error) {
                    root.loading = false
                    root.errorText = qsTr("Lyrics response could not be read")
                }
                return
            }

            if (request.status === 404) {
                onNotFound()
                return
            }

            root.loading = false
            root.errorText = request.status === 429
                ? qsTr("Lyrics service is busy. Try again shortly.")
                : qsTr("Could not load lyrics")
        }
        request.send()
    }

    function chooseBestRecord(records): var {
        const wantedTitle = String(RaohaneMedia.title ?? "").trim().toLowerCase()
        const wantedArtist = String(RaohaneMedia.artist ?? "").trim().toLowerCase()
        const wantedAlbum = String(RaohaneMedia.album ?? "").trim().toLowerCase()
        const wantedDuration = Number(RaohaneMedia.length) || 0

        let best = records[0]
        let bestScore = Number.POSITIVE_INFINITY
        for (const record of records) {
            const recordTitle = String(record.trackName ?? record.name ?? "").trim().toLowerCase()
            const recordArtist = String(record.artistName ?? "").trim().toLowerCase()
            const recordAlbum = String(record.albumName ?? "").trim().toLowerCase()
            const recordDuration = Number(record.duration) || 0
            let score = 0
            if (recordTitle !== wantedTitle)
                score += 80
            if (recordArtist !== wantedArtist)
                score += 80
            if (wantedAlbum.length > 0 && recordAlbum !== wantedAlbum)
                score += 12
            if (wantedDuration > 0 && recordDuration > 0)
                score += Math.abs(wantedDuration - recordDuration)
            if (score < bestScore) {
                bestScore = score
                best = record
            }
        }
        return best
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

    Component.onCompleted: root.scheduleLookup()
}
