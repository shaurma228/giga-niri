import QtQuick
import QtQuick.Layouts

// Календарь: крупное время, дата, месяц по-русски, листание месяцев.
ColumnLayout {
    id: root

    signal requestClose()

    readonly property var ru: Qt.locale("ru_RU")
    property date now: new Date()
    property int offset: 0 // сдвиг в месяцах от текущего

    readonly property int year: new Date(now.getFullYear(), now.getMonth() + offset, 1).getFullYear()
    readonly property int month: new Date(now.getFullYear(), now.getMonth() + offset, 1).getMonth()
    readonly property var cells: {
        const first = new Date(year, month, 1)
        const start = new Date(year, month, 1 - (first.getDay() + 6) % 7)
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                today: d.toDateString() === now.toDateString(),
                weekend: i % 7 >= 5,
            })
        }
        return out
    }

    spacing: 14

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        spacing: 0
        Label {
            text: Qt.formatTime(root.now, "HH:mm")
            size: 48
            bold: true
            font.letterSpacing: -1
        }
        Label {
            text: {
                const s = root.now.toLocaleDateString(root.ru, "dddd, d MMMM yyyy")
                return s.charAt(0).toUpperCase() + s.slice(1)
            }
            size: 14
            color: Theme.subtle
        }
    }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#1fffffff" }

    RowLayout {
        Layout.fillWidth: true

        Label {
            text: {
                const m = root.ru.standaloneMonthName(root.month, Locale.LongFormat)
                return m.charAt(0).toUpperCase() + m.slice(1) + " " + root.year
            }
            size: 15
            bold: true
            Layout.fillWidth: true
        }

        Label {
            visible: root.offset !== 0
            text: "Сегодня"
            size: 12
            color: Theme.blue
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.offset = 0
            }
        }

        Repeater {
            model: [{ code: 0xF0141, step: -1 }, { code: 0xF0142, step: 1 }]
            delegate: Rectangle {
                required property var modelData
                implicitWidth: 30
                implicitHeight: 30
                radius: Theme.innerRadius
                color: nav.containsMouse ? Theme.rowHover : "transparent"
                Icon { anchors.centerIn: parent; code: modelData.code; size: 18; color: Theme.subtle }
                MouseArea {
                    id: nav
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.offset += modelData.step
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
            delegate: Label {
                required property string modelData
                required property int index
                text: modelData
                size: 11
                color: Theme.muted
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: root.cells
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 12
                color: "transparent"

                // Сегодня — красный кружок, как в Календаре macOS
                Rectangle {
                    visible: modelData.today
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    radius: 16
                    color: Theme.red
                }

                Label {
                    anchors.centerIn: parent
                    text: modelData.day
                    bold: modelData.today
                    color: modelData.today ? "#ffffff"
                        : !modelData.inMonth ? "#48484a"
                        : modelData.weekend ? Theme.muted
                        : Theme.fg
                }
            }
        }
    }

    // Колесо мыши листает месяцы
    WheelHandler {
        onWheel: event => root.offset += event.angleDelta.y > 0 ? -1 : 1
    }
}
