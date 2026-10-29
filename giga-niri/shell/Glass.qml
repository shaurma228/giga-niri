import QtQuick

// Стеклянная подложка плитки Пункта управления: полупрозрачная заливка,
// светлая кромка и верхний блик. Скругление задаётся снаружи, по умолчанию — таблетка.
Rectangle {
    property bool hovered: false
    radius: 32
    color: hovered ? "#2bffffff" : "#1fffffff"
    border.width: 1
    border.color: "#24ffffff"
    Behavior on color { ColorAnimation { duration: 140 } }

    // Тонкий блик у верхней кромки, между скруглениями
    Rectangle {
        x: parent.radius
        y: 1
        width: Math.max(0, parent.width - parent.radius * 2)
        height: 1
        color: "#33ffffff"
    }
}
