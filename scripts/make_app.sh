#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
APP=dist/Audiosmith.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Audiosmith "$APP/Contents/MacOS/Audiosmith"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
