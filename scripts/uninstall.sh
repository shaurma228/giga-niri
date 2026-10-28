#!/usr/bin/env bash
# Снимает симлинки giga-niri и возвращает конфиги из последнего бэкапа install.sh.
#
#   scripts/uninstall.sh          все компоненты
#   scripts/uninstall.sh waybar   только перечисленные
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$HOME/.config"
ALLOWED=(niri waybar fuzzel mako giga-niri)
if [[ $# -gt 0 ]]; then components=("$@"); else components=("${ALLOWED[@]}"); fi

for c in "${components[@]}"; do
    dst="$CONFIG/$c"
    if [[ ! -L "$dst" || "$(readlink -f "$dst")" != "$REPO/$c" ]]; then
        echo "= $c: не установлен из репозитория, пропуск"
        continue
    fi
    rm "$dst"
    echo "- $c: симлинк снят"
    backup=$(ls -d "$CONFIG"/niri-themes-backup/giga-niri-install-*/"$c" 2>/dev/null | sort | tail -n1 || true)
    if [[ -n "$backup" ]]; then
        mv "$backup" "$dst"
        echo "~ $c: восстановлен из $backup"
    fi
done

"$REPO/scripts/check-kde.sh" || true
