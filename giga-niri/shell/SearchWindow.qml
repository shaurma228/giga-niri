import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Поиск по системе в стиле Spotlight macOS 27 (Alt+Space): калькулятор,
// программы, окна, системные действия, файлы в домашней папке, команды (> …)
// и поиск в интернете. ↑/↓ — выбор, Enter — выполнить, Esc — закрыть.
Scope {
    id: search

    property bool open: false
    property var targetScreen: Quickshell.screens[0]

    property string query: ""
    property int sel: 0
    property var windows: []
    property var files: []
    property string calc: ""
    readonly property var results: build(query, calc, files, windows)

    readonly property string home: Quickshell.env("HOME")

    onOpenChanged: {
        if (open) {
            query = ""
            calc = ""
            files = []
            winProc.running = true
        }
    }
    onQueryChanged: {
        sel = 0
        debounce.restart()
    }

    // --- Источники ---------------------------------------------------------

    Process {
        id: winProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { search.windows = JSON.parse(text) } catch (e) { search.windows = [] }
            }
        }
    }

    Timer {
        id: debounce
        interval: 160
        onTriggered: {
            const q = search.query.trim()
            search.files = []
            search.calc = ""
            if (q.length >= 2 && !q.startsWith(">")) {
                fdProc.forQuery = q
                fdProc.running = false
                fdProc.running = true
            }
            if (search.looksLikeMath(q)) {
                calcProc.forQuery = q
                calcProc.expr = search.toQalc(q)
                calcProc.running = false
                calcProc.running = true
            }
        }
    }

    Process {
        id: fdProc
        property string forQuery: ""
        command: ["fd", "--ignore-case", "--fixed-strings", "--max-results", "8",
                  "--type", "f", "--type", "d", "--", forQuery, search.home]
        stdout: StdioCollector {
            onStreamFinished: {
                if (fdProc.forQuery !== search.query.trim()) return
                search.files = text.split("\n").filter(l => l !== "")
            }
        }
    }

    Process {
        id: calcProc
        property string forQuery: ""
        property string expr: ""
        command: ["timeout", "2", "qalc", "-t", "--", expr]
        stdout: StdioCollector {
            onStreamFinished: {
                if (calcProc.forQuery !== search.query.trim()) return
                const r = text.trim().split("\n").pop() ?? ""
                const ok = r !== "" && r !== calcProc.forQuery && !/error|ошибка|warning/i.test(r)
                search.calc = ok ? r : ""
            }
        }
    }

    // qalc понимает только английские связки: «в» → to, «15% от 2000» → 15% * 2000
    function toQalc(q) {
        return q.replace(/\s+в\s+/gi, " to ").replace(/%\s*от\s+/gi, "% * ").replace(/\s+of\s+/gi, " * ")
    }

    function looksLikeMath(q) {
        return /\d/.test(q) && (/[-+*/^%()=]/.test(q) || /\s(to|в|in)\s/i.test(q)
            || /\d\s*[a-zа-я$€₽]/i.test(q))
    }

    // --- Сборка результатов --------------------------------------------------

    readonly property var systemActions: [
        { title: "Заблокировать экран", keys: "lock заблокировать блокировка экран", code: 0xF033E,
          run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
        { title: "Сон", keys: "sleep suspend сон спящий", code: 0xF04B2,
          run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { title: "Выключение, перезагрузка, выход", keys: "power shutdown reboot logout выключить выключение перезагрузка перезагрузить выход питание",
          code: 0xF0425, run: () => Quickshell.execDetached([search.home + "/.config/giga-niri/power-menu.sh"]) },
        { title: "Параметры системы", keys: "settings параметры настройки система",
          code: 0xF0493, run: () => Quickshell.execDetached(["systemsettings"]) },
        { title: "Подсказка по клавишам", keys: "keys клавиши сочетания горячие хоткеи shortcuts",
          code: 0xF030C, run: () => Quickshell.execDetached([search.home + "/.config/giga-niri/keybinds.py"]) },
    ]

    function score(text, q) {
        // keywords у DesktopEntry — список, поэтому всё приводим к строке
        const t = (Array.isArray(text) ? text.join(" ") : String(text ?? "")).toLowerCase()
        if (t.startsWith(q)) return 3
        if (t.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 2
        if (t.includes(q)) return 1
        return 0
    }

    function build(rawQuery, calcValue, fileList, winList) {
        const query = rawQuery.trim()
        const q = query.toLowerCase()
        const out = []
        if (q === "") return out

        if (query.startsWith(">")) {
            const cmd = query.slice(1).trim()
            if (cmd !== "")
                out.push({ section: "Команда", title: cmd, subtitle: "Выполнить в терминале", code: 0xF018D,
                           run: () => Quickshell.execDetached(["alacritty", "--config-file",
                               search.home + "/.config/giga-niri/alacritty.toml", "--hold", "-e", "sh", "-c", cmd]) })
            return out
        }

        if (calcValue !== "")
            out.push({ section: "Калькулятор", title: "= " + calcValue, subtitle: query + " · Enter — скопировать",
                       code: 0xF00EC, run: () => { Quickshell.clipboardText = calcValue } })

        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ e, s: Math.max(score(e.name, q) * 3, score(e.genericName, q) * 2,
                                        score(e.keywords, q) * 2, score(e.comment, q)) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .slice(0, 6)
        for (const { e } of apps)
            out.push({ section: "Программы", title: e.name, subtitle: e.genericName || e.comment || "",
                       icon: e.icon, code: 0xF003B, run: () => e.execute() })

        const wins = winList.filter(w => score(w.title, q) || score(w.app_id, q)).slice(0, 4)
        for (const w of wins)
            out.push({ section: "Окна", title: w.title || w.app_id, subtitle: w.app_id || "",
                       icon: DesktopEntries.heuristicLookup(w.app_id || "")?.icon ?? "", code: 0xF05B5,
                       run: () => Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(w.id)]) })

        for (const a of systemActions.filter(a => score(a.title, q) || score(a.keys, q)))
            out.push({ section: "Система", title: a.title, subtitle: "", code: a.code, run: a.run })

        for (const f of fileList) {
            const isDir = f.endsWith("/")
            const path = isDir ? f.slice(0, -1) : f
            const name = path.split("/").pop()
            const dir = path.slice(0, path.length - name.length - 1).replace(search.home, "~")
            out.push({ section: "Файлы", title: name, subtitle: dir || "~", code: isDir ? 0xF024B : 0xF0214,
                       run: () => Quickshell.execDetached(["xdg-open", path]) })
        }

        out.push({ section: "Интернет", title: "Искать «" + query + "» в интернете", subtitle: "Firefox",
                   code: 0xF059F, run: () => Quickshell.execDetached(["firefox", "--search", query]) })
        return out
    }

    function activate(i) {
        const r = results[i]
        if (!r) return
        open = false
        r.run()
    }

    // --- Окна ----------------------------------------------------------------

    // Подложка: клик мимо закрывает поиск
    PanelWindow {
        visible: search.open
        screen: search.targetScreen
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "giga-search-scrim"
        MouseArea { anchors.fill: parent; onClicked: search.open = false }
    }

    PanelWindow {
        id: win

        visible: search.open
        screen: search.targetScreen
        color: "transparent"
        anchors.top: true
        margins.top: Math.round((search.targetScreen ? search.targetScreen.height : 1080) * 0.2)
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 680
        implicitHeight: card.implicitHeight
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "giga-search"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: column.implicitHeight
            radius: 26
            color: Theme.card
            border.width: 1
            border.color: Theme.cardBorder

            ColumnLayout {
                id: column
                width: parent.width
                spacing: 0

                // Строка ввода
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 12

                    Icon { code: 0xF0349; size: 22; color: Theme.subtle }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        text: search.query
                        onTextChanged: search.query = text
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 22
                        selectByMouse: true
                        focus: search.open
                        onVisibleChanged: if (visible) forceActiveFocus()
                        Component.onCompleted: forceActiveFocus()

                        Keys.onPressed: event => {
                            // Esc и то же сочетание, что открывает поиск (Alt+Space), закрывают его.
                            // Окно держит клавиатуру целиком, поэтому до niri нажатие не доходит.
                            if (event.key === Qt.Key_Escape
                                    || (event.key === Qt.Key_Space && (event.modifiers & Qt.AltModifier))) {
                                search.open = false; event.accepted = true
                            }
                            else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                search.sel = Math.min(search.sel + 1, search.results.length - 1); event.accepted = true
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                search.sel = Math.max(search.sel - 1, 0); event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                search.activate(search.sel); event.accepted = true
                            }
                        }

                        Label {
                            visible: input.text === ""
                            text: "Поиск по системе: программы, файлы, окна, калькулятор…"
                            size: 22
                            color: Theme.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    visible: search.results.length > 0
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: "#1fffffff"
                }

                ListView {
                    id: list
                    visible: search.results.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 470)
                    Layout.topMargin: 6
                    Layout.bottomMargin: 8
                    clip: true
                    model: search.results
                    currentIndex: search.sel
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Column {
                        id: item
                        required property var modelData
                        required property int index
                        readonly property bool header: index === 0 || search.results[index - 1].section !== modelData.section
                        width: ListView.view.width

                        Label {
                            visible: item.header
                            text: item.modelData.section
                            size: 11
                            bold: true
                            color: Theme.muted
                            leftPadding: 22
                            topPadding: item.index === 0 ? 4 : 10
                            bottomPadding: 4
                        }

                        Rectangle {
                            x: 8
                            width: parent.width - 16
                            height: 44
                            radius: 10
                            color: item.index === search.sel ? Theme.blue : (rowMouse.containsMouse ? Theme.rowHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Item {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    readonly property string path: item.modelData.icon ? Quickshell.iconPath(item.modelData.icon, true) : ""
                                    Image {
                                        anchors.fill: parent
                                        visible: parent.path !== ""
                                        source: parent.path
                                        sourceSize: Qt.size(56, 56)
                                        smooth: true
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        visible: parent.path === ""
                                        code: item.modelData.code
                                        size: 20
                                        color: item.index === search.sel ? "#ffffff" : Theme.subtle
                                    }
                                }

                                Label {
                                    text: item.modelData.title
                                    size: 14
                                    bold: item.modelData.section === "Калькулятор"
                                    color: item.index === search.sel ? "#ffffff" : Theme.fg
                                    Layout.maximumWidth: 380
                                }
                                Label {
                                    text: item.modelData.subtitle
                                    size: 12
                                    color: item.index === search.sel ? "#d9ffffff" : Theme.muted
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: search.activate(item.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
