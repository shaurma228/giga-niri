import QtQuick
import QtQuick.Layouts

// Строка списка (сеть, устройство): значок, название, подпись, справа — пометка.
Rectangle {
    id: root

    property int iconCode: 0
    property color iconColor: Theme.subtle
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property int trailingIcon: 0
    property bool active: false
    property bool busy: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 48
    radius: Theme.innerRadius
    color: active ? Theme.rowActive : (mouse.containsMouse ? Theme.rowHover : "transparent")
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Icon {
            code: root.iconCode
            color: root.active ? Theme.blue : root.iconColor
            Layout.preferredWidth: 22
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { text: root.title; bold: root.active; Layout.fillWidth: true }
            Label {
                text: root.subtitle
                size: 11
                color: root.active ? Theme.blue : Theme.muted
                visible: text !== ""
                Layout.fillWidth: true
            }
        }

        Label { text: root.trailing; size: 11; color: Theme.muted; visible: text !== "" }
        Icon {
            code: root.trailingIcon
            size: 14
            color: Theme.muted
            visible: root.trailingIcon !== 0
        }
        Icon {
            code: 0xF0450 // refresh
            size: 14
            color: Theme.blue
            visible: root.busy
            RotationAnimation on rotation {
                running: root.busy
                from: 0; to: 360; duration: 900; loops: Animation.Infinite
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
