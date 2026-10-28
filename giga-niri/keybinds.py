#!/usr/bin/env -S python3 -I
"""Подсказка по клавишам в стиле giga-niri (fuzzel), вместо встроенной в niri.

Список строится из ~/.config/niri/cfg/binds.kdl, поэтому всегда совпадает с
конфигом. Разделы — строки «// == Название». Подпись — hotkey-overlay-title,
иначе перевод действия. Бинды с hotkey-overlay-title=null не показываются.
Enter выполняет выбранное действие.

    keybinds.py           открыть подсказку
    keybinds.py --print   напечатать список (для проверки)
"""
import os
import re
import shlex
import subprocess
import sys

BINDS = os.path.expanduser("~/.config/niri/cfg/binds.kdl")

ACTIONS = {
    "toggle-overview": "Overview",
    "close-window": "Закрыть окно",
    "focus-column-left": "Фокус: колонка слева",
    "focus-column-right": "Фокус: колонка справа",
    "focus-window-down": "Фокус: окно ниже",
    "focus-window-up": "Фокус: окно выше",
    "move-column-left": "Сдвинуть колонку влево",
    "move-column-right": "Сдвинуть колонку вправо",
    "move-window-down": "Сдвинуть окно вниз",
    "move-window-up": "Сдвинуть окно вверх",
    "focus-column-first": "Фокус: первая колонка",
    "focus-column-last": "Фокус: последняя колонка",
    "move-column-to-first": "Колонку в начало",
    "move-column-to-last": "Колонку в конец",
    "focus-monitor-left": "Фокус: монитор слева",
    "focus-monitor-right": "Фокус: монитор справа",
    "move-column-to-monitor-left": "Колонку на монитор слева",
    "move-column-to-monitor-right": "Колонку на монитор справа",
    "move-workspace-to-monitor-left": "Рабочий стол на монитор слева",
    "move-workspace-to-monitor-right": "Рабочий стол на монитор справа",
    "focus-workspace-down": "Рабочий стол ниже",
    "focus-workspace-up": "Рабочий стол выше",
    "move-column-to-workspace-down": "Колонку на стол ниже",
    "move-column-to-workspace-up": "Колонку на стол выше",
    "move-workspace-down": "Переместить стол вниз",
    "move-workspace-up": "Переместить стол вверх",
    "focus-workspace": "Рабочий стол {}",
    "move-column-to-workspace": "Колонку на стол {}",
    "consume-or-expel-window-left": "Окно в колонку слева / из неё",
    "consume-or-expel-window-right": "Окно в колонку справа / из неё",
    "consume-window-into-column": "Забрать окно в колонку",
    "expel-window-from-column": "Вынуть окно из колонки",
    "switch-preset-column-width": "Ширина колонки: следующая",
    "switch-preset-column-width-back": "Ширина колонки: предыдущая",
    "switch-preset-window-height": "Высота окна: следующая",
    "reset-window-height": "Сбросить высоту окна",
    "maximize-column": "Колонка на всю ширину",
    "fullscreen-window": "Полный экран",
    "maximize-window-to-edges": "Развернуть окно до краёв",
    "expand-column-to-available-width": "Растянуть колонку на свободное место",
    "center-column": "Колонку по центру",
    "center-visible-columns": "Видимые колонки по центру",
    "set-column-width": "Ширина колонки {}",
    "set-window-height": "Высота окна {}",
    "toggle-window-floating": "Плавающее окно / в сетку",
    "switch-focus-between-floating-and-tiling": "Фокус: плавающие ↔ сетка",
    "toggle-column-tabbed-display": "Колонка вкладками",
    "screenshot": "Скриншот области",
    "screenshot-screen": "Скриншот экрана",
    "screenshot-window": "Скриншот окна",
    "toggle-keyboard-shortcuts-inhibit": "Отдать клавиши окну / вернуть",
    "quit": "Выйти из niri",
    "power-off-monitors": "Выключить мониторы",
    "show-hotkey-overlay": "Встроенная подсказка niri",
}

