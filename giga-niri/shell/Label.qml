import QtQuick

Text {
    property int size: 13
    property bool bold: false

    font.family: Theme.font
    font.pixelSize: size
    font.weight: bold ? Font.DemiBold : Font.Normal
    color: Theme.fg
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
