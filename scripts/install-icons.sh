#!/usr/bin/env bash
# Круглые иконки в стиле macOS: McMojave-circle (github.com/vinceliuice/McMojave-circle)
# в ~/.local/share/icons. Без sudo и без запуска чужого install.sh: файлы копируются
# так же, как это делает его базовый вариант (без -light/-dark и цветных папок).
#
# Тема используется только в лаунчере (fuzzel) и уведомлениях (mako). KDE
# по-прежнему берёт свою тему из kdeglobals.
#
#   scripts/install-icons.sh
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST="$HOME/.local/share/icons/McMojave-circle"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ -e "$DEST" ]]; then
    echo "Уже установлено: $DEST"
else
    git clone -q --depth 1 https://github.com/vinceliuice/McMojave-circle.git "$TMP/src"
    SRC="$TMP/src"
    mkdir -p "$DEST/status"
    cp -r "$SRC"/COPYING "$SRC"/AUTHORS "$SRC"/src/index.theme "$DEST"/
    cp -r "$SRC"/src/{actions,animations,apps,categories,devices,emotes,emblems,mimes,places} "$DEST"/
    cp -r "$SRC"/src/status/{16,22,24,32,symbolic} "$DEST"/status/
    cp -r "$SRC"/links/{actions,apps,categories,devices,emotes,emblems,mimes,places,status} "$DEST"/
    (cd "$DEST" && for d in actions animations apps categories devices emotes emblems mimes places status; do
        ln -sf "$d" "$d@2x"
    done)
    gtk-update-icon-cache -q "$DEST"
    echo "Установлено: $DEST"
fi

"$REPO/scripts/make-mako-icons.sh"
command -v makoctl >/dev/null && makoctl reload 2>/dev/null || true
