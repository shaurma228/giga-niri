pragma Singleton

import QtQuick
import Quickshell

// Цвета и шрифты в стиле macOS 27 (тёмный режим, Liquid Glass).
// Системные цвета Apple для тёмного режима. Цвета с прозрачностью в Qt: #AARRGGBB.
Singleton {
    // Стекло: плотнее, чем в Tahoe (macOS 27 снизил прозрачность), светлая кромка
    readonly property color card: "#c41e1e20"
    readonly property color cardBorder: "#30ffffff"
    readonly property color tile: "#1fffffff"
    readonly property color row: "#14ffffff"
    readonly property color rowHover: "#24ffffff"
    readonly property color rowActive: "#2b0a84ff"
    readonly property color track: "#3a3a3c"

    readonly property color fg: "#f2f2f7"
    readonly property color subtle: "#aeaeb2"
    readonly property color muted: "#8e8e93"
    readonly property color blue: "#0a84ff"
    readonly property color magenta: "#bf5af2"
    readonly property color cyan: "#64d2ff"
    readonly property color green: "#30d158"
    readonly property color orange: "#ff9f0a"
    readonly property color red: "#ff453a"
    readonly property color dark: "#1c1c1e"

    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Единые скругления, как в macOS 27: 22 — у всех поверхностей (окна, меню fuzzel,
    // поиск, Пункт управления, уведомления), 14 — у всего внутри них.
    // Те же значения в niri/cfg/rules.kdl, fuzzel/fuzzel.ini, mako/config.
    readonly property int radius: 22
    readonly property int innerRadius: 14
    readonly property int pad: 14

    // Значки Nerd Font (Material Design) по коду: так их не испортит запись файла
    function icon(code) { return String.fromCodePoint(code) }
}
