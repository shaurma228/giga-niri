import QtQuick

// Переключатель в стиле macOS: синий, когда включён.
// checked задаётся снаружи, нажатие только сообщает toggled().
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.blue : Theme.track
    Behavior on color { ColorAnimation { duration: 160 } }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: "#ffffff"
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
