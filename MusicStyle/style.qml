pragma Singleton

import QtQuick

QtObject {
    readonly property color background: Qt.rgba(255 / 255, 0 / 255, 128 / 255, 0.60)
    readonly property color border: Qt.rgba(255 / 255, 51 / 255, 133 / 255, 0.70)

    readonly property color text: "#ffffff"
    readonly property color secondaryText: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.70)
    readonly property color mutedText: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.45)

    readonly property color button: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.12)
    readonly property color buttonHover: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.22)

    readonly property color progress: "#ff3385"

    readonly property color sliderBackground: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.15)
    readonly property color sliderProgress: "#ff3385"
    readonly property color sliderHandle: "#ffffff"

    readonly property int radius: 0
    readonly property int smallRadius: 0
    readonly property int borderWidth: 2

    readonly property int coverSize: 260
    readonly property int titleSize: 28
    readonly property int artistSize: 17
    readonly property int normalSize: 13

    readonly property int sliderHeight: 6
    readonly property int sliderHandleSize: 16
}
