# giga-niri

Собственное оформление niri 26.04 в стиле **macOS 27 Golden Gate, тёмный режим** (Liquid Glass) — без дока, с тайлингом niri. GitHub: https://github.com/shaurma228/giga-niri (публичный, ветка `main`). Локальная папка — `~/niri-ixdi`. Журнал решений и чек-листы — `PLAN.md` (отмечать выполненное).

Общайся с пользователем по-русски.

**Режим работы — оркестратор** (просьба пользователя): исследования, правки и проверки отдавать субагентам на Haiku (`Agent`, `model: "haiku"`, независимые — параллельно). У субагента нет истории сессии: давать полный контекст (пути, правила отсюда, критерии готовности, что вернуть) и запрещать коммит. Самому — планировать, проверять результат (diff, скриншоты, `check-kde.sh`), коммитить и отчитываться. Мелкие правки в пару строк можно делать самому.

## Система

- CachyOS (Arch). Пакеты — `pacman`, AUR — `yay`. **`sudo` агенту недоступен**: команды установки отдавать пользователю как `! sudo pacman -S ...`.
- niri 26.04, вход через Plasma Login Manager (сессия `niri-session`). Рядом KDE Plasma 6.8.
- Ноутбук: i5-12450H, Intel UHD (Alder Lake-P, 48 EU) + NVIDIA RTX 3050 Mobile. Все выходы на Intel (`card1`/`renderD128`); niri не открывает NVIDIA (`debug { ignore-drm-device "/dev/dri/renderD129" }`), игры — через `prime-run`. Сон NVIDIA запрещён драйвером (`Runtime D3: Disabled by default`) — системная настройка, решение за пользователем.
- Мониторы: eDP-1 1920×1080@144 и основной внешний MSI 2560×1440@100 (HDMI-A-1, справа). Производительность мерить на 1440p.
- **Турбо-буст CPU выключен пользователем (auto-cpufreq). Не включать, не трогать auto-cpufreq/intel_pstate/профили питания.**

## Главное правило: не ломать KDE

- Не трогать `~/.config/kdeglobals`, `kwinrc`, `plasma*rc`, `gtk-3.0/`, `gtk-4.0/`, `Trolltech.conf`, `xsettingsd/`, `alacritty/`, dconf/gsettings, `/etc` (в т.ч. logind.conf). Не ставить/не удалять пакеты `cachyos-*-settings`.
- Темы для niri — только внутри сессии: блок `environment {}` niri или отдельные конфиги программ, которых нет в KDE. Alacritty в niri — `--config-file ~/.config/giga-niri/alacritty.toml` (подключает общий конфиг и переопределяет тему).
- Конфиги ставятся симлинками через `scripts/install.sh` только по белому списку: `niri`, `waybar`, `fuzzel`, `mako`, `giga-niri`, `xdg-desktop-portal/niri-portals.conf`.
- `scripts/check-kde.sh` сравнивает KDE/GTK/Qt/alacritty/dconf с последним снимком в `~/.config/niri-themes-backup/kde-snapshot-*`. Запускать перед каждым коммитом и проверять **код возврата**, а не последнюю строку. Расхождение — сначала разобраться: если файл записал сам Plasma (по времени — вход в KDE, например смена обоев, позиции значков), снять новый снимок `--snapshot`; если наше — откатить.
- Чужие install-скрипты не запускать (авто-режим блокирует скачанный код): читать и повторять шаги вручную.

## Где что лежит

- `niri/` — конфиг (`config.kdl` + `cfg/*.kdl`). `cfg/animations.kdl` генерируется: править `niri/animations.kdl.in` и `shaders/*.frag`, затем `python3 -I scripts/build-animations.py` (niri 26.04 не умеет `custom-shader path=`).
- `niri/cfg/binds.kdl` — разделы `// == Раздел`, подписи `hotkey-overlay-title`; по ним строится подсказка `giga-niri/keybinds.py` (`Mod+Shift+/`). Новые действия без подписи — в словарь `ACTIONS` там же.
- `giga-niri/shell/` — Quickshell 0.3.2 (`qs -p ~/.config/giga-niri/shell`, автозапуск niri):
  - `shell.qml` — корень, IPC: `popup toggle <control|wifi|bluetooth|audio|calendar>`, `popup close`, `search toggle|close|setQuery <текст>`, `system toggle|close|page <menu|about|force|confirm-…>`.
  - `ControlCenterPanel.qml` (+ `Glass.qml`, `ThinSlider.qml`) — Пункт управления по образцу macOS 27; подстраницы `WifiPanel`, `BluetoothPanel`, `AudioPanel`; `CalendarPanel` — по клику на часы.
  - `SearchWindow.qml` — поиск по системе (`Alt+Space`): qalc, программы, окна, системные действия, `fd` по `$HOME`, `> команда`, Firefox.
  - `SystemMenu.qml` — меню системы как меню Apple (`Mod+Shift+Q`, значок слева в строке меню).
  - `Theme.qml` — цвета, шрифты, радиусы; `Icon.qml` центрирует рисунок значка по реальным границам.
