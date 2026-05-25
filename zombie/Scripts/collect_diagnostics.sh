#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
REPORT_DIR="zombie/reports/diagnostics"
mkdir -p "$REPORT_DIR"

swift run ZombieRegression > "$REPORT_DIR/regression.txt"
swift test > "$REPORT_DIR/unit.txt"
xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' build-for-testing > "$REPORT_DIR/xcode-build-for-testing.txt"
printf 'Diagnostics written to %s\n' "$REPORT_DIR"
