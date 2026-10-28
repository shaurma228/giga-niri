#!/usr/bin/env -S python3 -I
"""Одиночное нажатие Super открывает и закрывает лаунчер (fuzzel), как в KDE.

niri 26.04 вызывает бинды в момент нажатия, поэтому бинд на голый Super_L
срабатывал бы и при Super+D, Super+Q и т.д. Этот скрипт сам читает клавиатуру
и мышь (/dev/input, нужна группа input) и считает «тапом» нажатие Super,
во время которого не было других клавиш и кнопок мыши, отпущенное быстрее
TAP_MS. Тап открывает fuzzel, а если любое меню fuzzel уже открыто — закрывает.

Запускается только из автозапуска niri, поэтому на KDE не влияет.
Второй экземпляр сразу выходит.

    super-tap.py          работать
    super-tap.py --test   проверить распознавание на заготовленных сценариях
"""
import fcntl
import glob
import os
import select
import struct
import subprocess
import sys
import time

TAP_MS = 400
EV_KEY = 0x01
SUPER = {125, 126}  # KEY_LEFTMETA, KEY_RIGHTMETA
EVENT = struct.Struct("llHHi")  # struct input_event на 64-битной системе


class Tap:
    """Распознаёт тап Super по потоку событий (код клавиши, значение, время в мс)."""

    def __init__(self):
        self.down_at = None
        self.dirty = False

    def feed(self, code, value, ms):
        if value == 2:  # автоповтор
            return False
        if code in SUPER:
            if value == 1:
                self.down_at, self.dirty = ms, False
                return False
            tapped = self.down_at is not None and not self.dirty and ms - self.down_at <= TAP_MS
            self.down_at = None
            return tapped
        if value == 1 and self.down_at is not None:
            self.dirty = True
        return False


def toggle_launcher():
    if subprocess.run(["pkill", "-x", "fuzzel"]).returncode == 0:
        return
    subprocess.run(["niri", "msg", "action", "spawn", "--", "fuzzel"], check=False)


def open_devices(opened):
    for path in glob.glob("/dev/input/event*"):
        if path in opened.values():
            continue
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        except OSError:
            continue
        opened[fd] = path


def run():
    lock = open(os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "giga-niri-super-tap.lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return
    opened, tap, rescan_at = {}, Tap(), 0.0
    while True:
        if time.monotonic() >= rescan_at:  # новые клавиатуры и мыши
            open_devices(opened)
            rescan_at = time.monotonic() + 5
            if not opened:
                print("super-tap: нет доступа к /dev/input, нужна группа input", file=sys.stderr)
                return
        ready, _, _ = select.select(list(opened), [], [], 5)
        for fd in ready:
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:  # устройство отключили
                os.close(fd)
                del opened[fd]
                continue
            for off in range(0, len(data) - EVENT.size + 1, EVENT.size):
                sec, usec, etype, code, value = EVENT.unpack_from(data, off)
                if etype == EV_KEY and tap.feed(code, value, sec * 1000 + usec // 1000):
                    toggle_launcher()


def test():
    D, U, R = 1, 0, 2
    A, MOUSE = 30, 272  # KEY_A, BTN_LEFT
    cases = [
        ("тап Super", [(125, D, 0), (125, U, 120)], 1),
        ("правый Super", [(126, D, 0), (126, U, 90)], 1),
        ("Super+A", [(125, D, 0), (A, D, 50), (A, U, 80), (125, U, 120)], 0),
        ("Super+клик мыши", [(125, D, 0), (MOUSE, D, 40), (MOUSE, U, 70), (125, U, 150)], 0),
        ("долгое удержание", [(125, D, 0), (125, R, 300), (125, U, 900)], 0),
        ("A, потом тап Super", [(A, D, 0), (A, U, 30), (125, D, 100), (125, U, 200)], 1),
        ("Super+A, потом тап", [(125, D, 0), (A, D, 20), (A, U, 40), (125, U, 60),
                                (125, D, 500), (125, U, 600)], 1),
        ("автоповтор не мешает", [(125, D, 0), (125, R, 250), (125, U, 300)], 1),
    ]
    ok = True
    for name, events, want in cases:
        tap = Tap()
        got = sum(tap.feed(c, v, t) for c, v, t in events)
        ok &= got == want
        print(f"{'ok ' if got == want else 'FAIL'} {name}: {got} (ожидалось {want})")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    test() if "--test" in sys.argv else run()
