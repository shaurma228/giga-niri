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

### 0. Безопасность (готово)
- [x] Снимок KDE/GTK/Qt/dconf: `~/.config/niri-themes-backup/kde-snapshot-2026-10-28/`
- [x] Старое оформление (CachyOS + Noctalia) снято в бэкап
- [x] `scripts/check-kde.sh`
- [x] `scripts/install.sh` / `uninstall.sh` с белым списком

### 1. Базовый рабочий niri
- [x] Минимальный `config.kdl`: раскладка `us,ru`, тачпад, бинды
- [x] Мониторы: `output "HDMI-A-1"` 2560x1440@100 (основной), `output "eDP-1"` 1920x1080@144. Бинды переноса окон и рабочих столов между мониторами
- [x] Аварийные бинды: `Ctrl+Alt+Delete` выход, `Mod+Return` терминал, `Mod+Shift+/` подсказки
- [x] `environment {}`: `ELECTRON_OZONE_PLATFORM_HINT auto`, `QT_QPA_PLATFORMTHEME kde` (Qt-приложения как в Plasma). Курсор breeze как в KDE, агент polkit от KDE
- [x] `niri validate`, `check-kde.sh`
- [x] Вход в сессию: бинды, раскладка Meta+Space, тачпад
- [ ] Внешний монитор MSI 1440p: проверить `niri msg outputs`, когда будет подключён
- [x] Портал Secret в niri → KWallet (`xdg-desktop-portal/niri-portals.conf`)
- [x] `gnome-keyring` удалён: `org.freedesktop.secrets` и портал Secret в niri держит `ksecretd` (KWallet), `gh` видит токен
- [x] `qt5-wayland` установлен, Chrome (`Mod+B`) работает нативно на Wayland, ключи через KWallet
- [ ] Проверить диалог выбора файлов в niri (портал FileChooser: gnome без nautilus может не работать)

### 2. Стекло и рамки (сердце Tokyo Glass)
- [x] `layout`: gaps 16, `focus-ring` градиент `#7aa2f7 → #bb9af7` (`in="oklch shorter hue"`, `relative-to="workspace-view"`: перелив при прокрутке), неактивный `#3b4261`
- [x] `window-rule`: `geometry-corner-radius 18`, `clip-to-geometry true`, `draw-border-with-background false` (иначе заливка рамки просвечивает сквозь стекло), тени (softness 40, spread 4, y 8)
- [x] Глобальный `blur {}` (passes 3) и `background-effect { blur true }` для alacritty. Лаунчер, бар, уведомления — на этапах 4–5
- [x] alacritty в niri: `opacity 0.72`, Tokyo Night, JetBrainsMono Nerd Font, padding 16/14
- [x] Блюр в режиме xray (по умолчанию). `layout { background-color "transparent" }`, иначе обои не видны
- [x] Скрипт замера `scripts/gpu-bench.sh` (без root: по счётчику RC6). `intel_gpu_top` требует CAP_PERFMON, не используется
- [x] Замер на eDP 1080p @ 144 Гц (сценарий: 3 терминала, прокрутка колонок + Overview):

  | Конфигурация | Простой | Анимации | Ср. частота iGPU |
  |---|---|---|---|
  | Без эффектов | 2.4% | 30.5% | 96 МГц |
  | Стекло (xray-блюр, тени, градиент, обои) | 0.2% | 37.4% | 114 МГц |
  | Худший случай: обычный блюр на всех терминалах | 0.4% | 54.5% | 174 МГц |

  Частота далеко от максимума 1200 МГц, запас большой. NVIDIA (этап 2.5) не нужна.
- [ ] Повторить замер на MSI 2560x1440 @ 100 Гц, когда монитор будет подключён (ожидание: ~×1.25 к нагрузке)

### 2.5. NVIDIA: не рендерить, а отпустить
Рендер niri на NVIDIA отклонён: Intel загружен на ~15% своей частоты, все мониторы подключены к Intel (кадры пришлось бы копировать по PCIe), а dGPU под нагрузкой ест в разы больше.
Замер показал обратное: niri держал NVIDIA открытой, и она не засыпала ни разу (`runtime_suspended_time = 0`, P8 ~4 Вт).
- [x] `debug { ignore-drm-device "/dev/dri/renderD129" }` в `cfg/misc.kdl`
- [ ] После перезахода: `runtime_status` NVIDIA = `suspended`, `prime-run glxinfo -B` / игра будит её и работает
- [ ] Номер render-узла может смениться между загрузками (порядок драйверов). Проверять `ls -l /dev/dri/by-path/`, если NVIDIA снова не засыпает

### 3. Обои
- [x] Свои обои «ночной город + боке»: `scripts/make-wallpaper.py` → `wallpapers/tokyo-glass.png` (2560x1440, без проблем с лицензией)
- [x] `awww-daemon` в автозапуске, картинка через симлинк `~/.config/giga-niri/wallpaper.png`
- [ ] Скрипт смены обоев с переходом `--transition-type grow`
- [x] Обои в Overview: `layer-rule` для `awww-daemon` с `place-within-backdrop`
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
