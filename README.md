# giga-niri

Оформление для [niri](https://github.com/niri-wm/niri) 26.04 в стиле **macOS 27 Golden Gate** (тёмный режим, Liquid Glass) — но без дока и с тайлингом: строка меню, Пункт управления, Spotlight, уведомления и экран блокировки как у Apple.

Сделано для CachyOS/Arch рядом с KDE Plasma: всё применяется только внутри сессии niri и не меняет темы KDE, GTK и Qt.

![Рабочий стол](docs/screenshots/desktop.png)

| Spotlight | Пункт управления |
|---|---|
| ![Spotlight](docs/screenshots/launcher.png) | ![Пункт управления](docs/screenshots/control-center.png) |

## Что внутри

- **Liquid Glass.** Окна и панели из матового стекла с блюром niri 26.04: плотнее, чем в Tahoe, со светлой кромкой — как в macOS 27. Скругления 22 у всех окон, тонкий светлый контур, у активного окна тень глубже. Цветной рамки фокуса нет.
- **Тайлинг niri** вместо дока: колонки, рабочие столы (точки в строке меню), Overview.
- **Анимации** без отскока: окно плавно вырастает при открытии и сжимается с затуханием при закрытии (свои GLSL-шейдеры).
- **Обои «Golden Gate»** — сумерки, мост и туман над заливом; нарисованы скриптом ([scripts/make-wallpaper.py](scripts/make-wallpaper.py)), без проблем с лицензией.
- **Строка меню** (waybar): значок системы (меню питания), имя активной программы, рабочие столы; справа трей, раскладка, батарея как на iPhone, Wi‑Fi, Spotlight, Пункт управления и дата по-русски.
- **Пункт управления** (Quickshell, [giga-niri/shell](giga-niri/shell)): плитка Wi‑Fi/Bluetooth, «Не беспокоить», «Заблокировать», ползунки «Дисплей» и «Звук», «Сейчас играет»; подстраницы Wi‑Fi (сети, подключение с паролем), Bluetooth (поиск, сопряжение), Звук (устройства вывода). Клик по часам — календарь.
- **Spotlight** (fuzzel): широкая стеклянная строка в верхней трети экрана, синее выделение.
- **Уведомления** (mako): стеклянные карточки справа сверху.
- **Иконки** McMojave-circle — значки в стиле macOS в кругах, в Spotlight и уведомлениях (`scripts/install-icons.sh`, ставится в `~/.local/share/icons` без sudo).
- **Экран блокировки** (hyprlock): дата и крупные часы сверху, имя и поле пароля-«пилюля» снизу.
- **Терминал**: системная палитра macOS для тёмного режима, стекло.
- **Питание как в KDE** (hypridle + [giga-niri/idle.sh](giga-niri/idle.sh)): на зарядке экран не гаснет и ноутбук не засыпает, в том числе при закрытой крышке ([giga-niri/lid-inhibit.sh](giga-niri/lid-inhibit.sh)); от батареи экран приглушается через 10 минут и гаснет через 30.

Шрифт интерфейса — Inter: SF Pro от Apple распространять нельзя, Inter ближе всего к нему.

## Клавиши

`Mod` — клавиша Super (Win). Полный список: `Mod+Shift+/` — своя подсказка на fuzzel в стиле лаунчера ([giga-niri/keybinds.py](giga-niri/keybinds.py)), строится из `binds.kdl`, Enter выполняет действие.

| Клавиши | Действие |
|---|---|
| `Mod+Return` | Терминал (alacritty с конфигом giga-niri) |
| `Super` (одиночное нажатие) | Открыть / закрыть Spotlight (нужна группа `input`, см. ниже) |
| `Mod+D` | Spotlight: открыть / закрыть |
| `Mod+E` / `Mod+B` | Файлы / Firefox |
| `Mod+O` | Overview |
| `Mod+Q` | Закрыть окно |
| `Mod+Shift+Q` | Меню питания |
| `Super+Alt+L` | Заблокировать |
| `Meta+Space` | Раскладка us/ru |
| `Ctrl+Alt+Delete` | Аварийный выход из niri |
| `Mod+Shift+Return` | Аварийный терминал с обычным конфигом alacritty |

## Установка

Пакеты:

```sh
sudo pacman -S --needed niri xwayland-satellite waybar fuzzel mako awww \
    alacritty inter-font ttf-jetbrains-mono-nerd brightnessctl playerctl \
    hyprlock hypridle qt5-wayland quickshell
```

Конфиги ставятся симлинками в `~/.config`. Установщик пишет только в папки из белого списка (`niri`, `waybar`, `fuzzel`, `mako`, `giga-niri`, `xdg-desktop-portal/niri-portals.conf`), существующие переносит в `~/.config/niri-themes-backup/`:

```sh
git clone https://github.com/shaurma228/giga-niri ~/giga-niri
cd ~/giga-niri
scripts/check-kde.sh --snapshot   # снимок настроек KDE до установки
scripts/install.sh                # или выборочно: scripts/install.sh niri waybar
```

Иконки: `scripts/install-icons.sh`.

Откат: `scripts/uninstall.sh`.

Конфиг рассчитан на конкретный ноутбук (мониторы, путь к render-узлу NVIDIA, иконки Tela). Перед установкой на другой машине поправьте `niri/cfg/outputs.kdl` и `niri/cfg/misc.kdl`.

### Лаунчер по одиночному Super

niri 26.04 вызывает бинды в момент нажатия, поэтому бинд на голый `Super_L` срабатывал бы и при `Super+D`. [giga-niri/super-tap.py](giga-niri/super-tap.py) сам читает `/dev/input` и считает «тапом» нажатие Super без других клавиш и кнопок мыши короче 400 мс. Для этого пользователь должен быть в группе `input` (`sudo usermod -aG input $USER` и перезаход); без неё скрипт сразу выходит. Учтите: группа `input` даёт программам пользователя читать нажатия клавиш напрямую.

## Совместимость с KDE

- Темы GTK/Qt, `kdeglobals`, dconf не трогаются. Переменные окружения задаются в блоке `environment {}` niri и действуют только в его сессии.
- У alacritty в niri свой конфиг, который подключает ваш обычный и переопределяет поверх него только тему.
- Секреты в обеих сессиях хранит KWallet: для niri портал Secret переключён на kwallet (`xdg-desktop-portal/niri-portals.conf`). `gnome-keyring` ставить не нужно.
- `scripts/check-kde.sh` сравнивает настройки KDE/GTK/Qt/dconf со снимком; `install.sh` запускает его до и после установки.

## Структура

```
niri/              config.kdl + cfg/*.kdl; animations.kdl собирается из animations.kdl.in
shaders/           GLSL открытия и закрытия окон
waybar/ fuzzel/ mako/
giga-niri/         alacritty, hyprlock, hypridle, меню питания, обои (симлинк)
wallpapers/        сгенерированные обои
scripts/           install, uninstall, check-kde, gpu-bench, make-wallpaper, build-animations
```

Шейдеры: niri 26.04 не умеет `custom-shader path=`, поэтому после правки `shaders/*.frag` нужно `python3 -I scripts/build-animations.py`.

## Производительность

Intel UHD (Alder Lake-P, 48 EU), 1920×1080 @ 144 Гц, замер `scripts/gpu-bench.sh` без root:

| Сценарий | Загрузка iGPU | Средняя частота |
|---|---|---|
| Простой | 0.5% | — |
| Анимации (прокрутка колонок, Overview) | 39.7% | 114 МГц |
| Открытие/закрытие окон по кругу | 25.6% | 84 МГц |

Частота далека от максимума 1200 МГц, NVIDIA для оформления не нужна: niri её не открывает (`ignore-drm-device`), игры запускаются через `prime-run`.

Подробный план и журнал решений: [PLAN.md](PLAN.md).
