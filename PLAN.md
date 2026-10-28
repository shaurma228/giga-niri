# giga-niri: план

Цель: оформление niri 26.04 в стиле **Tokyo Glass** (вариант 4 на холсте https://claude.ai/artifact/RArT5iYez9QKcNaouDVL3u).
Ночной город с боке, матовое стекло, блюр окон и панелей, градиентные рамки `#7aa2f7 → #bb9af7`, палитра Tokyo Night.

Жёсткое требование: **оформление KDE не меняется**. Проверка `scripts/check-kde.sh` после каждого шага.

## Палитра Tokyo Night

| Роль | Цвет |
|---|---|
| bg-dark / bg | `#16161e` / `#1a1b26` |
| fg / subtle / comment | `#c0caf5` / `#a9b1d6` / `#565f89` |
| blue (основной акцент) | `#7aa2f7` |
| magenta (второй акцент) | `#bb9af7` |
| cyan / green / orange / red | `#7dcfff` / `#9ece6a` / `#ff9e64` / `#f7768e` |

Шрифты: Inter (интерфейс), JetBrains Mono Nerd (терминал, бар).

## Компоненты

| Что | Чем | Почему |
|---|---|---|
| Композитор | niri 26.04 | блюр, градиенты, шейдеры, Overview |
| Бар | waybar | тонкая полоса сверху как на макете, стилизуется CSS, блюр через layer-rule niri |
| Лаунчер | fuzzel | лёгкий, скругления, прозрачность. Градиентной обводки нет: если понадобится, перейдём на свой лаунчер на quickshell (этап 7) |
| Уведомления | mako | простой, тема через конфиг |
| Обои | awww (статичные) / mpvpaper (видео) | плавные переходы, layer-shell |
| Терминал | alacritty с **отдельным** конфигом | общий `~/.config/alacritty/alacritty.toml` не трогаем: в niri запускаем `alacritty --config-file ~/.config/giga-niri/alacritty.toml` |
| Блокировка / простой | hyprlock + hypridle (или swaylock-effects + swayidle) | работают через ext-session-lock, который niri поддерживает |
| Скриншоты | встроенные в niri | без лишних пакетов |

## Структура репозитория

```
giga-niri/
├── niri/            config.kdl + cfg/*.kdl  →  ~/.config/niri
├── waybar/          config.jsonc, style.css →  ~/.config/waybar
├── fuzzel/          fuzzel.ini              →  ~/.config/fuzzel
├── mako/            config                  →  ~/.config/mako
├── giga-niri/       alacritty.toml, hyprlock.conf и др. → ~/.config/giga-niri
├── shaders/         GLSL анимации открытия/закрытия/ресайза
├── wallpapers/      обои (свои или с лицензией)
└── scripts/
    ├── install.sh   только симлинки в разрешённые папки + бэкап
    ├── uninstall.sh снять симлинки, вернуть бэкап
    └── check-kde.sh сравнить KDE/GTK/Qt/dconf со снимком
```

`install.sh` содержит белый список целевых папок и отказывается писать в `kdeglobals`, `gtk-*`, `kwinrc`, `plasma*`, `Trolltech.conf`, dconf и `/etc`.

## Этапы

### 0. Безопасность (почти готово)
- [x] Снимок KDE/GTK/Qt/dconf: `~/.config/niri-themes-backup/kde-snapshot-2026-10-28/`
- [x] Старое оформление (CachyOS + Noctalia) снято в бэкап
- [ ] `scripts/check-kde.sh`
- [ ] `scripts/install.sh` / `uninstall.sh` с белым списком

### 1. Базовый рабочий niri
- [ ] Минимальный `config.kdl`: раскладка `us,ru`, тачпад, монитор eDP-1, бинды
- [ ] Аварийные бинды: `Ctrl+Alt+Delete` выход, `Mod+Return` терминал, `Mod+Shift+/` подсказки
- [ ] `environment {}`: `QT_QPA_PLATFORM wayland`, `ELECTRON_OZONE_PLATFORM_HINT auto`. Qt-тему оставить `kde`, чтобы приложения выглядели как в Plasma
- [ ] Проверка: вход в сессию, все бинды, `niri validate`, `check-kde.sh`

### 2. Стекло и рамки (сердце Tokyo Glass)
- [ ] `layout`: gaps 16, `focus-ring` градиент `#7aa2f7 → #bb9af7` `in="oklch longer hue"`, неактивный тусклый
- [ ] `window-rule`: `geometry-corner-radius 18`, `clip-to-geometry true`, тени (softness 40, spread 4)
- [ ] Глобальный `blur {}` и `background-effect { blur true }` для терминала, лаунчера, бара, уведомлений
- [ ] Прозрачность: alacritty `opacity 0.72`, остальные окна непрозрачные (блюр на всех окнах тяжёлый)
- [ ] Проверка нагрузки на Intel UHD: `intel_gpu_top` (пакет `intel-gpu-tools`) + визуально, при подлагиваниях сначала включить xray-блюр

### 2.5. Эксперимент с NVIDIA (только если Intel не тянет)
Все выходы (eDP-1, HDMI, DP) подключены к Intel `card1`, у RTX 3050 (`card0`, `renderD129`) своих выходов нет. Рендер на NVIDIA = копирование каждого кадра через PCIe на Intel и постоянно активная dGPU (сейчас простаивает в P8 ~4 Вт).
- [ ] Выяснить, почему niri не смог инициализировать EGL на NVIDIA (`journalctl -b -1 | grep -i egl`). Пакеты `egl-gbm`, `egl-wayland`, профиль `limit-vram-usage` уже есть
- [ ] Отдельный `cfg/gpu-nvidia.kdl` с `debug { render-drm-device "/dev/dri/renderD129" }`, подключается одной строкой `include`
- [ ] Сравнить плавность и задержку, замерить потребление от батареи (`nvidia-smi`, `powertop`)
- [ ] Решение: Intel по умолчанию, NVIDIA как опциональный профиль «от сети»

### 3. Обои
- [ ] Подобрать обои «ночной город + боке» в 1920×1080 (с лицензией) или сгенерировать свои
- [ ] `awww-daemon` в `spawn-at-startup`, переход `--transition-type grow`
- [ ] Обои в Overview: `layer-rule` для `place-within-backdrop`
- [ ] Опционально: видео-обои через mpvpaper (оценить нагрузку от блюра, который тогда пересчитывается каждый кадр)

### 4. Бар (waybar)
- [ ] Тонкая полоса 30px сверху: `niri` · рабочие столы · заголовок окна | wifi · звук · часы
- [ ] Модули `niri/workspaces`, `niri/window`, `network`, `pulseaudio`, `battery`, `clock`
- [ ] Полупрозрачный фон `rgba(22,22,30,0.6)` + блюр niri, нижняя граница `rgba(122,162,247,0.12)`

### 5. Лаунчер и уведомления
- [ ] fuzzel: по центру, ширина ~560px, радиус 24, фон `#1a1b26b8`, выделение `#7aa2f7`, `Mod+D`
- [ ] mako: скругления, Tokyo Night, блюр через layer-rule
- [ ] Меню питания (fuzzel `--dmenu` скрипт): выход / блокировка / перезагрузка / выключение

### 6. Анимации
- [ ] Пружинные анимации для workspace-switch и Overview
- [ ] Свой шейдер `window-open`: появление с увеличением и растворением блюра
- [ ] Свой шейдер `window-close`: уменьшение и затухание
- [ ] Проверить, что шейдеры компилируются (иначе niri молча откатывается на стандартную анимацию, смотреть `journalctl`)

### 7. Полировка
- [ ] hyprlock в стиле Tokyo Glass, hypridle: гашение экрана, блокировка
- [ ] Курсор (Bibata Modern Ice) только в niri: `cursor {}` в конфиге niri
- [ ] Иконки, тема для GTK3-приложений только внутри niri (если возможно без dconf)
- [ ] Опционально: свой лаунчер или центр управления на quickshell с градиентной обводкой как на макете
- [ ] README со скриншотами

## Пакеты (ставит пользователь)

Этап 1–5:
```
sudo pacman -S --needed waybar fuzzel mako awww inter-font ttf-jetbrains-mono-nerd brightnessctl playerctl
```
Этап 7: `hyprlock hypridle`, `bibata-cursor-theme` (chaotic-aur).
Можно удалить старое: `sudo pacman -Rns noctalia adw-gtk-theme`.

## Риски

- Блюр и шейдеры рендерятся на Intel UHD. Обычный (не xray) блюр пересчитывается при изменении содержимого под ним.
- libadwaita/GTK4 берёт тёмную/светлую тему из общего dconf. Не трогаем, иначе изменится KDE.
- alacritty общий с KDE, поэтому для niri отдельный конфиг через `--config-file`.
