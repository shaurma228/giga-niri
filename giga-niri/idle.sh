#!/usr/bin/env bash
# Действия при простое для hypridle с учётом питания. Повторяет настройки
# PowerDevil из KDE (~/.config/powerdevilrc):
#
#                     на зарядке   от батареи   низкий заряд (≤10%)
#   приглушить        никогда      10 мин       2 мин
#   выключить экран   никогда      30 мин       5 мин
#   сон               никогда      никогда      10 мин
#
#   idle.sh state                  ac | battery | low
#   idle.sh dim <состояния>        приглушить подсветку, если состояние в списке
#   idle.sh undim                  вернуть подсветку, если её приглушали мы
#   idle.sh screen-off <состояния> выключить мониторы
#   idle.sh screen-on              включить мониторы
#   idle.sh suspend <состояния>    уйти в сон
#
# Для проверки состояние можно подменить: GIGA_POWER_STATE=battery idle.sh ...
set -euo pipefail

LOW_LEVEL=10
DIMMED="${XDG_RUNTIME_DIR:-/tmp}/giga-niri-dimmed"

state() {
    if [[ -n "${GIGA_POWER_STATE:-}" ]]; then
        echo "$GIGA_POWER_STATE"
        return
    fi
    local ac
    for ac in /sys/class/power_supply/*/online; do
        [[ "$(<"$ac")" == 1 ]] && { echo ac; return; }
    done
    local cap
    cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
    if [[ -n "$cap" && "$cap" -le $LOW_LEVEL ]]; then echo low; else echo battery; fi
}

# matches "ac battery" → 0, если текущее состояние в списке
matches() {
    local s
    s=$(state)
    [[ " $* " == *" $s "* ]]
}

cmd=${1:-state}
shift || true

case $cmd in
    state) state ;;
    dim)
        matches "$@" || exit 0
        brightnessctl --class=backlight -q -s set 30%
        touch "$DIMMED"
        ;;
    undim)
        [[ -e "$DIMMED" ]] || exit 0
        brightnessctl --class=backlight -q -r >/dev/null
        rm -f "$DIMMED"
        ;;
    screen-off)
        matches "$@" || exit 0
        niri msg action power-off-monitors
        ;;
    screen-on) niri msg action power-on-monitors ;;
    suspend)
        matches "$@" || exit 0
        systemctl suspend
        ;;
    *) echo "неизвестная команда: $cmd" >&2; exit 2 ;;
esac
