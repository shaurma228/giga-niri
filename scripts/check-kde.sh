#!/usr/bin/env bash
# Сравнивает текущие настройки KDE/GTK/Qt и dconf со снимком.
# Код выхода 0 — совпадает, 1 — есть расхождения, 2 — ошибка.
#
#   scripts/check-kde.sh            сравнить с последним снимком
#   scripts/check-kde.sh --snapshot снять новый снимок (когда изменения в KDE ваши)
set -euo pipefail

BACKUP_ROOT="$HOME/.config/niri-themes-backup"
# Файлы и папки KDE/GTK/Qt, которые оформление niri не должно менять.
PROTECTED=(
    kdeglobals kwinrc kdedefaults plasmarc plasmashellrc plasma-localerc
    plasma-org.kde.plasma.desktop-appletsrc gtk-3.0 gtk-4.0 gtkrc gtkrc-2.0
    Trolltech.conf xsettingsd qt5ct qt6ct Kvantum kcminputrc kscreenlockerrc
    kglobalshortcutsrc kxkbrc alacritty
)
# ksmserverrc не проверяется: KDE пишет туда список окон при каждом выходе.

existing() {
    local p
    for p in "${PROTECTED[@]}"; do
        [[ -e "$HOME/.config/$p" ]] && printf '%s\n' "$p"
    done
}

if [[ "${1:-}" == "--snapshot" ]]; then
    dir="$BACKUP_ROOT/kde-snapshot-$(date +%F-%H%M%S)"
    mkdir -p "$dir"
    mapfile -t items < <(existing)
    tar -czf "$dir/kde-config.tar.gz" -C "$HOME/.config" "${items[@]}"
    dconf dump / > "$dir/dconf-full.ini"
    echo "Снимок: $dir"
    exit 0
fi

snapshot=$(ls -d "$BACKUP_ROOT"/kde-snapshot-* 2>/dev/null | sort | tail -n1 || true)
if [[ -z "$snapshot" || ! -f "$snapshot/kde-config.tar.gz" ]]; then
    echo "Снимок KDE не найден в $BACKUP_ROOT. Снимите его: $0 --snapshot" >&2
    exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tar -xzf "$snapshot/kde-config.tar.gz" -C "$tmp"

status=0

# INI-файлы KDE переписывает сам: порядок строк и стороны пар
# в секциях [$InverseAction] меняются без изменения смысла.
normalize() {
    awk '
        /^\[.*\]$/ { sec = $0; next }
        /^[[:space:]]*$/ { next }
        sec ~ /\$InverseAction\]$/ && index($0, "=") {
            i = index($0, "="); a = substr($0, 1, i - 1); b = substr($0, i + 1)
            if (a > b) { t = a; a = b; b = t }
            print sec "\t" a "=" b; next
        }
        { print sec "\t" $0 }
    ' "$1" | LC_ALL=C sort
}

# Сравнивает файл или папку из снимка с текущими, печатает отличия.
compare() {
    local old=$1 new=$2 f rel out=""
    if [[ -f "$old" && -f "$new" ]]; then
        diff <(normalize "$old") <(normalize "$new") || return 1
        return 0
    fi
    # Файлы, которые есть только с одной стороны; содержимое сравнивается ниже.
    out=$(LC_ALL=C diff -rq "$old" "$new" 2>&1 | grep -v '^Files .* differ$' || true)
    out=${out//"$old"/снимок}
    while IFS= read -r f; do
        rel=${f#"$old"/}
        [[ -f "$new/$rel" ]] || continue
        diff <(normalize "$f") <(normalize "$new/$rel") >/dev/null \
            || out+=$'\n'"differ: $rel"
    done < <(find "$old" -type f)
    [[ -z "${out//$'\n'/}" ]] && return 0
    printf '%s\n' "$out" | sed '/^$/d'
    return 1
}

# Симлинк из защищённого места в репозиторий — точно наша ошибка.
for p in "${PROTECTED[@]}"; do
    if [[ -L "$HOME/.config/$p" ]]; then
        echo "ОШИБКА: ~/.config/$p — симлинк на $(readlink "$HOME/.config/$p")"
        status=1
    fi
done

for p in "${PROTECTED[@]}"; do
    if [[ -e "$tmp/$p" && ! -e "$HOME/.config/$p" ]]; then
        echo "Удалено: ~/.config/$p"
        status=1
    elif [[ ! -e "$tmp/$p" && -e "$HOME/.config/$p" ]]; then
        echo "Появилось: ~/.config/$p"
        status=1
    elif [[ -e "$tmp/$p" ]]; then
        if ! out=$(compare "$tmp/$p" "$HOME/.config/$p" 2>&1); then
            echo "Изменено: ~/.config/$p"
            printf '%s\n' "$out" | head -n 20 | sed 's/^/    /'
            status=1
        fi
    fi
done

if ! out=$(diff <(dconf dump /) "$snapshot/dconf-full.ini"); then
    echo "Изменено: dconf"
    printf '%s\n' "$out" | head -n 20 | sed 's/^/    /'
    status=1
fi

if [[ $status -eq 0 ]]; then
    echo "KDE не изменился (снимок $(basename "$snapshot"))"
else
    echo
    echo "Есть расхождения со снимком $(basename "$snapshot")."
    echo "Если это ваши изменения в настройках KDE, снимите новый снимок: $0 --snapshot"
fi
exit $status
