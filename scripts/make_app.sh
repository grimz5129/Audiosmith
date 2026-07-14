#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
APP=dist/MicMerge.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/MicMerge "$APP/Contents/MacOS/MicMerge"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
