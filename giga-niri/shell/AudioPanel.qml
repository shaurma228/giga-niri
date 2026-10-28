import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Звук: громкость, микрофон, выбор устройства вывода.
ColumnLayout {
    id: root

    signal requestClose()
    signal requestBack()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    spacing: 14

    // Без трекера у узлов нет данных о громкости
    PwObjectTracker { objects: [root.sink, root.source].filter(n => n) }

    function volumeIcon(node) {
        if (!node || !node.audio || node.audio.muted) return 0xF075F
        const v = node.audio.volume
        return v > 0.66 ? 0xF057E : v > 0.33 ? 0xF0580 : 0xF057F
    }

    PanelHeader {
        Layout.fillWidth: true
        iconCode: root.volumeIcon(root.sink)
        title: "Звук"
        subtitle: root.sink ? (root.sink.description || root.sink.nickname || root.sink.name) : "Нет устройства"
        showToggle: false
        iconActive: true
        onBack: root.requestBack()
    }

    Repeater {
        model: [
            { node: root.sink, on: 0xF057E, off: 0xF075F, name: "Громкость" },
            { node: root.source, on: 0xF036C, off: 0xF036D, name: "Микрофон" },
        ]

        delegate: RowLayout {
            required property var modelData
            readonly property var audio: modelData.node ? modelData.node.audio : null
            visible: audio !== null
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: Theme.innerRadius
                color: muteMouse.containsMouse ? Theme.rowHover : Theme.row
                Icon {
                    anchors.centerIn: parent
                    code: audio && audio.muted ? modelData.off : modelData.on
                    color: audio && audio.muted ? Theme.muted : Theme.fg
                    size: 17
                }
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audio.muted = !audio.muted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    Label { text: modelData.name; size: 12; color: Theme.subtle; Layout.fillWidth: true }
                    Label { text: audio ? Math.round(audio.volume * 100) + "%" : ""; size: 12; color: Theme.muted }
                }
                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 22
                    value: audio ? Math.min(1, audio.volume) : 0
                    opacity: audio && audio.muted ? 0.5 : 1
                    onMoved: v => { audio.volume = v; if (audio.muted && v > 0) audio.muted = false }
                }
            }
        }
    }

    Label {
        visible: root.sinks.length > 1
        text: "Устройство вывода"
        size: 12
        color: Theme.muted
    }

    Repeater {
        model: root.sinks.length > 1 ? root.sinks : []
        delegate: ListRow {
            required property var modelData
            iconCode: modelData === root.sink ? 0xF04C3 : 0xF04C3
            title: modelData.description || modelData.nickname || modelData.name
            active: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    FooterButton {
        iconCode: 0xF0493
        text: "Микшер"
        onClicked: {
            Quickshell.execDetached(["pavucontrol"])
            root.requestClose()
        }
    }
}
