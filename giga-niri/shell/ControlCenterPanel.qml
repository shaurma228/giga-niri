import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Пункт управления в стиле macOS 27: плитки Wi-Fi/Bluetooth, «Не беспокоить»,
// блокировка, ползунки «Дисплей» и «Звук», «Сейчас играет».
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

    // Единый шаг 12: край карточки (Theme.pad), промежутки между плитками, поля плиток
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

    // Плитка — скруглённая подложка Пункта управления
    component Tile: Rectangle {
        radius: Theme.innerRadius
        color: Theme.tile
        border.width: 1
        border.color: "#12ffffff"
    }

    // Строка плитки связи: круглый значок-переключатель, название, состояние, «›»
    component ConnRow: RowLayout {
        id: conn
        property int iconCode: 0
        property bool on: false
        property string title: ""
        property string status: ""
        signal toggled()
        signal opened()
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: conn.on ? Theme.blue : "#33ffffff"
            Behavior on color { ColorAnimation { duration: 160 } }
            Icon { anchors.centerIn: parent; code: conn.iconCode; size: 17; color: "#ffffff" }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: conn.toggled()
            }
        }
        // Текст и «›» открывают подстраницу
        Item {
            Layout.fillWidth: true
            implicitHeight: 34
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: chevron.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Label { text: conn.title; size: 13; bold: true; Layout.fillWidth: true }
                Label { text: conn.status; size: 11; color: Theme.muted; Layout.fillWidth: true }
            }
            Icon { id: chevron; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; code: 0xF0142; size: 16; color: Theme.muted }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: conn.opened()
            }
        }
    }

    // Квадратная плитка-кнопка
    component SquareTile: Tile {
        id: sq
        property int iconCode: 0
        property bool on: false
        property string title: ""
        signal clicked()
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: on ? "#e6ffffff" : (sqMouse.containsMouse ? "#2bffffff" : Theme.tile)
        Behavior on color { ColorAnimation { duration: 160 } }

        // Значок и подпись в одну строку, по центру по вертикали
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: sq.on ? Theme.blue : "#33ffffff"
                Icon { anchors.centerIn: parent; code: sq.iconCode; size: 14; color: "#ffffff" }
            }
            Label {
                text: sq.title
                size: 11
                bold: true
                color: sq.on ? Theme.dark : Theme.fg
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
                Layout.fillWidth: true
            }
        }
        MouseArea {
            id: sqMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sq.clicked()
        }
    }

    // Связь + две квадратные плитки справа
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 116
        spacing: 12

        Tile {
            Layout.preferredWidth: 196
            Layout.fillHeight: true

            // Строки прижаты к верхнему и нижнему полю с одинаковым отступом 12
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                ConnRow {
                    Layout.fillWidth: true
                    iconCode: Networking.wifiEnabled ? 0xF0928 : 0xF092E
                    on: Networking.wifiEnabled
                    title: "Wi-Fi"
                    status: !Networking.wifiEnabled ? "Выкл." : root.wifiNet ? root.wifiNet.name : "Не подключено"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onOpened: root.open("wifi")
                }
                Item { Layout.fillHeight: true }
                ConnRow {
                    Layout.fillWidth: true
                    iconCode: root.adapter && root.adapter.enabled ? 0xF00AF : 0xF00B2
                    on: root.adapter !== null && root.adapter.enabled
                    title: "Bluetooth"
                    status: !on ? "Выкл." : root.btConnected.length ? root.btConnected.map(d => d.name).join(", ") : "Вкл."
                    onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                    onOpened: root.open("bluetooth")
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            SquareTile {
                iconCode: 0xF0594 // moon
                on: root.dnd
                title: "Не беспокоить"
                onClicked: root.toggleDnd()
            }
            SquareTile {
                iconCode: 0xF033E // lock
                title: "Блокировка"
                onClicked: {
                    root.requestClose()
                    Quickshell.execDetached(["loginctl", "lock-session"])
                }
            }
        }
    }

    // Дисплей. Высота по содержимому: поля 12 сверху и снизу ровные
    Tile {
        visible: root.hasBacklight
        Layout.fillWidth: true
        implicitHeight: displayCol.implicitHeight + 24
        ColumnLayout {
            id: displayCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            Label { text: "Дисплей"; size: 13; bold: true; Layout.preferredHeight: 18 }
            Slider {
                Layout.fillWidth: true
                iconCode: 0xF00DF // brightness
                value: root.brightness
                onMoved: v => root.setBrightness(v)
            }
        }
    }

    // Звук — та же раскладка, что у «Дисплея»
    Tile {
        Layout.fillWidth: true
        implicitHeight: soundCol.implicitHeight + 24
        ColumnLayout {
            id: soundCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Label { text: "Звук"; size: 13; bold: true; Layout.fillWidth: true }
                Icon {
                    code: 0xF0142
                    size: 16
                    color: Theme.muted
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.open("audio")
                    }
                }
            }
            Slider {
                Layout.fillWidth: true
                readonly property var audio: root.sink ? root.sink.audio : null
                iconCode: audio && audio.muted ? 0xF075F : 0xF057E
                value: audio ? Math.min(1, audio.volume) : 0
                opacity: audio && audio.muted ? 0.55 : 1
                onMoved: v => { if (audio) { audio.volume = v; if (audio.muted && v > 0) audio.muted = false } }
            }
        }
    }

    // Сейчас играет
    Tile {
        visible: root.player !== null
        Layout.fillWidth: true
        implicitHeight: 64

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
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
                    size: 18
                    visible: !root.player || root.player.trackArtUrl === ""
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label { text: root.player ? (root.player.trackTitle || root.player.identity) : ""; size: 13; bold: true; Layout.fillWidth: true }
                Label { text: root.player ? root.player.trackArtist : ""; size: 11; color: Theme.muted; Layout.fillWidth: true }
            }
            Repeater {
                model: [
                    { code: 0xF04AE, act: "previous" },
                    { code: 0, act: "toggle" },
                    { code: 0xF04AD, act: "next" },
                ]
                delegate: Icon {
                    required property var modelData
                    code: modelData.code || (root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A)
                    size: 20
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.player) return
                            if (modelData.act === "previous") root.player.previous()
                            else if (modelData.act === "next") root.player.next()
                            else root.player.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
