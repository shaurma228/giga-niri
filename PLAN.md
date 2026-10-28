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
- [x] После перезахода niri пишет `node is ignored, skipping`, ошибки EGL больше нет, ни один процесс не держит NVIDIA. `prime-run glxinfo -B` → RTX 3050, XWayland работает
- [ ] NVIDIA всё равно не засыпает: драйвер сообщает `Runtime D3 status: Disabled by default` (`/proc/driver/nvidia/gpus/0000:01:00.0/power`), так было и в KDE с момента загрузки. Включается только системно: `options nvidia NVreg_DynamicPowerManagement=0x02` в `/etc/modprobe.d/` + `mkinitcpio -P` + перезагрузка. Решение пользователя, вне оформления
- [ ] Номер render-узла может смениться между загрузками (порядок драйверов). Проверять `ls -l /dev/dri/by-path/`, если NVIDIA снова не засыпает
- Заметка: при живой перезагрузке конфига с `ignore-drm-device` xwayland-satellite упал (panic, exit 101); niri перезапускает его по требованию, после перезахода всё работает

### 3. Обои
- [x] Свои обои «ночной город + боке»: `scripts/make-wallpaper.py` → `wallpapers/tokyo-glass.png` (2560x1440, без проблем с лицензией)
- [x] `awww-daemon` в автозапуске, картинка через симлинк `~/.config/giga-niri/wallpaper.png`
- [ ] Скрипт смены обоев с переходом `--transition-type grow`
- [x] Обои в Overview: `layer-rule` для `awww-daemon` с `place-within-backdrop`
- [ ] Опционально: видео-обои через mpvpaper (оценить нагрузку от блюра, который тогда пересчитывается каждый кадр)

### 4. Бар (waybar)
- [x] Тонкая полоса 30px сверху: `niri` (клик — Overview) │ рабочие столы │ заголовок окна … трей · раскладка · wifi · звук · батарея · часы
- [x] Модули `niri/workspaces`, `niri/window`, `niri/language` (EN/RU), `tray` (нужен для Throne), `network` (только `wlan0`, без throne-tun), `pulseaudio` (клик — pavucontrol), `battery` (BAT0), `clock` (клик — дата, подсказка — календарь)
- [x] Фон `rgba(22,22,30,0.6)` + xray-блюр niri (`layer-rule` для `waybar`), нижняя граница `rgba(122,162,247,0.12)`
- [x] Автозапуск в niri, установка `scripts/install.sh waybar`
- [x] Нагрузка: бар добавляет ~0.4 п.п. в простое
- Грабли: в `niri/language` общий `format` вместе с `format-en`/`format-ru` и `tooltip-format` даёт `argument not found` — общий `format` не задавать

### 5. Лаунчер и уведомления
- [x] fuzzel (`Mod+D`): по центру, 40 символов × 7 строк, радиус 24, фон `#1a1b26b8`, выделение `#7aa2f7` 28% со скруглением 14, совпадения `#bb9af7`, иконки Tela-dark как в KDE, шрифт Inter + запасной JetBrainsMono Nerd Font для значков
- [x] Блюр лаунчера настоящий (`xray false`): он открыт секунды. `geometry-corner-radius 24` в layer-rule, чтобы блюр не вылезал за скругление
- [x] mako: стекло `#1a1b26cc`, радиус 18, рамка `#7aa2f7`, критичные — `#f7768e` без таймаута, low — `#565f89`. xray-блюр + `geometry-corner-radius 18`
- [x] Грабли mako: `margin` входит в поверхность слоя, и блюр niri закрашивал прямоугольник вокруг карточки. Решение: `margin=0`, отступ от края через `outer-margin`
- [x] Меню питания `giga-niri/power-menu.sh` (fuzzel `--dmenu`): сон / выход / перезагрузка / выключение, для трёх последних подтверждение с «Отмена» по умолчанию. `Mod+Shift+Q` и значок 󰐥 в конце бара
- [ ] Пункт «Заблокировать» — после экрана блокировки (этап 7)

### 6. Анимации
- [x] Пружины с лёгким отскоком: workspace-switch (0.82/700), horizontal-view-movement и window-movement (0.85/750), window-resize (0.9/800), overview-open-close (0.88/650)
- [x] Шейдер `window-open` (`shaders/open.frag`, 340 мс, ease-out-cubic): окно проявляется, слегка увеличиваясь и поднимаясь, по нему проходит диагональный блик `#7aa2f7 → #bb9af7`
- [x] Шейдер `window-close` (`shaders/close.frag`, 420 мс, ease-out-quad): окно рассыпается на квадратики 8×8 снизу вверх со светящейся каймой
- [x] niri 26.04 не поддерживает `custom-shader path=`, поэтому `niri/cfg/animations.kdl` собирается скриптом `scripts/build-animations.py` из `niri/animations.kdl.in` и `shaders/*.frag`
- [x] Проверено: шейдеры компилируются (нет предупреждений в журнале), кадры из середины анимаций при `slowdown 8` сняты скриншотами
- [x] Замер (eDP 1080p@144, на фоне терминал Claude Code со спиннером): простой 6.6%, анимации 42.7% @ 120 МГц, открытие/закрытие окон по кругу 31.2% @ 132 МГц
- Заметка: во время open/close блюр под окном пропадает (ограничение niri 26.04), это видно как «прозрачные» обои под проявляющимся окном

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
