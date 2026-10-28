import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// Wi-Fi: включение, список сетей, подключение (с паролем прямо в карточке).
ColumnLayout {
    id: root

    signal requestClose()
    signal requestBack()

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: wifi
        ? wifi.networks.values.filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
        : []
    readonly property var current: networks.find(n => n.connected) ?? null
    property var pskTarget: null

    spacing: 12

    // Пока карточка открыта, сканер включён и видны все сети вокруг, а не только
    // сохранённые. Binding сам вернёт прежнее значение при закрытии карточки.
    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: true
        when: root.wifi !== null
        restoreMode: Binding.RestoreValue
    }

    function strength(n) {
        const s = n.signalStrength > 1 ? n.signalStrength / 100 : n.signalStrength
        return s
    }
    function strengthIcon(n) {
        const s = strength(n)
        return s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F
    }
    function secured(n) { return n.security !== WifiSecurityType.Open }
    function status(n) {
        if (n.state === ConnectionState.Connecting) return "Подключение…"
        if (n.connected) return "Подключено"
        if (n.known) return "Сохранена"
        return secured(n) ? "Защищённая" : "Открытая"
    }
    function activate(n) {
        if (n.connected || n.stateChanging) return
        if (n.known || !secured(n)) {
            pskTarget = null
            n.connect()
        } else {
            pskTarget = pskTarget === n ? null : n
        }
    }

    PanelHeader {
        Layout.fillWidth: true
        iconCode: Networking.wifiEnabled ? 0xF0928 : 0xF092E
        title: "Wi-Fi"
        subtitle: !Networking.wifiEnabled ? "Выключен"
            : root.current ? root.current.name
            : "Не подключено"
        checked: Networking.wifiEnabled
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        onBack: root.requestBack()
    }

    Label {
        visible: Networking.wifiEnabled && root.networks.length === 0
        text: "Поиск сетей…"
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        Layout.bottomMargin: 8
    }

    ListView {
        id: list
        visible: Networking.wifiEnabled && root.networks.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 330)
        clip: true
        spacing: 4
        model: root.networks
        boundsBehavior: Flickable.StopAtBounds

        delegate: ColumnLayout {
            required property var modelData
            width: ListView.view.width
            spacing: 6

            ListRow {
                iconCode: root.strengthIcon(modelData)
                title: modelData.name
                subtitle: root.status(modelData)
                trailingIcon: root.secured(modelData) ? 0xF033E : 0
                active: modelData.connected
                busy: modelData.stateChanging
                onClicked: root.activate(modelData)
            }

            // Пароль для новой защищённой сети
            Rectangle {
                visible: root.pskTarget === modelData
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                implicitHeight: 40
                radius: 12
                color: Theme.row
                border.width: 1
                border.color: psk.activeFocus ? Theme.blue : Theme.track

                TextInput {
                    id: psk
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    focus: visible
                    onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                    onAccepted: {
                        if (text.length > 0) modelData.connectWithPsk(text)
                        root.pskTarget = null
                    }

                    Label {
                        visible: psk.text === ""
                        text: "Пароль и Enter"
                        color: Theme.muted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    FooterButton {
        text: "Параметры сети"
        onClicked: {
            Quickshell.execDetached(["systemsettings", "kcm_networkmanagement"])
            root.requestClose()
        }
    }
}
