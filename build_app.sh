#!/bin/bash
# Builds SkibidiAltTab and packages it as a proper .app bundle
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "→ Building release binary..."
swift build -c release

BINARY=".build/release/SkibidiAltTab"
APP="SkibidiAltTab.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "→ Packaging $APP..."
rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BINARY" "$MACOS/SkibidiAltTab"

# Copy app icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.local.SkibidiAltTab</string>
    <key>CFBundleName</key>
    <string>SkibidiAltTab</string>
    <key>CFBundleExecutable</key>
    <string>SkibidiAltTab</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>SkibidiAltTab needs Accessibility access to intercept keyboard shortcuts globally.</string>
</dict>
</plist>
EOF

# Sign with the first valid Apple Development identity so the bundle has a stable
# identity across rebuilds. TCC (Accessibility) tracks by certificate, not binary hash,
# so permissions persist after every swift build.
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
    | grep -v REVOKED | grep "Apple Development" | head -1 | awk -F'"' '{print $2}')

if [ -z "$IDENTITY" ]; then
    # Fallback: ad-hoc (permissions will need re-granting after each rebuild)
    IDENTITY="-"
    echo "→ Signing (ad-hoc — no Apple Development cert found)"
else
    echo "→ Signing with: $IDENTITY"
fi

codesign --force --deep --sign "$IDENTITY" "$APP"

echo "✓ Built: $SCRIPT_DIR/$APP"
echo ""
echo "To run:"
echo "  open $SCRIPT_DIR/$APP"
