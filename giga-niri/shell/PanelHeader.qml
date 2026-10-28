import QtQuick
import QtQuick.Layouts

// Шапка карточки: значок, заголовок, подзаголовок, справа — переключатель.
RowLayout {
    id: root

    property int iconCode: 0
    property color iconColor: Theme.blue
    property string title: ""
    property string subtitle: ""
    property bool showToggle: true
    property bool checked: false
    signal toggled()

    spacing: 12

    Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 12
        color: "#267aa2f7"
        Icon {
            anchors.centerIn: parent
            code: root.iconCode
            size: 20
            color: root.iconColor
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Label { text: root.title; size: 15; bold: true; Layout.fillWidth: true }
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
