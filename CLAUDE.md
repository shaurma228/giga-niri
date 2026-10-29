# giga-niri

Репозиторий собственного оформления (rice) niri. Стиль — **macOS 27 Golden Gate, тёмный режим** (Liquid Glass), но без дока и с тайлингом niri. Tokyo Glass (прежний стиль) заменён полностью по решению пользователя, остался только в истории git. Цвета — системная палитра Apple для тёмного режима (акцент `#0a84ff`, стекло `#1e1e20` ~80%, светлая кромка `#ffffff30`), шрифт Inter (SF Pro нельзя по лицензии). Скругления единые: **22** у всех поверхностей (окна, поиск, меню fuzzel, Пункт управления, уведомления), **14** у всего внутри них (строки, выделение, плитки, кнопки); в QML — `Theme.radius` / `Theme.innerRadius`, те же числа в `niri/cfg/rules.kdl`, `fuzzel/fuzzel.ini`, `mako/config`. План и чек-листы: `PLAN.md` (отмечать выполненные пункты). Локальная папка называется `~/niri-ixdi`.

Общайся с пользователем по-русски.

**Режим работы — оркестратор** (просьба пользователя): исследования, правки и проверки отдавать субагентам на Haiku (`Agent`, `model: "haiku"`, независимые — параллельно) с полным контекстом из этого файла и чёткими критериями готовности. Самому — планировать, проверять результат (diff, скриншоты, `check-kde.sh`), коммитить и отчитываться.

## Система

- CachyOS (Arch), ядро cachyos, пакеты ставит `pacman` (AUR через `paru`/`yay`, если есть).
- niri 26.04. Сессия запускается из Plasma Login Manager (`/usr/share/wayland-sessions/niri.desktop`, команда `niri-session`).
- Ноутбук: i5-12450H + Intel UHD (Alder Lake-P GT1, 48 EU, до 1200 МГц) + NVIDIA RTX 3050 Mobile (гибрид).
- Мониторы: встроенный eDP-1 1920x1080 @ 144 Гц (BOE) и **основной внешний** MSI 2560x1440 @ 100 Гц по HDMI-A-1. Конфиг niri должен поддерживать оба, производительность мерить на 1440p.
- Турбо-буст CPU отключён пользователем (`intel_pstate/no_turbo = 1`, управляет auto-cpufreq), CPU не выше 2.0 ГГц. **Никогда не включать турбо и не трогать auto-cpufreq/intel_pstate.** Частота iGPU от `no_turbo` не зависит. Все выходы подключены к Intel (`card1`, `renderD128`), у NVIDIA (`card0`, `renderD129`, драйвер nvidia-open 615) своих выходов нет. niri рендерит на Intel; при попытке инициализировать NVIDIA получил `Failed to initialize EGL`. Рендер на NVIDIA отклонён (PLAN.md, этап 2.5): niri игнорирует её через `debug { ignore-drm-device "/dev/dri/renderD129" }`, чтобы она засыпала; игры — через `prime-run`. Блюр и шейдеры проверять на производительность.
- GitHub: https://github.com/shaurma228/giga-niri (публичный, ветка `main`).
- Рядом стоит KDE Plasma 6.8 со своими темами.

## Главное правило: не ломать KDE

Требование пользователя: оформление niri ни при каких условиях не должно менять текущий вид KDE.

- Эталонный снимок настроек KDE/GTK/Qt и dconf: `~/.config/niri-themes-backup/kde-snapshot-2026-10-28/` (`kde-config.tar.gz` распаковывать в `~/.config`, `dconf-full.ini` загружать через `dconf load / <`).
- После любой установки сравнивать с ним: `tar -dzf …/kde-config.tar.gz -C ~/.config` и `diff <(dconf dump /) …/dconf-full.ini`. Любое расхождение = откат.
- У `qt5ct`/`qt6ct`/`Kvantum` сейчас нет конфигов. Если они появятся, то только для сессии niri (через `QT_QPA_PLATFORMTHEME` в `environment {}`), а не глобально.
- Шеллы и dotfiles с автотемингом (matugen, Dux Shell, iNiR) настраивать так, чтобы они не писали в `gtk-3.0/`, `gtk-4.0/`, `kdeglobals` и dconf.
- Не трогать `~/.config/kdeglobals`, `kwinrc`, `plasma*rc`, `gtk-3.0/`, `gtk-4.0/`, `Trolltech.conf`, `xsettingsd/` и глобальные `gsettings`/dconf.
- Не ставить и не удалять `cachyos-*-settings` пакеты. `cachyos-kde-settings` конфликтует с `cachyos-niri-noctalia` (оба предоставляют `cachyos-desktop-settings`), удалять его нельзя.
- Темы для niri задавать только внутри сессии niri: блок `environment {}` в конфиге niri (`QT_QPA_PLATFORMTHEME`, `GTK_THEME`, `XCURSOR_THEME` и т.п.) или отдельные конфиги программ, которых нет в KDE.
- `~/.config/alacritty/alacritty.toml` общий с KDE. Для niri только отдельный конфиг (`alacritty --config-file ~/.config/giga-niri/alacritty.toml`).
- Конфиги из репозитория ставятся симлинками через `scripts/install.sh` только в папки из белого списка (niri, waybar, fuzzel, mako, giga-niri).
- Чужие install-скрипты dotfiles не запускать вслепую: сначала прочитать, что они пишут в `~/.config` и `/etc`.

