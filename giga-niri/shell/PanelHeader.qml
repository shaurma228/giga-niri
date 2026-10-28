import QtQuick
import QtQuick.Layouts

// Шапка подстраницы: «назад» в Пункт управления, круглый значок (синий, когда
// включено), заголовок, подзаголовок, справа — переключатель.
RowLayout {
    id: root

    property int iconCode: 0
    property bool iconActive: checked
    property string title: ""
    property string subtitle: ""
    property bool showToggle: true
    property bool showBack: true
    property bool checked: false
    signal toggled()
    signal back()

    spacing: 10

    Rectangle {
        visible: root.showBack
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 14
        color: backMouse.containsMouse ? Theme.rowHover : "transparent"
        Icon { anchors.centerIn: parent; code: 0xF0141; size: 18; color: Theme.subtle }
        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.back()
        }
    }

    Rectangle {
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        radius: 17
        color: root.iconActive ? Theme.blue : Theme.tile
        Icon {
            anchors.centerIn: parent
            code: root.iconCode
            size: 17
            color: "#ffffff"
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Label { text: root.title; size: 14; bold: true; Layout.fillWidth: true }
        Label {
            text: root.subtitle
            size: 12
            color: Theme.muted
            visible: text !== ""
            Layout.fillWidth: true
        }
    }

    Toggle {
        visible: root.showToggle
        checked: root.checked
        onToggled: root.toggled()
    }
}