# Описания для медиаклавиш (у них нет hotkey-overlay-title)
MEDIA = {
    "XF86AudioRaiseVolume": "Громче",
    "XF86AudioLowerVolume": "Тише",
    "XF86AudioMute": "Выключить звук",
    "XF86AudioMicMute": "Выключить микрофон",
    "XF86AudioPlay": "Пауза / воспроизведение",
    "XF86AudioStop": "Стоп",
    "XF86AudioPrev": "Предыдущий трек",
    "XF86AudioNext": "Следующий трек",
    "XF86MonBrightnessUp": "Ярче",
    "XF86MonBrightnessDown": "Темнее",
}

KEYS = {
    "Mod": "Super", "Return": "Enter", "Slash": "/", "Page_Down": "PgDn",
    "Page_Up": "PgUp", "BracketLeft": "[", "BracketRight": "]", "Comma": ",",
    "Period": ".", "Minus": "-", "Equal": "=", "Escape": "Esc", "Delete": "Del",
    "Left": "←", "Right": "→", "Up": "↑", "Down": "↓",
    "WheelScrollDown": "Колесо↓", "WheelScrollUp": "Колесо↑",
    "WheelScrollLeft": "Колесо←", "WheelScrollRight": "Колесо→",
    "XF86AudioRaiseVolume": "Громк+", "XF86AudioLowerVolume": "Громк−",
    "XF86AudioMute": "Mute", "XF86AudioMicMute": "MicMute",
    "XF86AudioPlay": "Play", "XF86AudioStop": "Stop", "XF86AudioPrev": "Prev",
    "XF86AudioNext": "Next", "XF86MonBrightnessUp": "Ярк+",
    "XF86MonBrightnessDown": "Ярк−",
}

BIND_RE = re.compile(r"^\s{4}([A-Za-z0-9_+]+)((?:\s+[a-z-]+=(?:\"[^\"]*\"|\S+))*)\s*\{\s*(.*?);?\s*\}\s*$")
TITLE_RE = re.compile(r'hotkey-overlay-title=(null|"([^"]*)")')


def parse():
    section, rows = "", []
    for line in open(BINDS, encoding="utf-8"):
        if line.startswith("    // == "):
            section = line[len("    // == "):].strip().split(":")[0]
            continue
        m = BIND_RE.match(line.rstrip("\n"))
        if not m:
            continue
        key, props, action = m.groups()
        title = TITLE_RE.search(props)
        if title and title.group(1) == "null":
            continue
        words = shlex.split(action.rstrip(";"))
        if title:
            desc = title.group(2)
        elif key in MEDIA:
            desc = MEDIA[key]
        else:
            desc = ACTIONS.get(words[0], words[0]).format(*words[1:2])
        pretty = "+".join(KEYS.get(k, k) for k in key.split("+"))
        rows.append((section, pretty, desc, words))
    return rows


def run(words):
    name, args = words[0], words[1:]
    if name in ("spawn", "spawn-sh"):
        cmd = ["niri", "msg", "action", name, "--"] + (args if name == "spawn" else [" ".join(args)])
    else:
        cmd = ["niri", "msg", "action", name] + args
    subprocess.run(cmd, check=False)


def main():
    rows = parse()
    width = max(len(r[1]) for r in rows)
    lines = [f"{s:<14} {k:<{width}}   {d}" for s, k, d, _ in rows]
    if "--print" in sys.argv:
        print("\n".join(lines))
        return
    res = subprocess.run(
        ["fuzzel", "--dmenu", "--index",
         "--font", "JetBrainsMono Nerd Font:size=11",
         "--prompt", "\U000F030C  ", "--placeholder", "Поиск по клавишам и действиям",
         "--width", "78", "--lines", "16", "--line-height", "28"],
        input="\n".join(lines), capture_output=True, text=True)
    if res.returncode != 0 or not res.stdout.strip():
        return
    run(rows[int(res.stdout.strip())][3])


if __name__ == "__main__":
    main()