## Где что лежит

- `~/.config/niri` и `~/.config/giga-niri` — симлинки на папки `niri/` и `giga-niri/` этого репозитория (ставит `scripts/install.sh`). Правки в репозитории сразу действуют в niri.
- `scripts/gpu-bench.sh` — замер нагрузки iGPU в сессии niri (простой + анимации). Результаты записывать в PLAN.md.
- `shaders/*.frag` + `niri/animations.kdl.in` → `scripts/build-animations.py` → `niri/cfg/animations.kdl` (сгенерированный, руками не править). Проверка шейдеров: временно `slowdown 8.0` в сгенерированном файле, скриншоты в середине анимации, журнал на предупреждения; потом пересобрать.
- `scripts/make-wallpaper.py` — генератор обоев `wallpapers/golden-gate.png`; активные обои: симлинк `giga-niri/wallpaper.png`.
- `scripts/check-kde.sh` — сравнение KDE/GTK/Qt/dconf со снимком (`--snapshot` снять новый). Запускать после каждой установки; `install.sh` вызывает его сам.
- `~/.config/niri-themes-backup/` — бэкапы прежних оформлений (там лежит CachyOS + Noctalia, снятое 2026-10-28).
- `~/.config/niri.bak-2026-10-28/` — самый первый дефолтный конфиг niri.
- Эта папка (`~/niri-ixdi`) — исходники нового оформления, заметки, варианты.

## Установленное для прежней темы (можно удалить)

`noctalia`, `adw-gtk-theme`, `xdg-desktop-portal-gnome`, `wl-clipboard`, `xwayland-satellite` (`gnome-keyring` уже удалён). `xwayland-satellite` и порталы нужны niri в любом случае — их оставлять.

## Работа с конфигом niri

- После любой правки: `niri validate` (проверяет `~/.config/niri/config.kdl`). niri перечитывает конфиг на лету.
- Конфиг можно делить через `include "./cfg/*.kdl"`.
- Всегда держать рабочий аварийный выход: `Ctrl+Alt+Delete { quit; }` и бинд на терминал, который не зависит от шелла/бара. Если бар или шелл (Noctalia, quickshell и т.п.) не запустится, сессия не должна превращаться в серый экран без выхода.
- Логи прошлой сессии: `journalctl -b -1 | grep -i niri`.
- **Проверки делает агент сам**, не перекладывая на пользователя: если сессия niri запущена (`$NIRI_SOCKET` задан), использовать `niri msg` (outputs, windows, focused-window, action ...), журнал, тестовые запуски программ с `timeout`, скриншоты (`niri msg action screenshot-screen` и чтение файла из `~/Pictures/Screenshots`). Пользователя просить только о том, что невозможно проверить самому (например, физически подключить монитор).
- Chrome: в нём выбрана тема Qt (`system_theme: 2`), на Wayland работает благодаря `qt5-wayland` (не удалять). Тему Chrome не менять (она общая с KDE).
- Секреты: и в KDE, и в niri хранилище — KWallet (`ksecretd`). `gnome-keyring` удалён и не должен возвращаться: иначе в niri у Chrome и `gh` будут другие ключи. В niri бумажник разблокируется паролем от входа через `plasma-kwallet-pam.service` (первая строка `niri/cfg/autostart.kdl`); без неё D-Bus поднимает второй `ksecretd` без пароля и программы просят пароль бумажника.
- Значки Nerd Font: брать из диапазона Material Design (U+F0000+, например 󰐥), а не Font Awesome (U+F000–F2FF): последние теряются при записи файлов. Надёжно вставлять через `\U000Fxxxx` / `\uf240` в Python (так сделана горизонтальная батарея в waybar).
- Waybar: локализованные дни и месяцы только с флагом `L` (`{:L%a %d %b}`) и `"locale": "ru_RU.utf8"`.
- Питание: **на зарядке ноутбук не должен засыпать, выключаться и гасить экран** (требование пользователя). Простой — `giga-niri/hypridle.conf` + `giga-niri/idle.sh` (копия powerdevilrc), крышка — `giga-niri/lid-inhibit.sh`. Системный logind.conf не менять, профили питания не трогать (их ведёт auto-cpufreq).
- Горячие клавиши: заголовки разделов в `niri/cfg/binds.kdl` — строки `// == Раздел`, подписи — `hotkey-overlay-title`; по ним строится подсказка `giga-niri/keybinds.py`. Новые действия без подписи добавлять в словарь `ACTIONS` там же.
- Карточки Quickshell: `giga-niri/shell/` (симлинк в `~/.config/giga-niri/shell`). Quickshell сам перечитывает конфиг при изменении файлов, но несколько быстрых правок подряд может склеить: тогда `touch shell.qml`. Лог: файл из строки `Saving logs to` или вывод `qs`. API модулей смотреть в `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`.
- Не использовать `pkill -f <шаблон>`, если шаблон есть в тексте самой команды: убьёт собственную оболочку. Искать по имени процесса (`pgrep -x qs`).
- Иконки: McMojave-circle только для fuzzel и mako. Тему KDE (Tela в kdeglobals) не менять. После переустановки темы — `scripts/install-icons.sh` (пересобирает вид для mako).
- `sudo` агенту недоступен: команды установки отдавать пользователю в виде `! sudo pacman -S ...`.
