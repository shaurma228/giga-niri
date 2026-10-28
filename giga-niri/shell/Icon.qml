import QtQuick

// Значок Nerd Font по коду: Icon { code: 0xF0928 }
// Центрируется сам рисунок символа (его реальные границы), а не ячейка шрифта:
// у значков Nerd Font рисунок часто смещён внутри ячейки.
Item {
    id: root

    property int code: 0
    property int size: 18
    property color color: Theme.fg

    implicitWidth: size
    implicitHeight: size

    TextMetrics {
        id: ink
        font: glyph.font
        text: glyph.text
    }

    Text {
        id: glyph
        text: root.code ? Theme.icon(root.code) : ""
        font.family: Theme.iconFont
        font.pixelSize: root.size
        color: root.color
        x: Math.round((root.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x)
        y: Math.round((root.height - ink.tightBoundingRect.height) / 2 - ink.tightBoundingRect.y - glyph.baselineOffset)
    }
}
