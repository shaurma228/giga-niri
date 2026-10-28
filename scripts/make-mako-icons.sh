#!/usr/bin/env bash
# mako ищет значки в раскладке «размер/категория» (как у Tela), а у
# McMojave-circle «категория/размер». Этот скрипт собирает из ссылок вид темы
# в нужной раскладке: ~/.local/share/giga-niri/mako-icons/<NxN>/<категория>
# (размер в имени папки, scalable → 48x48, см. ниже).
# Файлы не копируются, сама тема не меняется.
#
#   scripts/make-mako-icons.sh [тема]   (по умолчанию McMojave-circle)
set -euo pipefail

THEME=${1:-McMojave-circle}
SRC="$HOME/.local/share/icons/$THEME"
OUT="$HOME/.local/share/giga-niri/mako-icons"

[[ -d "$SRC" ]] || { echo "Нет темы $SRC" >&2; exit 1; }
rm -rf "$OUT"
mkdir -p "$OUT"

for cat_dir in "$SRC"/*/; do
    cat=$(basename "$cat_dir")
    [[ "$cat" == *@2x ]] && continue
    for size_dir in "$cat_dir"*/; do
        [[ -d "$size_dir" ]] || continue
        size=$(basename "$size_dir")
        # mako берёт размер из имени папки (strtol) и выбирает только размер,
        # равный max-icon-size или меньше. scalable для него = 0 и не выбирается,
        # поэтому SVG кладём как 48x48 (= max-icon-size в mako/config).
        case $size in
            scalable) size=48x48 ;;
            symbolic) continue ;;
            *[!0-9]*) continue ;;
            *) size=${size}x${size} ;;
        esac
        mkdir -p "$OUT/$size"
        ln -s "${size_dir%/}" "$OUT/$size/$cat"
    done
done
echo "$OUT"
