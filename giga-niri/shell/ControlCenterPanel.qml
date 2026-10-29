import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Пункт управления в стиле macOS 27: стеклянные таблетки Wi-Fi/Bluetooth,
// «Сейчас играет», «Не беспокоить», круглые кнопки, блокировка, раскладка,
// тонкие ползунки «Дисплей» и «Звук».
ColumnLayout {
    id: root

    signal requestClose()
    signal open(string page)

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter ? adapter.devices.values.filter(d => d.connected) : []
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    property bool dnd: false
    property real brightness: 0
    property bool hasBacklight: false
    property string layout: ""

    readonly property var layoutShort: ({ "English (US)": "EN", "Russian": "RU" })

    // Единый шаг 12: край карточки (Theme.pad), промежутки между плитками и строками
    spacing: 12

    PwObjectTracker { objects: [root.sink].filter(n => n) }

    // «Не беспокоить» — режим mako
    Process {
        id: dndRead
        running: true
        command: ["makoctl", "mode"]
        stdout: StdioCollector { onStreamFinished: root.dnd = text.includes("do-not-disturb") }
    }
    function toggleDnd() {
        Quickshell.execDetached(["makoctl", "mode", "-t", "do-not-disturb"])
        dnd = !dnd
    }

    // Яркость встроенного экрана
    Process {
        id: brightRead
        running: true
        command: ["brightnessctl", "-m", "--class=backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 5) {
                    root.brightness = Number(f[2]) / Number(f[4])
                    root.hasBacklight = true
                }
            }
        }
    }
    function setBrightness(v) {
        brightness = Math.max(0.03, v)
        Quickshell.execDetached(["brightnessctl", "-q", "--class=backlight", "set", Math.round(brightness * 100) + "%"])
    }

    // Текущая раскладка клавиатуры из niri
    Process {
        id: keyRead
        running: true
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const k = JSON.parse(text)
                    const name = k.names[k.current_idx]
                    root.layout = root.layoutShort[name] ?? name.substring(0, 2).toUpperCase()
                } catch (e) {
                    root.layout = ""
                }
            }
        }
    }
    // После переключения раскладки niri обновляет состояние не сразу
    Timer {
        id: keyRefresh
        interval: 200
        onTriggered: keyRead.running = true
    }

    // Таблетка связи: круг слева (переключатель), название и состояние.
    // Круг переключает, остальная часть открывает подстраницу.
    component Pill: Glass {
        id: pill
        property int iconCode: 0
        property bool on: false
        property string title: ""
        property string subtitle: ""
        signal circleClicked()
        signal bodyClicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        hovered: bodyMa.containsMouse

        // Фоновая область идёт первой, чтобы кружок стоял над ней и ловил свои клики
        MouseArea {
            id: bodyMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.bodyClicked()
        }

        Rectangle {
            id: circ
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            radius: 20
            color: pill.on ? "#ffffff" : "#33ffffff"
            Icon {
                anchors.centerIn: parent
                code: pill.iconCode
                size: 20
                color: pill.on ? Theme.blue : "#ffffff"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.circleClicked()
            }
        }

        ColumnLayout {
            anchors.left: circ.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Label { text: pill.title; size: 13; bold: true; Layout.fillWidth: true }
            Label {
                text: pill.subtitle
                size: 11
                color: "#b3ffffff"
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }

    // Круглая кнопка 64 px с значком
    component CircleButton: Glass {
        id: cb
        property int iconCode: 0
        signal clicked()

        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        radius: 32
        hovered: cbMa.containsMouse

        Icon {
            anchors.centerIn: parent
            code: cb.iconCode
            size: 24
            color: "#ffffff"
        }
        MouseArea {
            id: cbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cb.clicked()
        }
    }

    // Строка 1: слева две таблетки связи, справа «Сейчас играет»
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Pill {
                iconCode: Networking.wifiEnabled ? 0xF0928 : 0xF092E
                on: Networking.wifiEnabled
                title: "Wi-Fi"
                subtitle: !Networking.wifiEnabled ? "Выкл." : root.wifiNet ? root.wifiNet.name : "Не подключено"
                onCircleClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                onBodyClicked: root.open("wifi")
            }
            Pill {
                iconCode: root.adapter && root.adapter.enabled ? 0xF00AF : 0xF00B2
                on: root.adapter !== null && root.adapter.enabled
                title: "Bluetooth"
                subtitle: !on ? "Выкл." : root.btConnected.length ? root.btConnected.map(d => d.name).join(", ") : "Вкл."
                onCircleClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                onBodyClicked: root.open("bluetooth")
            }
        }

        // Сейчас играет
        Glass {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 0

                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 10
                    color: "#33ffffff"
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Icon {
                        anchors.centerIn: parent
                        code: 0xF075A // music
                        size: 22
                        color: "#ffffff"
                        visible: !root.player || root.player.trackArtUrl === ""
                    }
                }

                Item { Layout.fillHeight: true }

                Label {
                    text: root.player ? (root.player.trackTitle || root.player.identity) : "Ничего не играет"
                    size: 13
                    bold: true
                    Layout.fillWidth: true
                }
                Label {
                    text: root.player ? root.player.trackArtist : ""
                    size: 11
                    color: "#b3ffffff"
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    opacity: root.player ? 1 : 0.4
                    enabled: root.player !== null

                    Icon {
                        code: 0xF04AE
                        size: 20
                        color: "#ffffff"
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player.previous()
                        }
                    }
                    Icon {
                        code: root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A
                        size: 26
                        color: "#ffffff"
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player.togglePlaying()
                        }
                    }
                    Icon {
                        code: 0xF04AD
                        size: 20
                        color: "#ffffff"
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player.next()
                        }
                    }
                }
            }
        }
    }

    // Строка 2: «Не беспокоить» и две круглые кнопки
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        spacing: 12

        Glass {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            hovered: dndMa.containsMouse

            MouseArea {
                id: dndMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleDnd()
            }
            Rectangle {
                id: dndCirc
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: root.dnd ? Theme.blue : "#33ffffff"
                Behavior on color { ColorAnimation { duration: 160 } }
                Icon {
                    anchors.centerIn: parent
                    code: 0xF0594 // moon
                    size: 20
                    color: "#ffffff"
                }
            }
            ColumnLayout {
                anchors.left: dndCirc.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                // Как в macOS: плитка «Фокус», режим — в подписи
                Label { text: "Фокус"; size: 13; bold: true; Layout.fillWidth: true }
                Label { text: root.dnd ? "Не беспокоить" : "Выкл."; size: 11; color: "#b3ffffff"; Layout.fillWidth: true }
            }
        }

        // Две круглые кнопки в правой половине строки
        RowLayout {
            Layout.preferredWidth: 162
            Layout.preferredHeight: 64
            spacing: 34

            // Скриншот: сначала закрыть Пункт, потом снимок (ждём, пока окно уйдёт)
            CircleButton {
                iconCode: 0xF0104 // camera
                onClicked: {
                    root.requestClose()
                    Quickshell.execDetached(["sh", "-c", "sleep 0.3; niri msg action screenshot"])
                }
            }
            // Обзор окон niri
            CircleButton {
                iconCode: 0xF0570 // grid
                onClicked: {
                    root.requestClose()
                    Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"])
                }
            }
        }
    }

    // Строка 3: блокировка и раскладка
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        spacing: 12

        Pill {
            iconCode: 0xF033E // lock
            title: "Блокировка"
            onCircleClicked: {
                root.requestClose()
                Quickshell.execDetached(["loginctl", "lock-session"])
            }
            onBodyClicked: {
                root.requestClose()
                Quickshell.execDetached(["loginctl", "lock-session"])
            }
        }
        Pill {
            iconCode: 0xF030C // keyboard
            title: "Раскладка"
            subtitle: root.layout
            onCircleClicked: {
                Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"])
                keyRefresh.restart()
            }
            onBodyClicked: {
                Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"])
                keyRefresh.restart()
            }
        }
    }

    // Дисплей. Высота по содержимому: поля 14 сверху и снизу ровные
    Glass {
        visible: root.hasBacklight
        Layout.fillWidth: true
        implicitHeight: displayCol.implicitHeight + 28
        radius: 26

        ColumnLayout {
            id: displayCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Label { text: "Дисплей"; size: 13; bold: true; Layout.preferredHeight: 18 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Icon { code: 0xF05A8; size: 14; color: "#ffffff" } // солнце
                ThinSlider {
                    Layout.fillWidth: true
                    value: root.brightness
                    onMoved: v => root.setBrightness(v)
                }
                Icon { code: 0xF05A8; size: 20; color: "#ffffff" }
            }
        }
    }

    // Звук: ползунок громкости и кнопка выбора выхода
    Glass {
        id: soundTile
        Layout.fillWidth: true
        implicitHeight: soundCol.implicitHeight + 28
        radius: 26

        readonly property var audio: root.sink ? root.sink.audio : null

        ColumnLayout {
            id: soundCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Label { text: "Звук"; size: 13; bold: true; Layout.preferredHeight: 18 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Icon { code: 0xF057F; size: 14; color: "#ffffff" }
                ThinSlider {
                    Layout.fillWidth: true
                    value: soundTile.audio ? Math.min(1, soundTile.audio.volume) : 0
                    opacity: soundTile.audio && soundTile.audio.muted ? 0.5 : 1
                    onMoved: v => {
                        const a = soundTile.audio
                        if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false }
                    }
                }
                Icon {
                    code: soundTile.audio && soundTile.audio.muted ? 0xF075F : 0xF057E
                    size: 20
                    color: "#ffffff"
                }
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: "#33ffffff"
                    Icon { anchors.centerIn: parent; code: 0xF04C3; size: 16; color: "#ffffff" }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.open("audio")
                    }
                }
            }
        }
    }
}
