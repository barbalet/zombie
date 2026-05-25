#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

OUT_DIR="zombie/build/ZombieDemo-$(date +%Y%m%d-%H%M%S)"
APP_PATH="$(xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' -showBuildSettings | awk '/TARGET_BUILD_DIR/ { dir=$3 } /FULL_PRODUCT_NAME/ { app=$3 } END { print dir "/" app }')"

xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' build
mkdir -p "$OUT_DIR"
cp -R "$APP_PATH" "$OUT_DIR/"
cp README.md PLAN.md "$OUT_DIR/"
cp zombie/docs/release-notes.md zombie/docs/demo-script.md zombie/docs/qa-checklist.md "$OUT_DIR/"
printf 'Packaged %s\n' "$OUT_DIR/Zombie.app"
