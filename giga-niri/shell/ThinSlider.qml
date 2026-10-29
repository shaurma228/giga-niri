import QtQuick

// Тонкий ползунок в стиле Пункта управления macOS 27: белая полоска 4 px,
// без постоянного ползунка; кружок появляется только при наведении и нажатии.
// API такой же, как у Slider.qml: value 0..1, сигнал moved(value).
Item {
    id: root

    property real value: 0
    signal moved(real value)

    implicitHeight: 20

    function setFrom(x) { root.moved(Math.max(0, Math.min(1, x / width))) }

    // Дорожка
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: "#40ffffff"

        // Заливка слева
        Rectangle {
            width: track.width * root.value
            height: track.height
            radius: track.radius
            color: "#ffffff"
        }
    }

    // Кружок при наведении и нажатии
    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: "#ffffff"
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        visible: ma.containsMouse || ma.pressed
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
