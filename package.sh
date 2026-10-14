#!/bin/bash
# Збирає ScreenDoodle.app і ScreenDoodle.dmg
set -e
cd "$(dirname "$0")"
./build.sh
APP="ScreenDoodle.app"
rm -rf "$APP" dmg_tmp ScreenDoodle.dmg
mkdir -p "$APP/Contents/MacOS"
cp draw "$APP/Contents/MacOS/draw"
mkdir -p "$APP/Contents/Resources" AppIcon.iconset
for sz in 16 32 128 256 512; do
  sips -z $sz $sz icon_1024.png --out AppIcon.iconset/icon_${sz}x${sz}.png >/dev/null
  sips -z $((sz*2)) $((sz*2)) icon_1024.png --out AppIcon.iconset/icon_${sz}x${sz}@2x.png >/dev/null
done
iconutil -c icns AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf AppIcon.iconset
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>ScreenDoodle</string>
<key>CFBundleDisplayName</key><string>ScreenDoodle</string>
<key>CFBundleIdentifier</key><string>local.oleg.malyuvalka</string>
<key>CFBundleExecutable</key><string>draw</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1.0</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
ditto --norsrc --noextattr --noqtn "$APP" clean.app && rm -rf "$APP" && mv clean.app "$APP"
codesign --force --deep --sign - "$APP"
mkdir dmg_tmp
ditto --norsrc --noextattr --noqtn "$APP" "dmg_tmp/$APP"
ln -s /Applications dmg_tmp/Applications
hdiutil create -volname "ScreenDoodle" -srcfolder dmg_tmp -ov -format UDZO ScreenDoodle.dmg >/dev/null
rm -rf dmg_tmp
echo "Готово: ScreenDoodle.dmg"
