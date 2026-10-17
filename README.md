# ScreenDoodle

[Українська](README.uk.md) | **English**

A tiny macOS menu bar app for drawing on top of your screen: annotate anything, clear it, undo, and keep working underneath.

![ScreenDoodle drawing over a window](docs/screenshot.png)

**Hotkeys**
- `⌃⌥D` — toggle drawing mode
- `⌃⌥C` — clear the screen

**Toolbar.** A floating panel appears while drawing: Pen, Text, Arrow, Object (Rectangle, Circle, Block), color picker, Undo, Clear, Exit.
- Text: pick *Text*, click anywhere, type, press `Return` or `Esc`. `[` / `]` change the text size too.
- Arrow, Rectangle, Circle, Block: drag to draw in the current color. Block is a translucent filled rectangle.

**While drawing**
- `1`–`6` — red, yellow, green, blue, white, black
- `[` / `]` — thinner / thicker pen
- `Z` — undo last stroke
- `C` — clear
- `Esc` or `D` — leave drawing mode

Strokes stay visible after you leave drawing mode, and mouse clicks pass through to the apps underneath. Works on all displays and over full-screen apps.

**Requirements:** macOS 12+, Apple Silicon (arm64).

## Build

```bash
./build.sh        # produces ./draw
./package.sh      # produces ScreenDoodle.app and ScreenDoodle.dmg
```

## Install an unsigned build

The app is ad-hoc signed, so Gatekeeper blocks it. After copying it to `/Applications`, run:

```bash
xattr -dr com.apple.quarantine "/Applications/ScreenDoodle.app"
```
