#!/usr/bin/env bash
# Крышка как в KDE: на зарядке закрытие крышки только гасит экран (это делает
# сам niri), а не усыпляет ноутбук. В niri крышку обрабатывает systemd-logind
# и по умолчанию уходит в сон, поэтому на зарядке держим inhibitor
# handle-lid-switch. От батареи inhibitor снимается, и logind усыпляет как обычно.
#
# Системный /etc/systemd/logind.conf не меняется: он общий с KDE.
# Запускается из автозапуска niri, второй экземпляр сразу выходит.
set -euo pipefail

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/giga-niri-lid-inhibit.lock"
flock -n 9 || exit 0

IDLE="$(dirname "$(readlink -f "$0")")/idle.sh"
inhibitor=""

release() {
    [[ -n "$inhibitor" ]] && kill "$inhibitor" 2>/dev/null || true
    inhibitor=""
}
trap 'release; exit 0' INT TERM EXIT

while true; do
    if [[ "$("$IDLE" state)" == ac ]]; then
        if [[ -z "$inhibitor" ]] || ! kill -0 "$inhibitor" 2>/dev/null; then
            systemd-inhibit --what=handle-lid-switch --who=giga-niri \
                --why="На зарядке крышка только гасит экран (как в KDE)" \
                --mode=block sleep infinity &
            inhibitor=$!
        fi
    else
        release
    fi
    sleep 5
done
