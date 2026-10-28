import QtQuick
import QtQuick.Layouts

// Кнопка внизу карточки: значок и текст, например «Параметры сети».
Rectangle {
    id: root

    property int iconCode: 0xF0493 // cog
    property string text: ""
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 40
    radius: Theme.innerRadius
    color: mouse.containsMouse ? Theme.rowHover : Theme.row
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 8
        Icon { code: root.iconCode; size: 15; color: Theme.subtle }
        Label { text: root.text; size: 12; color: Theme.subtle }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
