#!/usr/bin/env bash
# Меню питания на fuzzel. Открывается по Mod+Shift+Q и кликом по значку в баре.
# Выход, перезагрузка и выключение спрашивают подтверждение.
set -euo pipefail

menu() {
    fuzzel --dmenu --index --prompt "$1" --width 26 --lines "$2" --placeholder ""
}

choice=$(printf '%s\n' \
    "󰤄  Сон" \
    "󰍃  Выйти из niri" \
    "󰜉  Перезагрузка" \
    "󰐥  Выключение" | menu "󰐥  " 4) || exit 0

confirm() {
    # «Отмена» первой: случайный двойной Enter ничего не выключит
    [[ $(printf '%s\n' "󰅖  Отмена" "󰄬  Да, $1" | menu "󰋗  $1? " 2) == 1 ]]
}

case $choice in
    0) systemctl suspend ;;
    1) confirm "выйти" && niri msg action quit --skip-confirmation ;;
    2) confirm "перезагрузить" && systemctl reboot ;;
    3) confirm "выключить" && systemctl poweroff ;;
esac
