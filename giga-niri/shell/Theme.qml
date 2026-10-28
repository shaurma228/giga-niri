pragma Singleton

import QtQuick
import Quickshell

// Цвета и шрифты Tokyo Glass. Цвета с прозрачностью в Qt: #AARRGGBB.
Singleton {
    readonly property color card: "#e01a1b26"
    readonly property color cardBorder: "#807aa2f7"
    readonly property color row: "#14c0caf5"
    readonly property color rowHover: "#267aa2f7"
    readonly property color rowActive: "#3d7aa2f7"
    readonly property color track: "#3b4261"

    readonly property color fg: "#c0caf5"
    readonly property color subtle: "#a9b1d6"
    readonly property color muted: "#565f89"
    readonly property color blue: "#7aa2f7"
    readonly property color magenta: "#bb9af7"
    readonly property color cyan: "#7dcfff"
    readonly property color green: "#9ece6a"
    readonly property color orange: "#ff9e64"
    readonly property color red: "#f7768e"
    readonly property color dark: "#16161e"

    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    readonly property int radius: 20
    readonly property int pad: 18

    // Значки Nerd Font (Material Design) по коду: так их не испортит запись файла
    function icon(code) { return String.fromCodePoint(code) }
}
