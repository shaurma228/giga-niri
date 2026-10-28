import QtQuick

// Ползунок в стиле Пункта управления macOS: толстая «пилюля», белая заливка,
// значок внутри слева. Значение 0..1 задаётся снаружи, движение сообщает moved().
Item {
    id: root

    property real value: 0
    property int iconCode: 0
    signal moved(real value)

    implicitHeight: 28

    function setFrom(x) { root.moved(Math.max(0, Math.min(1, x / width))) }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: "#2effffff"
        clip: true

        Rectangle {
            width: Math.max(track.height, track.width * root.value)
            height: track.height
            radius: track.radius
            color: "#f2ffffff"
        }
    }

    Icon {
        visible: root.iconCode !== 0
        code: root.iconCode
        size: 15
        x: 9
        anchors.verticalCenter: parent.verticalCenter
        color: root.value * root.width > 26 ? "#1c1c1e" : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
