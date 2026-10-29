import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Системное меню в стиле macOS 27 (как меню Apple): «Об этой системе», сон, перезагрузка,
// выключение, блокировка, выход. Открывается: qs -p ~/.config/giga-niri/shell ipc call system toggle
// ↑/↓ — выбор, Enter — выполнить, Esc — назад или закрыть, Super+Shift+Q — закрыть.
Scope {
    id: sys

    property bool open: false
    property var targetScreen: Quickshell.screens[0]
    // menu | about | force | confirm-reboot | confirm-poweroff | confirm-logout
    property string page: "menu"

    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER")

    // Выделение в меню (индекс в menuItems, разделители пропускаются)
    property int sel: 0

    // Данные страниц
    property string host: ""
    property string osName: ""
    property var aboutRows: []
    property var wins: []
    property int forceSel: -1

    onOpenChanged: {
        if (open) {
            page = "menu"
            sel = 0
        }
    }
    onPageChanged: {
        if (page === "menu") sel = 0
        else if (page === "about") infoProc.running = true
        else if (page === "force") {
            forceSel = -1
            winsProc.running = true
        }
    }

    // --- Пункты меню --------------------------------------------------------

    readonly property var menuItems: [
        { title: "Об этой системе", act: () => { sys.page = "about" } },
        { sep: true },
        { title: "Параметры системы…", act: () => sys.launch(["systemsettings"]) },
        { sep: true },
        { title: "Завершить принудительно…", act: () => { sys.page = "force" } },
        { sep: true },
        { title: "Сон", act: () => sys.launch(["systemctl", "suspend"]) },
        { title: "Перезагрузить…", act: () => { sys.page = "confirm-reboot" } },
        { title: "Выключить…", act: () => { sys.page = "confirm-poweroff" } },
        { sep: true },
        { title: "Заблокировать экран", keys: "Super+Alt+L", act: () => sys.launch(["loginctl", "lock-session"]) },
        { title: "Завершить сеанс " + sys.user + "…", keys: "Super+Shift+E", act: () => { sys.page = "confirm-logout" } },
    ]

    // Подтверждения: вопрос, подпись кнопки и команда
    readonly property var confirms: ({
        "confirm-reboot": { q: "Перезагрузить компьютер сейчас?", btn: "Перезагрузить", cmd: ["systemctl", "reboot"] },
        "confirm-poweroff": { q: "Выключить компьютер сейчас?", btn: "Выключить", cmd: ["systemctl", "poweroff"] },
        "confirm-logout": { q: "Завершить сеанс и выйти?", btn: "Выйти", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
    })
    readonly property var cf: confirms[page] ?? ({ q: "", btn: "", cmd: [] })

    // Одна команда собирает сведения о системе; строки вида key=value
    readonly property string infoScript: ". /etc/os-release; echo \"os=$PRETTY_NAME\"; echo \"host=$(hostname)\"; "
        + "echo \"kernel=$(uname -r)\"; echo \"cpu=$(LC_ALL=C lscpu | sed -n 's/^Model name: *//p' | head -n1)\"; "
        + "lspci | grep -E 'VGA|3D' | sed -E 's/^[^ ]+ [^:]+: /gpu=/'; "
        + "echo \"mem=$(awk '/MemTotal/{print $2}' /proc/meminfo)\"; "
        + "echo \"niri=$(niri --version 2>/dev/null | awk '{print $2}')\""

    // --- Действия ------------------------------------------------------------

    function launch(cmd) {
        open = false
        Quickshell.execDetached(cmd)
    }

    function activate(i) {
        const it = menuItems[i]
        if (it && !it.sep && it.act) it.act()
    }

    function move(d) {
        let i = sel + d
        while (i >= 0 && i < menuItems.length && menuItems[i].sep) i += d
        if (i >= 0 && i < menuItems.length) sel = i
    }

    function step(d) {
        if (page === "menu") move(d)
        else if (page === "force") forceSel = Math.max(0, Math.min(wins.length - 1, forceSel + d))
    }

    function enter() {
        if (page === "menu") activate(sel)
        else if (page.startsWith("confirm")) page = "menu"
        // На странице «Завершить принудительно» Enter ничего не делает: убийство только мышью
    }

    function back() {
        if (page === "menu") open = false
        else page = "menu"
    }

    function selPid() {
        const w = wins[forceSel]
        return w && w.pid > 0 ? w.pid : 0
    }

    function killSelected() {
        const p = selPid()
        if (p > 0) launch(["kill", "-9", String(p)])
    }

    // --- Разбор сведений о системе -------------------------------------------

    // Видеокарта: «Intel Corporation Alder Lake-P GT1 [UHD Graphics]» → «Intel UHD Graphics»
    function shortGpu(v) {
        const vendor = (v.match(/NVIDIA|Intel|AMD/) || [""])[0]
        const br = v.match(/\[([^\]]+)\]/)
        if (br) return (vendor + " " + br[1]).trim()
        return v.replace(/\s*\(rev.*$/, "").replace(/ Corporation| Inc\.?| Co\., Ltd\./g, "").trim()
    }

    // Процессор: убираем (R), (TM) и частоту
    function shortCpu(v) {
        return v.replace(/\(R\)|\(TM\)/g, "").replace(/\s*@.*$/, "").replace(/\s+/g, " ").trim()
    }

    function parseInfo(t) {
        const kv = {}
        const gpus = []
        for (const line of t.split("\n")) {
            const i = line.indexOf("=")
            if (i < 0) continue
            const k = line.slice(0, i)
            const v = line.slice(i + 1).trim()
            if (k === "gpu") gpus.push(shortGpu(v))
            else kv[k] = v
        }
        host = kv.host ?? ""
        osName = kv.os ?? ""
        const kb = Number(kv.mem)
        aboutRows = [
            { label: "Система", value: kv.os ?? "" },
            { label: "Ядро", value: kv.kernel ?? "" },
            { label: "Процессор", value: shortCpu(kv.cpu ?? "") },
            { label: "Видеокарты", value: gpus.join(", ") },
            { label: "Память", value: kb > 0 ? (kb / 1048576).toFixed(1) + " ГБ" : "" },
            { label: "Оболочка", value: kv.niri ? "niri " + kv.niri : "niri" },
        ]
    }

    // --- Источники -----------------------------------------------------------

    Process {
        id: infoProc
        command: ["sh", "-c", sys.infoScript]
        stdout: StdioCollector { onStreamFinished: sys.parseInfo(text) }
    }

    Process {
        id: winsProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { sys.wins = JSON.parse(text) } catch (e) { sys.wins = [] }
            }
        }
    }

    // --- Компоненты ----------------------------------------------------------

    // Заголовок подстраницы: «‹» слева и название по центру
    component SubHeader: Item {
        id: hd
        property string title: ""
        signal back()
        Layout.fillWidth: true
        implicitHeight: 32

        Label {
            anchors.centerIn: parent
            text: hd.title
            size: 13
            bold: true
        }
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 8
            color: backMouse.containsMouse ? Theme.rowHover : "transparent"
            Icon { anchors.centerIn: parent; code: 0xF0141; size: 16; color: Theme.subtle }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: hd.back()
            }
        }
    }

    // Кнопка-таблетка для диалогов
    component PillButton: Rectangle {
        id: pb
        property string label: ""
        property color tint: Theme.blue
        property color textColor: "#ffffff"
        property bool active: true
        signal activated()
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        radius: Theme.innerRadius
        color: tint
        opacity: active ? 1 : 0.4
        Label {
            anchors.centerIn: parent
            text: pb.label
            size: 13
            bold: true
            color: pb.textColor
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: pb.active
            onClicked: pb.activated()
        }
    }

    // --- Подложка: клик мимо меню закрывает его. Бар (30 px) не перекрыт -------

    PanelWindow {
        visible: sys.open
        screen: sys.targetScreen
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: 30
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "giga-system-scrim"
        MouseArea { anchors.fill: parent; onClicked: sys.open = false }
    }

    // --- Меню ----------------------------------------------------------------

    PanelWindow {
        id: win

        visible: sys.open
        screen: sys.targetScreen
        color: "transparent"
        anchors { top: true; left: true }
        margins { top: 36; left: 8 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 330
        implicitHeight: card.implicitHeight
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "giga-system"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        onVisibleChanged: if (visible) card.forceActiveFocus()

        Rectangle {
            id: card

            width: parent.width
            implicitHeight: col.implicitHeight + 12
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.cardBorder
            focus: true

            // Окно держит клавиатуру целиком, поэтому Super+Shift+Q обрабатываем здесь
            Keys.onPressed: event => {
                const m = event.modifiers
                if (event.key === Qt.Key_Q && (m & Qt.MetaModifier) && (m & Qt.ShiftModifier)) {
                    sys.open = false
                } else if (event.key === Qt.Key_Escape) {
                    sys.back()
                } else if (event.key === Qt.Key_Down) {
                    sys.step(1)
                } else if (event.key === Qt.Key_Up) {
                    sys.step(-1)
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sys.enter()
                } else {
                    return
                }
                event.accepted = true
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 0

                // Главное меню: только текст, без значков (как в macOS 27)
                Column {
                    id: menuPage
                    Layout.fillWidth: true
                    visible: sys.page === "menu"

                    Repeater {
                        model: sys.menuItems
                        delegate: Item {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === sys.sel
                            width: menuPage.width
                            height: modelData.sep ? 13 : 28

                            // Разделитель: линия 1 px, отступы 6 px сверху и снизу, 12 px по бокам
                            Rectangle {
                                visible: entry.modelData.sep === true
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 1
                                color: "#1fffffff"
                            }

                            Rectangle {
                                visible: entry.modelData.sep !== true
                                anchors.fill: parent
                                radius: 8
                                color: entry.selected ? Theme.blue : "transparent"

                                // Название обрезается перед подсказкой сочетания
                                Label {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.right: keyHint.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.modelData.title ?? ""
                                    size: 13
                                    color: entry.selected ? "#ffffff" : Theme.fg
                                }
                                Label {
                                    id: keyHint
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.modelData.keys ?? ""
                                    size: 12
                                    color: entry.selected ? "#d9ffffff" : Theme.muted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: sys.sel = entry.index
                                    onClicked: sys.activate(entry.index)
                                }
                            }
                        }
                    }
                }

                // Об этой системе
                ColumnLayout {
                    id: aboutPage
                    Layout.fillWidth: true
                    visible: sys.page === "about"
                    spacing: 0

                    SubHeader { title: "Об этой системе"; onBack: sys.page = "menu" }

                    Label {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        horizontalAlignment: Text.AlignHCenter
                        text: sys.osName
                        size: 15
                        bold: true
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: sys.host
                        size: 12
                        color: Theme.muted
                    }

                    Repeater {
                        model: sys.aboutRows
                        delegate: RowLayout {
                            id: aRow
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            spacing: 8

                            Label {
                                Layout.preferredWidth: 84
                                Layout.alignment: Qt.AlignTop
                                verticalAlignment: Text.AlignTop
                                text: aRow.modelData.label
                                size: 12
                                color: Theme.muted
                            }
                            Label {
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignTop
                                text: aRow.modelData.value
                                size: 12
                                wrapMode: Text.WordWrap
                                elide: Text.ElideNone
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.topMargin: 10
                        radius: 8
                        color: moreMouse.containsMouse ? Theme.blue : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: "Подробнее…"
                            size: 13
                            color: moreMouse.containsMouse ? "#ffffff" : Theme.fg
                        }
                        MouseArea {
                            id: moreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sys.launch(["alacritty", "--config-file", sys.home + "/.config/giga-niri/alacritty.toml",
                                                   "--hold", "-e", "fastfetch"])
                        }
                    }
                }

                // Завершить принудительно: список окон, выбор и «Завершить»
                ColumnLayout {
                    id: forcePage
                    Layout.fillWidth: true
                    visible: sys.page === "force"
                    spacing: 0

                    SubHeader { title: "Завершить принудительно"; onBack: sys.page = "menu" }

                    Label {
                        visible: sys.wins.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        horizontalAlignment: Text.AlignHCenter
                        text: "Нет открытых окон"
                        size: 12
                        color: Theme.muted
                    }

                    ListView {
                        id: winList
                        visible: sys.wins.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 240)
                        Layout.topMargin: 4
                        clip: true
                        model: sys.wins
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: wrow
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 40
                            radius: 8
                            color: index === sys.forceSel ? Theme.blue : (wm.containsMouse ? Theme.rowHover : "transparent")

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    width: parent.width
                                    text: wrow.modelData.title || wrow.modelData.app_id || "Окно"
                                    size: 13
                                    bold: true
                                    color: wrow.index === sys.forceSel ? "#ffffff" : Theme.fg
                                }
                                Label {
                                    width: parent.width
                                    text: wrow.modelData.app_id || ""
                                    size: 11
                                    color: wrow.index === sys.forceSel ? "#d9ffffff" : Theme.muted
                                }
                            }
                            MouseArea {
                                id: wm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sys.forceSel = wrow.index
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 6
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        spacing: 8

                        PillButton {
                            label: "Отмена"
                            tint: "#33ffffff"
                            textColor: Theme.fg
                            onActivated: sys.page = "menu"
                        }
                        PillButton {
                            label: "Завершить"
                            tint: Theme.red
                            active: sys.selPid() > 0
                            onActivated: sys.killSelected()
                        }
                    }
                }

                // Подтверждение: перезагрузка, выключение, выход. По умолчанию — «Отмена»
                ColumnLayout {
                    id: confirmPage
                    Layout.fillWidth: true
                    visible: sys.page.startsWith("confirm")
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                        text: sys.cf.q
                        size: 14
                        bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 14
                        Layout.bottomMargin: 6
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        spacing: 8

                        PillButton {
                            label: "Отмена"
                            tint: "#33ffffff"
                            textColor: Theme.fg
                            onActivated: sys.page = "menu"
                        }
                        PillButton {
                            label: sys.cf.btn
                            onActivated: sys.launch(sys.cf.cmd)
                        }
                    }
                }
            }
        }
    }
}
