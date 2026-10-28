#!/usr/bin/env bash
# Ставит конфиги giga-niri симлинками в ~/.config.
# Пишет только в папки из белого списка, существующие папки переносит в бэкап.
#
#   scripts/install.sh            все компоненты, которые есть в репозитории
#   scripts/install.sh niri       только перечисленные
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$HOME/.config"
BACKUP="$CONFIG/niri-themes-backup/giga-niri-install-$(date +%F-%H%M%S)"
ALLOWED=(niri waybar fuzzel mako giga-niri)

allowed() {
    local a
    for a in "${ALLOWED[@]}"; do [[ "$a" == "$1" ]] && return 0; done
    return 1
}

if [[ $# -gt 0 ]]; then
    components=("$@")
else
    components=()
    for a in "${ALLOWED[@]}"; do [[ -d "$REPO/$a" ]] && components+=("$a"); done
fi

for c in "${components[@]}"; do
    allowed "$c" || { echo "Отказ: '$c' не в белом списке (${ALLOWED[*]})" >&2; exit 1; }
    [[ -d "$REPO/$c" ]] || { echo "Отказ: в репозитории нет папки $c" >&2; exit 1; }
done

echo "== Проверка KDE до установки"
"$REPO/scripts/check-kde.sh" || {
    echo "KDE уже отличается от снимка. Разберитесь до установки." >&2
    exit 1
}

for c in "${components[@]}"; do
    src="$REPO/$c"
    dst="$CONFIG/$c"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$src" ]]; then
        echo "= $c уже установлен"
        continue
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP"
        mv "$dst" "$BACKUP/$c"
        echo "~ $c: старый конфиг перенесён в $BACKUP/$c"
    fi
    ln -s "$src" "$dst"
    echo "+ $c → $dst"
done

mkdir -p "$HOME/Pictures/Screenshots"

if [[ -d "$REPO/niri" ]] && command -v niri >/dev/null; then
    echo "== niri validate"
    niri validate -c "$CONFIG/niri/config.kdl"
fi

echo "== Проверка KDE после установки"
"$REPO/scripts/check-kde.sh"
