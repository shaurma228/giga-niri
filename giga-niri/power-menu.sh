#!/usr/bin/env bash
# Меню питания на fuzzel. Открывается по Mod+Shift+Q и кликом по значку в баре.
# Выход, перезагрузка и выключение спрашивают подтверждение.
# «Заблокировать» идёт через loginctl lock-session → hypridle → hyprlock.
set -euo pipefail

menu() {
    fuzzel --dmenu --index --prompt "$1" --width 26 --lines "$2" --placeholder ""
}

choice=$(printf '%s\n' \
    "󰌾  Заблокировать" \
    "󰤄  Сон" \
    "󰍃  Выйти из niri" \
    "󰜉  Перезагрузка" \
    "󰐥  Выключение" | menu "󰐥  " 5) || exit 0

confirm() {
    # «Отмена» первой: случайный двойной Enter ничего не выключит
    [[ $(printf '%s\n' "󰅖  Отмена" "󰄬  Да, $1" | menu "󰋗  $1? " 2) == 1 ]]
}

case $choice in
    0) loginctl lock-session ;;
    1) systemctl suspend ;;
    2) confirm "выйти" && niri msg action quit --skip-confirmation ;;
    3) confirm "перезагрузить" && systemctl reboot ;;
    4) confirm "выключить" && systemctl poweroff ;;
esac
