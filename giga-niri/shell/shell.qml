// Всплывающие меню giga-niri: Wi-Fi, Bluetooth, календарь, звук.
// Запуск: qs -p ~/.config/giga-niri/shell
// Открыть/закрыть: qs -p ~/.config/giga-niri/shell ipc call popup toggle wifi
//
// Блюр под карточкой даёт niri (layer-rule для namespace "giga-popup").

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property string current: ""
    property var targetScreen: Quickshell.screens[0]

    function toggle(name) {
        if (current === name) {
            current = ""
            return
        }
        focusedOutput.pending = name
        focusedOutput.running = true
    }

    // Карточка открывается на мониторе, где сейчас фокус
    Process {
        id: focusedOutput
        property string pending: ""
        command: ["niri", "msg", "-j", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = ""
                try { name = JSON.parse(text).name } catch (e) {}
                root.targetScreen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
                root.current = focusedOutput.pending
            }
        }
    }

    IpcHandler {
        target: "popup"
        function toggle(name: string): void { root.toggle(name) }
        function close(): void { root.current = "" }
    }

    // Прозрачная подложка: клик мимо карточки закрывает её. Бар (30 px) не перекрыт,
    // поэтому клик по другому модулю бара сразу переключает карточку.
    PanelWindow {
        visible: root.current !== ""
        screen: root.targetScreen
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: 30
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "giga-popup-scrim"

        MouseArea {
            anchors.fill: parent
            onClicked: root.current = ""
        }
    }

    PanelWindow {
        id: popup

        visible: root.current !== ""
        screen: root.targetScreen
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: 38; right: 12 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 380
        implicitHeight: card.implicitHeight
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "giga-popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            id: card

            width: parent.width
            implicitHeight: loader.implicitHeight + Theme.pad * 2
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.cardBorder
            focus: true
            Keys.onEscapePressed: root.current = ""

            // Появление: лёгкий сдвиг сверху и проявление
            opacity: 0
            transform: Translate { id: shift; y: -10 }
            states: State {
                name: "shown"
                when: popup.visible
                PropertyChanges { card.opacity: 1; shift.y: 0 }
            }
            transitions: Transition {
                to: "shown"
                NumberAnimation { properties: "opacity,y"; duration: 220; easing.type: Easing.OutCubic }
            }

            Loader {
                id: loader
                x: Theme.pad
                y: Theme.pad
                width: parent.width - Theme.pad * 2
                sourceComponent: ({
                    wifi: wifiPanel,
                    bluetooth: bluetoothPanel,
                    audio: audioPanel,
                    calendar: calendarPanel,
                })[root.current] ?? null
            }
        }
    }

    Component {
        id: wifiPanel
        WifiPanel { onRequestClose: root.current = "" }
    }

    Component {
        id: bluetoothPanel
        BluetoothPanel { onRequestClose: root.current = "" }
    }

    Component {
        id: audioPanel
        AudioPanel { onRequestClose: root.current = "" }
    }

    Component {
        id: calendarPanel
        CalendarPanel { onRequestClose: root.current = "" }
    }
}
