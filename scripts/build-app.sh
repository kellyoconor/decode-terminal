#!/bin/bash
set -euo pipefail

# Build a proper Decode.app bundle from the Swift Package Manager output
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$PROJECT_DIR/dist/Decode.app"
CONTENTS="$APP_DIR/Contents"

echo "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

# Copy binary
cp "$BUILD_DIR/Decode" "$CONTENTS/MacOS/Decode"

# Copy bundled resources (fonts etc)
if [ -d "$BUILD_DIR/Decode_Decode.bundle" ]; then
    cp -R "$BUILD_DIR/Decode_Decode.bundle" "$CONTENTS/Resources/"
fi

# Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Decode</string>
    <key>CFBundleDisplayName</key>
    <string>Decode</string>
    <key>CFBundleIdentifier</key>
    <string>com.decode.terminal</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>Decode</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

echo ""
echo "Done! App bundle at: $APP_DIR"
echo ""
echo "To run:  open $APP_DIR"
echo "To make DMG:  hdiutil create -volname Decode -srcfolder dist -ov -format UDZO dist/Decode.dmg"
