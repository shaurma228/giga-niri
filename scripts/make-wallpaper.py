#!/usr/bin/env python3
"""Обои Tokyo Glass: ночное небо, боке и силуэт города в палитре Tokyo Night.

    python3 -I scripts/make-wallpaper.py [путь] [ширина] [высота]

По умолчанию: wallpapers/tokyo-glass.png, 2560x1440. Seed фиксирован,
поэтому результат всегда один и тот же.
"""
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
out = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "wallpapers" / "tokyo-glass.png"
W = int(sys.argv[2]) if len(sys.argv) > 2 else 2560
H = int(sys.argv[3]) if len(sys.argv) > 3 else 1440
rnd = random.Random(1999)


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


BLUE, CYAN, MAGENTA = hex_rgb("#7aa2f7"), hex_rgb("#7dcfff"), hex_rgb("#bb9af7")
RED, ORANGE, GREEN = hex_rgb("#f7768e"), hex_rgb("#ff9e64"), hex_rgb("#9ece6a")
YELLOW = hex_rgb("#e0af68")

# Небо: вертикальный градиент сверху вниз
stops = [(0.0, hex_rgb("#0f0f17")), (0.45, hex_rgb("#1a1b36")),
         (0.78, hex_rgb("#2a1e3f")), (1.0, hex_rgb("#3a2448"))]
sky = Image.new("RGB", (1, H))
for y in range(H):
    t = y / (H - 1)
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t0 <= t <= t1:
            k = (t - t0) / (t1 - t0)
            sky.putpixel((0, y), tuple(round(a + (b - a) * k) for a, b in zip(c0, c1)))
            break
img = sky.resize((W, H)).convert("RGBA")

# Боке: размытые цветные круги в два слоя (дальний сильнее размыт)
s = W / 2560
for blur, count, rmin, rmax, alpha in ((40, 18, 90, 220, 70), (16, 26, 30, 90, 95)):
    layer = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        r = rnd.uniform(rmin, rmax) * s
        x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.72)
        color = rnd.choice((BLUE, BLUE, MAGENTA, MAGENTA, CYAN, RED, ORANGE))
        d.ellipse((x - r, y - r, x + r, y + r), fill=color + (alpha,))
    img = Image.alpha_composite(img, layer.filter(ImageFilter.GaussianBlur(blur * s)))

# Дымка над горизонтом
haze = Image.new("RGBA", (W, H))
d = ImageDraw.Draw(haze)
d.ellipse((-W * 0.2, H * 0.55, W * 1.2, H * 1.15), fill=MAGENTA + (55,))
img = Image.alpha_composite(img, haze.filter(ImageFilter.GaussianBlur(120 * s)))

# Город: два ряда домов, дальний светлее, ближний почти чёрный, с окнами
for base, hmin, hmax, color, wins in ((0.80, 0.10, 0.30, "#16162a", 0.10),
                                      (0.86, 0.05, 0.22, "#0b0b12", 0.18)):
    layer = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(layer)
    x = -20 * s
    while x < W:
        bw = rnd.uniform(40, 130) * s
        top = H * (base - rnd.uniform(hmin, hmax))
        d.rectangle((x, top, x + bw, H), fill=hex_rgb(color) + (255,))
        if rnd.random() < 0.25:  # антенна
            ax = x + bw * rnd.uniform(0.3, 0.7)
            d.rectangle((ax, top - 40 * s, ax + 3 * s, top), fill=hex_rgb(color) + (255,))
            d.ellipse((ax - 3 * s, top - 46 * s, ax + 6 * s, top - 37 * s), fill=RED + (230,))
        wy = top + 14 * s
        while wy < H - 10 * s:
            wx = x + 8 * s
            while wx < x + bw - 12 * s:
                if rnd.random() < wins:
                    c = rnd.choice((YELLOW, YELLOW, CYAN, BLUE))
                    d.rectangle((wx, wy, wx + 6 * s, wy + 9 * s), fill=c + (rnd.randint(110, 200),))
                wx += 14 * s
            wy += 20 * s
        x += bw + rnd.uniform(-8, 14) * s
    img = Image.alpha_composite(img, layer)

# Лёгкая виньетка
vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse((-W * 0.25, -H * 0.35, W * 1.25, H * 1.35), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(200 * s))
dark = Image.new("RGBA", (W, H), (8, 8, 14, 255))
img = Image.composite(img, dark, vig)

out.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").save(out, optimize=True)
print(out)
