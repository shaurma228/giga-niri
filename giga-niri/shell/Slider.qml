import QtQuick

// Ползунок 0..1 с градиентной заливкой. Сообщает moved(value), значение задаётся снаружи.
Item {
    id: root

    property real value: 0
    signal moved(real value)

    implicitHeight: 24

    function setFrom(x) { root.moved(Math.max(0, Math.min(1, x / width))) }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.track

        Rectangle {
            width: Math.max(height, parent.width * root.value)
            height: parent.height
            radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.blue }
                GradientStop { position: 1; color: Theme.magenta }
            }
        }
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        color: Theme.fg
        border.width: 3
        border.color: Theme.magenta
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
