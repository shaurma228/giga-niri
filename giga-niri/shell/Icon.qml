import QtQuick

// Значок Nerd Font по коду: Icon { code: 0xF0928 }
Text {
    property int code: 0
    property int size: 18

    text: code ? Theme.icon(code) : ""
    font.family: Theme.iconFont
    font.pixelSize: size
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
