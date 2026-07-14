#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
APP=dist/Audify.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Audify "$APP/Contents/MacOS/Audify"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
