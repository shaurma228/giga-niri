//@ pragma IconTheme McMojave-circle
// Пункт управления и всплывающие меню giga-niri в стиле macOS 27:
// control (Пункт управления) → wifi / bluetooth / audio, а также calendar.
// Запуск: qs -p ~/.config/giga-niri/shell
// Открыть/закрыть: qs -p ~/.config/giga-niri/shell ipc call popup toggle wifi
// Поиск по системе (Alt+Space): qs -p ~/.config/giga-niri/shell ipc call search toggle
// Системное меню (как меню Apple): qs -p ~/.config/giga-niri/shell ipc call system toggle
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
        systemMenu.open = false
        if (current === name) {
            current = ""
            return
        }
        focusedOutput.pending = name
        focusedOutput.running = true
    }

    function toggleSearch() {
        systemMenu.open = false
        if (searchWindow.open) {
            searchWindow.open = false
            return
        }
        current = ""
        focusedOutput.pending = "search"
        focusedOutput.running = true
    }

    function toggleSystem() {
        if (systemMenu.open) {
            systemMenu.open = false
            return
        }
        current = ""
        searchWindow.open = false
        focusedOutput.pending = "system"
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
                if (focusedOutput.pending === "search") {
                    systemMenu.open = false
                    searchWindow.targetScreen = root.targetScreen
                    searchWindow.open = true
                } else if (focusedOutput.pending === "system") {
                    searchWindow.open = false
                    root.current = ""
                    systemMenu.targetScreen = root.targetScreen
                    systemMenu.open = true
                } else {
                    searchWindow.open = false
                    systemMenu.open = false
                    root.current = focusedOutput.pending
                }
            }
        }
    }

    IpcHandler {
        target: "search"
        function toggle(): void { root.toggleSearch() }
        function close(): void { searchWindow.open = false }
        // Подставить запрос (для проверки и для открытия поиска с готовым текстом)
        function setQuery(text: string): void { searchWindow.query = text }
    }

    SearchWindow { id: searchWindow }

    SystemMenu { id: systemMenu }

    IpcHandler {
        target: "system"
        function toggle(): void { root.toggleSystem() }
        function close(): void { systemMenu.open = false }
        // Открыть страницу меню: about, force, confirm-reboot, confirm-poweroff, confirm-logout, menu
        function page(name: string): void { systemMenu.page = name }
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
        implicitWidth: root.current === "calendar" ? 330 : 360
        implicitHeight: card.implicitHeight
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "giga-popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            id: card

            width: parent.width
            implicitHeight: loader.implicitHeight + Theme.pad * 2
            radius: Theme.panelRadius
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
                    control: controlPanel,
                    wifi: wifiPanel,
                    bluetooth: bluetoothPanel,
                    audio: audioPanel,
                    calendar: calendarPanel,
                })[root.current] ?? null
            }
        }
    }

    Component {
        id: controlPanel
        ControlCenterPanel {
            onRequestClose: root.current = ""
            onOpen: page => root.current = page
        }
    }

    Component {
        id: wifiPanel
        WifiPanel {
            onRequestClose: root.current = ""
            onRequestBack: root.current = "control"
        }
    }

    Component {
        id: bluetoothPanel
        BluetoothPanel {
            onRequestClose: root.current = ""
            onRequestBack: root.current = "control"
        }
    }

    Component {
        id: audioPanel
        AudioPanel {
            onRequestClose: root.current = ""
            onRequestBack: root.current = "control"
        }
    }

    Component {
        id: calendarPanel
        CalendarPanel { onRequestClose: root.current = "" }
    }
}
