import QtQuick

// Переключатель. checked задаётся снаружи, нажатие только сообщает toggled().
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.checked ? Theme.blue : Theme.track }
        GradientStop { position: 1; color: root.checked ? Theme.magenta : Theme.track }
    }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.dark : Theme.subtle
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
