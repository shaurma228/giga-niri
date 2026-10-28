#!/usr/bin/env python3
"""Обои «Golden Gate»: сумеречное небо, туман над заливом, подвесной мост и холмы.

    python3 -I scripts/make-wallpaper.py [путь] [ширина] [высота]

По умолчанию: wallpapers/golden-gate.png, 2560x1440. Рисуется с нуля
(без чужих изображений), seed фиксирован — результат всегда одинаковый.
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
out = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "wallpapers" / "golden-gate.png"
W = int(sys.argv[2]) if len(sys.argv) > 2 else 2560
H = int(sys.argv[3]) if len(sys.argv) > 3 else 1440
S = W / 2560
rnd = random.Random(2027)


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def vgradient(stops, w, h):
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
            if t0 <= t <= t1:
                k = (t - t0) / (t1 - t0)
                k = k * k * (3 - 2 * k)
                col.putpixel((0, y), tuple(round(a + (b - a) * k) for a, b in zip(hex_rgb(c0), hex_rgb(c1))))
                break
    return col.resize((w, h))


def glow(img, cx, cy, r, color, alpha, blur):
    layer = Image.new("RGBA", img.size)
    ImageDraw.Draw(layer).ellipse((cx - r, cy - r, cx + r, cy + r), fill=hex_rgb(color) + (alpha,))
    return Image.alpha_composite(img, layer.filter(ImageFilter.GaussianBlur(blur)))


def hills(img, base, amp, color, alpha, waves, blur=0):
    layer = Image.new("RGBA", img.size)
    pts = [(0, H)]
    for x in range(0, W + 8, 8):
        y = base
        for a, f, ph in waves:
            y += a * amp * math.sin(x / W * f * math.tau + ph)
        pts.append((x, y))
    pts.append((W, H))
    ImageDraw.Draw(layer).polygon(pts, fill=hex_rgb(color) + (alpha,))
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(img, layer)


# Небо: глубокий индиго сверху, пурпур и тёплое зарево у горизонта
img = vgradient([(0.0, "#0b0d24"), (0.32, "#241a4a"), (0.55, "#5b2a63"),
                 (0.68, "#b5506a"), (0.76, "#f08a5d"), (1.0, "#2a1838")], W, H).convert("RGBA")

# Зарево заката и пара мягких бликов
img = glow(img, W * 0.36, H * 0.72, 520 * S, "#ffb36b", 150, 160 * S)
img = glow(img, W * 0.80, H * 0.18, 380 * S, "#6a5cff", 60, 200 * S)

# Звёзды в верхней части
stars = Image.new("RGBA", img.size)
d = ImageDraw.Draw(stars)
for _ in range(int(220 * S)):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.42)
    r = rnd.choice((0.8, 1.0, 1.4)) * S
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, rnd.randint(60, 190)))
img = Image.alpha_composite(img, stars)

# Дальние холмы (за мостом)
img = hills(img, H * 0.70, 40 * S, "#3a2350", 255, [(1.0, 1.3, 0.4), (0.5, 3.1, 1.7)])
img = hills(img, H * 0.74, 30 * S, "#2b1a3f", 255, [(1.0, 2.2, 2.0), (0.4, 5.0, 0.3)])

# Мост: две башни, главный трос-цепная линия, подвесы и полотно
bridge = Image.new("RGBA", img.size)
d = ImageDraw.Draw(bridge)
red = hex_rgb("#c8452f")
deck_y = H * 0.775
t1, t2 = W * 0.30, W * 0.74
top = H * 0.50
tw = 26 * S
for tx in (t1, t2):
    d.rectangle((tx - tw / 2, top, tx - tw / 2 + 8 * S, deck_y + 40 * S), fill=red + (255,))
    d.rectangle((tx + tw / 2 - 8 * S, top, tx + tw / 2, deck_y + 40 * S), fill=red + (255,))
    for k in range(4):
        yy = top + 18 * S + k * (deck_y - top) / 4.2
        d.rectangle((tx - tw / 2, yy, tx + tw / 2, yy + 7 * S), fill=red + (255,))

def cable(x0, y0, x1, y1, sag):
    pts = []
    for i in range(101):
        t = i / 100
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + sag * 4 * t * (1 - t)
        pts.append((x, y))
    return pts

main = cable(t1, top + 6 * S, t2, top + 6 * S, deck_y - top - 30 * S)
left = cable(-W * 0.02, deck_y - 6 * S, t1, top + 6 * S, -(deck_y - top) * 0.25)
right = cable(t2, top + 6 * S, W * 1.02, deck_y - 6 * S, -(deck_y - top) * 0.25)
for c in (main, left, right):
    d.line(c, fill=red + (255,), width=max(2, int(5 * S)))
for c in (main, left, right):
    for i in range(0, 101, 3):
        x, y = c[i]
        if y < deck_y - 4:
            d.line((x, y, x, deck_y), fill=red + (150,), width=max(1, int(1.5 * S)))
d.rectangle((-10, deck_y, W + 10, deck_y + 12 * S), fill=hex_rgb("#a23a2a") + (255,))
img = Image.alpha_composite(img, bridge)

# Огоньки на полотне моста
lights = Image.new("RGBA", img.size)
d = ImageDraw.Draw(lights)
for i in range(int(70 * S)):
    x = rnd.uniform(0, W)
    d.ellipse((x - 2 * S, deck_y + 2 * S, x + 2 * S, deck_y + 6 * S), fill=hex_rgb("#ffd59a") + (220,))
img = Image.alpha_composite(img, lights.filter(ImageFilter.GaussianBlur(1.2 * S)))

# Туман: несколько полупрозрачных слоёв поверх опор
for base, alpha, blur in ((0.80, 120, 30), (0.84, 150, 40), (0.88, 170, 50)):
    img = hills(img, H * base, 18 * S, "#d9b4c9", alpha,
                [(1.0, rnd.uniform(1.5, 3.5), rnd.uniform(0, 6)), (0.6, rnd.uniform(4, 7), rnd.uniform(0, 6))],
                blur=blur * S)

# Ближние тёмные холмы
img = hills(img, H * 0.90, 40 * S, "#140d22", 255, [(1.0, 1.1, 2.6), (0.35, 3.7, 0.2)])
img = hills(img, H * 0.95, 26 * S, "#0b0716", 255, [(1.0, 1.7, 0.9), (0.3, 4.4, 1.1)])

# Виньетка
vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse((-W * 0.25, -H * 0.3, W * 1.25, H * 1.3), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(220 * S))
img = Image.composite(img, Image.new("RGBA", (W, H), (6, 5, 14, 255)), vig)

out.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").save(out, optimize=True)
print(out)
