# Варианты оформления niri (исследование 2026-10-28)

Наличие пакетов проверено через `pacman -Si` на этой системе. Остальное взято из веб-поиска субагентов. Звёзды и даты не перепроверялись.

## A. Dux Shell (бывший DankMaterialShell) + эффекты niri

- https://github.com/duxlabs-dev/dux-shell (старый адрес AvengeMedia/DankMaterialShell редиректит)
- Пакет: `dux-shell` 2.0.0 в `cachyos-extra-v3`, тянет `quickshell` 0.3.2.
- Официально поддерживает niri и уже использует блюр niri 26.04.
- Есть бар, лаунчер в стиле Spotlight, центр уведомлений, центр управления, экран блокировки, виджеты (CPU/GPU, медиа, погода) и цвета из обоев через matugen.
- Стиль: Material 3, аккуратно и современно, без перебора.
- Риск для KDE: средний. Шелл умеет сам перекрашивать GTK/Qt через matugen и qt6ct, это надо отключить или держать только в `environment {}` niri.

## B. iNiR (порт end-4 illogical-impulse на niri)

- https://github.com/snowarch/iNiR, около 1.9k звёзд
- Скриншот: https://github.com/snowarch/iNiR/blob/main/docs/images/iris-2.32-principal.webp
- Есть три стиля панелей: iRiS (стекло/frost), Material ii (плавающий бар), Waffle (под Win11). Плюс анимированный переключатель окон, видео-обои, Material You.
- Самый «тиктоковый» из найденного.
- Риск для KDE: высокий. `./setup install` меняет системные настройки и темы GTK/Qt (plasma-integration, darkly), умеет включать SDDM. Ставить только вручную, не запуская его установщик.

## C. Свой рис с нуля на возможностях niri 26.04

Полный контроль и нулевой риск для KDE, но больше ручной работы.

- Блюр (26.04): `background-effect { blur true }` в window-rule/layer-rule + глобальный `blur {}`.
- Свои GLSL-шейдеры на открытие/закрытие/ресайз окон (`custom-shader` в `animations {}`).
- Градиентные рамки: `focus-ring { active-gradient from="#ff0080" to="#00ffff" angle=45 in="oklch longer hue" }`.
- `geometry-corner-radius`, `shadow {}`, `opacity` для окон.
- Живые обои: `awww` (бывший swww, cachyos-extra-v3) или `mpvpaper` (cachyos) для видео.
- Цвета: `matugen` (cachyos-extra-v3) генерирует палитру из обоев сразу для niri, бара и терминала.
- Бар и лаунчер: waybar + fuzzel/rofi или свой виджет на quickshell.
- Палитры на выбор: неон/киберпанк, Catppuccin Mocha, Rosé Pine, Tokyo Night или динамическая из обоев.

## D. Готовые dotfiles (копировать вручную)

- saatvik333/niri-dotfiles: https://github.com/saatvik333/niri-dotfiles. Waybar, Rofi, awww, Wallust, переключение тем (Catppuccin/Gruvbox/Rosé Pine). Минимализм без зазоров. Установщик рассчитан на чистый Arch, запускать нельзя.
- Kanjurito/dotfiles: https://github.com/Kanjurito/dotfiles. Waybar + Eww + Quickshell, cava, fastfetch, классический unixporn. Мало звёзд.

## Не подходят

- Caelestia, end-4 illogical-impulse: только Hyprland (для niri есть только сырой форк).
- Noctalia: уже пробовали, от неё уходим.

## Сопутствующее (в репозиториях)

`qt6ct`, `kvantum`, `papirus-icon-theme`, `ttf-jetbrains-mono-nerd`, `bibata-cursor-theme` (chaotic-aur).

## Ограничения

libadwaita/GTK4 берёт тёмную тему из глобального dconf `color-scheme`, общего с KDE. Отдельно для niri это не настроить. Qt можно развести через `QT_QPA_PLATFORMTHEME=qt6ct` в `environment {}` niri.
