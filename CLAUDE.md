# giga-niri

Репозиторий собственного оформления (rice) niri. Выбран стиль **Tokyo Glass**: палитра Tokyo Night, матовое стекло, блюр, градиентные рамки `#7aa2f7 → #bb9af7`. Макет: вариант 4 на холсте https://claude.ai/artifact/RArT5iYez9QKcNaouDVL3u. План и чек-листы: `PLAN.md` (отмечать выполненные пункты). Локальная папка называется `~/niri-ixdi`.

Общайся с пользователем по-русски.

## Система

- CachyOS (Arch), ядро cachyos, пакеты ставит `pacman` (AUR через `paru`/`yay`, если есть).
- niri 26.04. Сессия запускается из Plasma Login Manager (`/usr/share/wayland-sessions/niri.desktop`, команда `niri-session`).
- Ноутбук: Intel UHD (Alder Lake-P) + NVIDIA RTX 3050 Mobile (гибрид), экран eDP-1 1920x1080. niri рендерит на Intel; тяжёлые шейдеры и блюр проверять на производительность.
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

- `~/.config/niri/` — активный конфиг niri. Сейчас пуст/отсутствует: niri сам создаст дефолтный при запуске.
- `~/.config/niri-themes-backup/` — бэкапы прежних оформлений (там лежит CachyOS + Noctalia, снятое 2026-10-28).
- `~/.config/niri.bak-2026-10-28/` — самый первый дефолтный конфиг niri.
- Эта папка (`~/niri-ixdi`) — исходники нового оформления, заметки, варианты.

## Установленное для прежней темы (можно удалить)

`noctalia`, `adw-gtk-theme`, `xdg-desktop-portal-gnome`, `gnome-keyring`, `wl-clipboard`, `xwayland-satellite`. `xwayland-satellite` и порталы нужны niri в любом случае — их оставлять.

## Работа с конфигом niri

- После любой правки: `niri validate` (проверяет `~/.config/niri/config.kdl`). niri перечитывает конфиг на лету.
- Конфиг можно делить через `include "./cfg/*.kdl"`.
- Всегда держать рабочий аварийный выход: `Ctrl+Alt+Delete { quit; }` и бинд на терминал, который не зависит от шелла/бара. Если бар или шелл (Noctalia, quickshell и т.п.) не запустится, сессия не должна превращаться в серый экран без выхода.
- Логи прошлой сессии: `journalctl -b -1 | grep -i niri`.
- `sudo` агенту недоступен: команды установки отдавать пользователю в виде `! sudo pacman -S ...`.
