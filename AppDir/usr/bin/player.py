import dbus
import dbus.mainloop.glib
import requests
import subprocess
import json
import re

from PySide6.QtCore import QObject, Signal, Property, Slot, QTimer


class Player(QObject):
    changed = Signal()
    lyricsChanged = Signal()

    def __init__(self):
        super().__init__()

        self.bus = dbus.SessionBus()
        self.service = None

        self._lyrics = ""
        self._synced_lyrics = []
        self._lyrics_source = ""
        self._lyrics_track = ""

        self.timer = QTimer()
        self.timer.timeout.connect(self.refresh)
        self.timer.start(500)

        self.refresh()

    def find_players(self):
        return [
            name for name in self.bus.list_names()
            if name.startswith("org.mpris.MediaPlayer2.")
        ]

    def find_active(self):
        players = self.find_players()

        for service in players:
            try:
                obj = self.bus.get_object(
                    service,
                    "/org/mpris/MediaPlayer2"
                )

                props = dbus.Interface(
                    obj,
                    "org.freedesktop.DBus.Properties"
                )

                status = props.Get(
                    "org.mpris.MediaPlayer2.Player",
                    "PlaybackStatus"
                )

                if status == "Playing":
                    return service

            except Exception:
                pass

        return players[0] if players else None

    def refresh(self):
        new_service = self.find_active()

        if new_service != self.service:
            self.service = new_service
            self.load_lyrics()
            self.changed.emit()
        else:
            old_track = self._lyrics_track

            current_track = (
                self.title +
                " - " +
                self.artist
            )

            if current_track != old_track:
                self.load_lyrics()

            self.changed.emit()

    def props(self):
        if not self.service:
            return None

        try:
            obj = self.bus.get_object(
                self.service,
                "/org/mpris/MediaPlayer2"
            )

            return dbus.Interface(
                obj,
                "org.freedesktop.DBus.Properties"
            )

        except Exception:
            return None

    def metadata(self):
        props = self.props()

        if not props:
            return {}

        try:
            return props.Get(
                "org.mpris.MediaPlayer2.Player",
                "Metadata"
            )
        except Exception:
            return {}

    def value(self, key, default=""):
        data = self.metadata()

        try:
            return data.get(key, default)
        except Exception:
            return default

    @Property(str, notify=changed)
    def title(self):
        return str(
            self.value(
                "xesam:title",
                "Sin música"
            )
        )

    @Property(str, notify=changed)
    def artist(self):
        artists = self.value(
            "xesam:artist",
            []
        )

        if artists:
            return str(artists[0])

        return "Artista desconocido"

    @Property(str, notify=changed)
    def album(self):
        return str(
            self.value(
                "xesam:album",
                ""
            )
        )

    @Property(str, notify=changed)
    def artUrl(self):
        return str(
            self.value(
                "mpris:artUrl",
                ""
            )
        )

    @Property(str, notify=changed)
    def identity(self):
        if not self.service:
            return "Sin reproductor"

        return self.service.replace(
            "org.mpris.MediaPlayer2.",
            ""
        )

    @Property(bool, notify=changed)
    def playing(self):
        props = self.props()

        if not props:
            return False

        try:
            return props.Get(
                "org.mpris.MediaPlayer2.Player",
                "PlaybackStatus"
            ) == "Playing"

        except Exception:
            return False

    @Property(float, notify=changed)
    def position(self):
        props = self.props()

        if not props:
            return 0

        try:
            value = props.Get(
                "org.mpris.MediaPlayer2.Player",
                "Position"
            )

            return float(value) / 1000000.0

        except Exception:
            return 0

    @Property(float, notify=changed)
    def length(self):
        value = self.value(
            "mpris:length",
            0
        )

        try:
            return float(value) / 1000000.0

        except Exception:
            return 0

    # ============================================================
    # LETRAS
    # ============================================================

    @Property(str, notify=lyricsChanged)
    def lyrics(self):
        return self._lyrics

    @Property(str, notify=lyricsChanged)
    def lyricsSource(self):
        return self._lyrics_source

    @Property(str, notify=lyricsChanged)
    def syncedLyrics(self):
        import json
        return json.dumps(
            [
                {"time": timestamp, "text": text}
                for timestamp, text in self._synced_lyrics
            ],
            ensure_ascii=False
        )

    @Property(str, notify=lyricsChanged)
    def currentLyric(self):
        position = self.position

        if not self._synced_lyrics:
            return ""

        current = ""

        for timestamp, text in self._synced_lyrics:
            if position >= timestamp:
                current = text
            else:
                break

        return current

    def load_lyrics(self):
        title = self.title
        artist = self.artist

        if (
            not title
            or title == "Sin música"
            or artist == "Artista desconocido"
        ):
            self._lyrics = ""
            self._synced_lyrics = []
            self._lyrics_source = ""
            self.lyricsChanged.emit()
            return

        self._lyrics_track = title + " - " + artist

        self._lyrics = "Buscando letras..."
        self._synced_lyrics = []
        self._lyrics_source = ""

        self.lyricsChanged.emit()

        try:
            response = requests.get(
                "https://lrclib.net/api/get",
                params={
                    "track_name": title,
                    "artist_name": artist,
                    "album_name": self.album,
                    "duration": self.length
                },
                timeout=5
            )

            if response.ok:
                data = response.json()

                synced = data.get(
                    "syncedLyrics"
                )

                plain = data.get(
                    "plainLyrics"
                )

                if synced:
                    self._synced_lyrics = (
                        self.parse_lrc(synced)
                    )

                    self._lyrics = "\n".join(
                        text
                        for _, text
                        in self._synced_lyrics
                    )

                    self._lyrics_source = "Spotify"
                    self.lyricsChanged.emit()
                    return

                if plain:
                    self._lyrics = plain
                    self._lyrics_source = "Spotify"
                    self.lyricsChanged.emit()
                    return

        except Exception:
            pass

        self._lyrics = "No se encontraron letras."
        self._lyrics_source = ""
        self.lyricsChanged.emit()

    def parse_lrc(self, text):
        result = []

        pattern = re.compile(
            r"\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)"
        )

        for line in text.splitlines():
            match = pattern.match(line.strip())

            if not match:
                continue

            minutes = int(match.group(1))
            seconds = float(match.group(2))
            lyric = match.group(3).strip()

            result.append(
                (
                    minutes * 60 + seconds,
                    lyric
                )
            )

        result.sort(
            key=lambda item: item[0]
        )

        return result

    # ============================================================
    # CONTROLES
    # ============================================================

    @Slot()
    def playPause(self):
        self.call_player("PlayPause")

    @Slot()
    def next(self):
        self.call_player("Next")

    @Slot()
    def previous(self):
        self.call_player("Previous")

    def call_player(self, method):
        if not self.service:
            return

        try:
            obj = self.bus.get_object(
                self.service,
                "/org/mpris/MediaPlayer2"
            )

            player = dbus.Interface(
                obj,
                "org.mpris.MediaPlayer2.Player"
            )

            getattr(player, method)()

        except Exception:
            pass

    @Slot(float)
    def seek(self, seconds):
        if not self.service:
            return

        try:
            obj = self.bus.get_object(
                self.service,
                "/org/mpris/MediaPlayer2"
            )

            player = dbus.Interface(
                obj,
                "org.mpris.MediaPlayer2.Player"
            )

            player.SetPosition(
                "/org/mpris/MediaPlayer2/TrackList/NoTrack",
                dbus.Int64(
                    seconds * 1000000
                )
            )

        except Exception:
            pass