- `waybar/` — строка меню; `fuzzel/` — только подсказка по клавишам; `mako/` — уведомления.
- `giga-niri/`: `alacritty.toml`, `hyprlock.conf`, `hypridle.conf` + `idle.sh` (простой как в KDE), `lid-inhibit.sh` (крышка на зарядке), `super-tap.py` (тап Super → поиск; работает только при группе `input`, которой нет — пользователь отказался), `wallpaper.png` → `wallpapers/golden-gate.png`. `power-menu.sh` больше не используется.
- `scripts/`: `install.sh`/`uninstall.sh`, `check-kde.sh`, `gpu-bench.sh` (нагрузка iGPU без root, результаты — в PLAN.md), `make-wallpaper.py`, `build-animations.py`, `install-icons.sh` + `make-mako-icons.sh`.
- `~/.config/niri-themes-backup/` — бэкапы прежних конфигов и снимки KDE.

## Дизайн

- Палитра Apple для тёмного режима: акцент `#0a84ff`, стекло `#1e1e20` ~80%, светлая кромка `#ffffff30`, текст `#f2f2f7`. Шрифт Inter (SF Pro нельзя по лицензии), значки — Nerd Font Material.
- Скругления: **22** у поверхностей (окна, поиск, меню системы, fuzzel, уведомления); внутри — **14**, концентрично (внутренний = внешний − отступ); окно Пункта управления/календаря/подстраниц — **30** (`Theme.panelRadius`, плитки-«пилюли»). QML: `Theme.radius`/`innerRadius`/`panelRadius`; те же числа в `niri/cfg/rules.kdl` (`giga-popup` = 30), `fuzzel/fuzzel.ini`, `mako/config`.
- Блюр даёт niri через `layer-rule`/`window-rule` (`background-effect`), с `geometry-corner-radius`, иначе блюр вылезает прямоугольником. У слоёв поверхность должна быть ровно по карточке (mako: `margin=0`, отступ — `outer-margin`).
- Иконки McMojave-circle в `~/.local/share/icons` (без sudo): fuzzel, mako (через вид `~/.local/share/giga-niri/mako-icons`) и Quickshell (`//@ pragma IconTheme`). KDE остаётся на Tela.

## Проверки и грабли

- После правки niri — `niri validate`; niri перечитывает конфиг сам. Аварийный выход всегда: `Ctrl+Alt+Delete { quit; }`, `Mod+Shift+Return` — терминал с обычным конфигом.
- **Проверки делать самому**: `niri msg` (windows, outputs, layers, action …), скриншоты `niri msg action screenshot-screen --show-pointer false --path <scratchpad>` и их чтение (кропы — `magick`), тестовые запуски с `timeout`. Пользователя просить только о невозможном (клавиши, пароль, физические действия). Скриншоты для README — на пустом рабочем столе, без личных данных (SSID, IP, список программ).
- Quickshell перечитывает файлы сам, но склеивает быстрые правки — тогда `touch shell.qml`; новый `.qml`-файл/прагма требуют перезапуска `qs`. Лог — `ls -t /run/user/1000/quickshell/by-id/*/log.qslog | head -1` (двоичный, смотреть хвост). API — `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`. «Not ready to accept queries» — подождать и повторить.
- Окна поиска, меню системы и fuzzel забирают клавиатуру целиком: повторное сочетание до niri не доходит, его надо ловить внутри окна (QML `Keys`, fuzzel `[key-bindings] cancel`), включая русскую раскладку.
- `pkill -f <шаблон>` убивает собственную оболочку, если шаблон в тексте команды — искать по имени (`pgrep -x qs`).
- Значки Nerd Font: Font Awesome (U+F000–F2FF) теряются при записи файлов — вставлять через `\uXXXX`/`\U000Fxxxx` в Python. В шрифтах интерфейса — вариант `JetBrainsMono Nerd Font Propo` (у обычного рисунок смещён в ячейке).
- Waybar: локализованная дата только `{:L…}` + `"locale": "ru_RU.utf8"`; в `niri/language` не задавать общий `format` вместе с `format-en/ru`.
- Секреты: везде KWallet (`ksecretd`). В niri бумажник открывается паролем входа через `plasma-kwallet-pam.service` (первая строка `niri/cfg/autostart.kdl`); без неё D-Bus поднимает второй `ksecretd` без пароля. Портал Secret для niri — kwallet (`xdg-desktop-portal/niri-portals.conf`). `gnome-keyring` удалён и не должен вернуться.
- Chrome: тема Qt (`system_theme: 2`), на Wayland нужен `qt5-wayland` — не удалять, тему Chrome не менять. Браузер по умолчанию — Firefox (`Mod+B`).
- Питание: **на зарядке ноутбук не засыпает и не гасит экран** (требование пользователя), от батареи — как в KDE (`idle.sh`).
- Коммиты: в конце `Co-Authored-By` и `Claude-Session` из напоминания системы; планы/черновики, которые пользователь просил не коммитить, держать в `.git/info/exclude`.
