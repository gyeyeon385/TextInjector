#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
xcodebuild -project "$ROOT/TextInjector.xcodeproj" -scheme TextInjector \
  -configuration Debug -derivedDataPath "$ROOT/build" build
printf '\nApp: %s/build/Build/Products/Debug/TextInjector.app\n' "$ROOT"
