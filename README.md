# screen-doodle

A tiny macOS menu bar app for drawing on top of your screen: annotate anything, clear it, undo, and keep working underneath.

## English

**Hotkeys**
- `⌃⌥D` — toggle drawing mode
- `⌃⌥C` — clear the screen

**While drawing**
- `1`–`6` — red, yellow, green, blue, white, black
- `[` / `]` — thinner / thicker pen
- `Z` — undo last stroke
- `C` — clear
- `Esc` or `D` — leave drawing mode

Strokes stay visible after you leave drawing mode, and mouse clicks pass through to the apps underneath. Works on all displays and over full-screen apps.

**Requirements:** macOS 12+, Apple Silicon (arm64).

**Build**
```bash
./build.sh        # produces ./draw
./package.sh      # produces Малювалка.app and Малювалка.dmg
```

**Install of an unsigned build.** The app is ad-hoc signed, so Gatekeeper blocks it. After copying it to `/Applications`, run:
```bash
xattr -dr com.apple.quarantine "/Applications/Малювалка.app"
```

## Українська

Невеликий застосунок для macOS у рядку меню, який дозволяє малювати поверх екрана: позначати будь-що, стирати, скасовувати й далі працювати під малюнком.

**Гарячі клавіші**
- `⌃⌥D` — увімкнути або вимкнути режим малювання
- `⌃⌥C` — очистити екран

**У режимі малювання**
- `1`–`6` — червоний, жовтий, зелений, синій, білий, чорний
- `[` / `]` — тонший або товстіший пензель
- `Z` — скасувати останній штрих
- `C` — очистити
- `Esc` або `D` — вийти з режиму малювання

Штрихи лишаються видимими після виходу з режиму, а кліки проходять крізь до програм під ними. Працює на всіх дисплеях і поверх повноекранних програм.

**Вимоги:** macOS 12+, Apple Silicon (arm64).

**Збірка**
```bash
./build.sh        # створює ./draw
./package.sh      # створює Малювалка.app і Малювалка.dmg
```

**Встановлення незавіреної збірки.** Застосунок підписано ad-hoc, тому Gatekeeper його блокує. Після копіювання в `/Applications` виконай:
```bash
xattr -dr com.apple.quarantine "/Applications/Малювалка.app"
```
