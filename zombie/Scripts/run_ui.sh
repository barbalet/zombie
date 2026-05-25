#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test
