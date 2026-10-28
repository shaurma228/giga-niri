import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Bluetooth: включение, поиск, сопряжённые и найденные устройства.
ColumnLayout {
    id: root

    signal requestClose()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter !== null && adapter.enabled
    readonly property var devices: adapter
        ? adapter.devices.values.filter(d => d.name !== "" && d.name.replace(/-/g, ":") !== d.address)
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        : []
    readonly property var connectedNames: devices.filter(d => d.connected).map(d => d.name)
    property bool startedScan: false

    spacing: 12

    // Поиск, запущенный из карточки, останавливается при её закрытии
    Component.onDestruction: if (startedScan && adapter) adapter.discovering = false

    function deviceIcon(d) {
        const i = d.icon || ""
        if (i.includes("headset") || i.includes("headphone")) return 0xF02CB
        if (i.includes("audio") || i.includes("speaker")) return 0xF04C3
        if (i.includes("mouse")) return 0xF037D
        if (i.includes("keyboard")) return 0xF030C
        if (i.includes("gaming") || i.includes("joystick")) return 0xF0297
        if (i.includes("phone")) return 0xF03F2
        if (i.includes("computer")) return 0xF0322
        return 0xF00AF
    }
    function status(d) {
        if (d.pairing) return "Сопряжение…"
        if (d.state === BluetoothDeviceState.Connecting) return "Подключение…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Отключение…"
        if (d.connected) return "Подключено"
        return d.paired ? "Сопряжено" : "Доступно"
    }
    function activate(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else { d.trusted = true; d.pair() }
    }

    PanelHeader {
        Layout.fillWidth: true
        iconCode: root.enabled ? (root.connectedNames.length ? 0xF00B1 : 0xF00AF) : 0xF00B2
        title: "Bluetooth"
        subtitle: !root.adapter ? "Адаптер не найден"
            : !root.enabled ? "Выключен"
            : root.connectedNames.length ? root.connectedNames.join(", ")
            : "Нет подключений"
        checked: root.enabled
        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
    }

    ListRow {
        visible: root.enabled
        iconCode: 0xF0349 // magnify
        iconColor: Theme.magenta
        title: root.adapter && root.adapter.discovering ? "Идёт поиск устройств…" : "Найти устройства"
        busy: root.adapter !== null && root.adapter.discovering
        onClicked: {
            root.adapter.discovering = !root.adapter.discovering
            root.startedScan = root.adapter.discovering
        }
    }

    ListView {
        visible: root.enabled && root.devices.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 300)
        clip: true
        spacing: 4
        model: root.devices
        boundsBehavior: Flickable.StopAtBounds

        delegate: ListRow {
            required property var modelData
            width: ListView.view.width
            iconCode: root.deviceIcon(modelData)
            title: modelData.name
            subtitle: root.status(modelData)
            trailing: modelData.batteryAvailable
                ? Math.round((modelData.battery > 1 ? modelData.battery / 100 : modelData.battery) * 100) + "%"
                : ""
            active: modelData.connected
            busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                || modelData.state === BluetoothDeviceState.Disconnecting
            onClicked: root.activate(modelData)
        }
    }

    Label {
        visible: root.enabled && root.devices.length === 0
        text: "Устройств пока нет"
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
    }

    FooterButton {
        text: "Параметры Bluetooth"
        onClicked: {
            Quickshell.execDetached(["systemsettings", "kcm_bluetooth"])
            root.requestClose()
        }
    }
}
