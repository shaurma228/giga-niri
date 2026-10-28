#!/usr/bin/env bash
# Замер нагрузки Intel iGPU в сессии niri без root.
# Загрузка = доля времени вне сна RC6 (счётчик rc6_residency_ms в sysfs).
#
#   scripts/gpu-bench.sh            простой (idle) + анимации niri, по 10 с
#   scripts/gpu-bench.sh idle 20    только простой, 20 с
#
# Сценарий «анимации» открывает 3 терминала, гоняет фокус между колонками
# и Overview. Сценарий «окна» по кругу открывает и закрывает терминал
# (шейдеры window-open/window-close). Открытые скриптом окна закрываются.
set -euo pipefail

GT=/sys/class/drm/card1/gt/gt0
FREQ=/sys/class/drm/card1/gt_act_freq_mhz
TERM_CMD=(alacritty --config-file "$HOME/.config/giga-niri/alacritty.toml")

[[ -n "${NIRI_SOCKET:-}" ]] || { echo "Запускать внутри сессии niri" >&2; exit 2; }

# measure <секунд> [команда фоновой нагрузки...] — печатает загрузку и частоту
measure() {
    local secs=$1; shift
    local load_pid=""
    if [[ $# -gt 0 ]]; then "$@" & load_pid=$!; fi
    local rc0 t0 rc1 t1 fsum=0 n=0 f
    rc0=$(<"$GT/rc6_residency_ms"); t0=$(date +%s%3N)
    local end=$(( t0 + secs * 1000 ))
    while (( $(date +%s%3N) < end )); do
        f=$(<"$FREQ"); fsum=$(( fsum + f )); n=$(( n + 1 ))
        sleep 0.2
    done
    rc1=$(<"$GT/rc6_residency_ms"); t1=$(date +%s%3N)
    [[ -n "$load_pid" ]] && { kill "$load_pid" 2>/dev/null; wait "$load_pid" 2>/dev/null || true; }
    awk -v rc=$(( rc1 - rc0 )) -v dt=$(( t1 - t0 )) -v fs=$fsum -v n=$n \
        'BEGIN { b = 100 - 100 * rc / dt; if (b < 0) b = 0; printf "загрузка %5.1f%%  частота %4d МГц\n", b, fs / n }'
}

animate() {
    while true; do
        niri msg action focus-column-left;  sleep 0.35
        niri msg action focus-column-left;  sleep 0.35
        niri msg action focus-column-right; sleep 0.35
        niri msg action focus-column-right; sleep 0.35
        niri msg action toggle-overview;    sleep 0.6
        niri msg action toggle-overview;    sleep 0.6
    done
}

open_close() {
    while true; do
        niri msg action spawn -- "${TERM_CMD[@]}" -T giga-bench-oc
        sleep 0.9
        niri msg -j windows | python3 -I -c 'import json,sys; [print(w["id"]) for w in json.load(sys.stdin) if w["title"]=="giga-bench-oc"]' \
            | while read -r id; do niri msg action close-window --id "$id"; done
        sleep 0.9
    done
}

mode=${1:-all}
secs=${2:-10}
outputs=$(niri msg -j outputs | python3 -I -c '
import json, sys
out = []
for name, o in json.load(sys.stdin).items():
    if o.get("current_mode") is None:
        continue
    m = o["modes"][o["current_mode"]]
    out.append("%s %dx%d@%d" % (name, m["width"], m["height"], round(m["refresh_rate"] / 1000)))
print(", ".join(out))')
echo "Мониторы: $outputs"

printf 'простой     '; measure "$secs"
[[ "$mode" == idle ]] && exit 0

before=$(niri msg -j windows | python3 -I -c 'import json,sys; print(" ".join(str(w["id"]) for w in json.load(sys.stdin)))')
for _ in 1 2 3; do niri msg action spawn -- "${TERM_CMD[@]}"; sleep 0.7; done
sleep 1
printf 'анимации    '; measure "$secs" animate
printf 'окна        '; measure "$secs" open_close
sleep 1
for id in $(niri msg -j windows | python3 -I -c 'import json,sys; print(" ".join(str(w["id"]) for w in json.load(sys.stdin)))'); do
    [[ " $before " == *" $id "* ]] || niri msg action close-window --id "$id"
done
