import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "MusicStyle"

ApplicationWindow {
    id: app

    width: 1200
    height: 430

    minimumWidth: 900
    minimumHeight: 380

    visible: true
    color: "transparent"
    title: "Music Player"

    Rectangle {
        anchors.fill: parent

        color: Style.background
        radius: Style.radius

        border.width: Style.borderWidth
        border.color: Style.border
    }

    // ============================================================
    // CONTENIDO DE MÚSICA
    // ============================================================

    Row {
        id: musicLayout

        anchors.left: parent.left
        anchors.leftMargin: 30

        anchors.top: parent.top
        anchors.topMargin: 35

        anchors.right: lyricsPanel.left
        anchors.rightMargin: 25

        height: 320

        spacing: 25

        // --------------------------------------------------------
        // PORTADA
        // --------------------------------------------------------

        Rectangle {
            id: cover

            width: 250
            height: 250

            anchors.verticalCenter: parent.verticalCenter

            color: Qt.rgba(1, 1, 1, 0.08)

            radius: Style.radius

            clip: true

            Image {
                anchors.fill: parent

                source: player.artUrl

                fillMode: Image.PreserveAspectCrop

                asynchronous: true
                smooth: true
            }

            Text {
                anchors.centerIn: parent

                text: "♫"

                color: Style.text

                font.pixelSize: 70

                visible: player.artUrl === ""
            }
        }

        // --------------------------------------------------------
        // INFORMACIÓN + CONTROLES + PROGRESO
        // --------------------------------------------------------

        Column {
            id: musicInfo

            width: parent.width - cover.width - parent.spacing

            height: parent.height

            anchors.verticalCenter: parent.verticalCenter

            spacing: 10

            Item {
                width: 1
                height: 55
            }

            Text {
                width: parent.width

                text: player.title

                color: Style.text

                font.pixelSize: 28
                font.bold: true

                elide: Text.ElideRight
            }

            Text {
                width: parent.width

                text: player.artist

                color: Style.secondaryText

                font.pixelSize: 17

                elide: Text.ElideRight
            }

            Text {
                width: parent.width

                text: player.album

                color: Style.mutedText

                font.pixelSize: 13

                elide: Text.ElideRight
            }

            Item {
                width: 1
                height: 12
            }

            // ----------------------------------------------------
            // BOTONES
            // ----------------------------------------------------

            Row {
                id: controls

                spacing: 14

                Rectangle {
                    width: 45
                    height: 45

                    radius: 22

                    color: Style.button

                    Text {
                        anchors.centerIn: parent

                        text: "󰒮"

                        color: Style.text

                        font.pixelSize: 22
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: player.previous()
                    }
                }

                Rectangle {
                    width: 58
                    height: 58

                    radius: 29

                    color: Style.buttonHover

                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent

                        text: player.playing
                              ? "󰏤"
                              : "󰐊"

                        color: Style.text

                        font.pixelSize: 27
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: player.playPause()
                    }
                }

                Rectangle {
                    width: 45
                    height: 45

                    radius: 22

                    color: Style.button

                    Text {
                        anchors.centerIn: parent

                        text: "󰒭"

                        color: Style.text

                        font.pixelSize: 22
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: player.next()
                    }
                }
            }

        }
    }

    // ============================================================
    // BARRA DE TIEMPO GLOBAL
    // ============================================================

    Item {
        id: globalProgress

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 37

        height: 28

        Rectangle {
            id: progressBar

            anchors.left: parent.left
            anchors.right: parent.right

            anchors.top: parent.top

            height: 6

            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                width: player.length > 0
                        ? parent.width *
                          Math.min(
                              1,
                              player.position /
                              player.length
                          )
                        : 0

                height: parent.height

                color: Style.progress
            }

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    if (player.length <= 0)
                        return

                    player.seek(
                        mouse.x /
                        width *
                        player.length
                    )
                }
            }
        }
    }

    // ============================================================
    // LETRAS
    // ============================================================

    Rectangle {
        id: lyricsPanel

        width: 400

        anchors.top: musicLayout.top
        anchors.bottom: musicLayout.bottom

        anchors.right: parent.right
        anchors.rightMargin: 20

        color: Qt.rgba(1, 1, 1, 0.07)

        radius: Style.smallRadius

        border.width: 1

        border.color: Qt.rgba(1, 1, 1, 0.10)

        Column {
            anchors.fill: parent

            anchors.margins: 18

            spacing: 10

            Text {
                text: "♫  LETRAS"

                color: Style.text

                font.pixelSize: 14
                font.bold: true
            }

            Flickable {
                id: lyricsFlick

                width: parent.width
                height: parent.height - 35

                clip: true

                contentHeight: lyricsColumn.height

                property var lines: {
                    try {
                        return JSON.parse(player.syncedLyrics)
                    } catch (e) {
                        return []
                    }
                }

                Connections {
                    target: player

                    function onChanged() {
                        lyricsFlick.linesChanged()
                    }

                    function onLyricsChanged() {
                        lyricsFlick.linesChanged()
                    }
                }

                Column {
                    id: lyricsColumn

                    width: parent.width

                    spacing: 8

                    Repeater {
                        model: lyricsFlick.lines

                        delegate: Text {
                            id: lyricLine

                            required property var modelData

                            property bool isCurrent:
                                player.position >= modelData.time &&
                                (
                                    index === lyricsFlick.lines.length - 1 ||
                                    player.position < lyricsFlick.lines[index + 1].time
                                )

                            onIsCurrentChanged: {
                                if (isCurrent) {
                                    Qt.callLater(function() {
                                        var target =
                                            lyricLine.y -
                                            lyricsFlick.height / 2 +
                                            lyricLine.height / 2

                                        lyricsFlick.contentY =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    target,
                                                    lyricsFlick.contentHeight -
                                                    lyricsFlick.height
                                                )
                                            )
                                    })
                                }
                            }

                            required property int index

                            width: lyricsColumn.width

                            text: modelData.text

                            horizontalAlignment: Text.AlignLeft

                            wrapMode: Text.WordWrap

                            color: {
                                if (isCurrent)
                                    return Style.text

                                return Style.mutedText
                            }

                            font.pixelSize: {
                                if (isCurrent)
                                    return 16

                                return 13
                            }

                            font.bold: {
                                return isCurrent
                            }

                            opacity: {
                                if (isCurrent)
                                    return 1.0

                                return 0.55
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 180
                                }
                            }

                            Behavior on font.pixelSize {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // ARRASTRAR VENTANA
    // ============================================================

    MouseArea {
        id: dragArea

        z: 1000

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 35

        acceptedButtons: Qt.LeftButton

        onPressed: {
            windowController.startMove()
        }
    }

    function formatTime(seconds) {
        if (!seconds ||
            seconds < 0 ||
            !isFinite(seconds)) {
            return "0:00"
        }

        var minutes = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)

        return minutes +
               ":" +
               (secs < 10 ? "0" : "") +
               secs
    }
}
