#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f fastlane/.env.testflight ]]; then
  set -a
  source fastlane/.env.testflight
  set +a
fi

if [[ -z "${VIBE_BETA_ACCESS_TOKEN:-}" ]]; then
  echo "Missing VIBE_BETA_ACCESS_TOKEN in fastlane/.env.testflight." >&2
  echo "Run ./scripts/testflight.sh once, or add VIBE_BETA_ACCESS_TOKEN to fastlane/.env.testflight." >&2
  exit 1
fi

project="VibeMap.xcodeproj"
scheme="VibeMap"
configuration="Debug"
bundle_id="com.brianhakel.vibemap"
simulator_name="${VIBEMAP_SIMULATOR_NAME:-iPhone 17 Pro}"
derived_data_path="${VIBEMAP_SIM_DERIVED_DATA_PATH:-$PWD/build/codex-simulator-derived-data}"

simulator_id="${VIBEMAP_SIMULATOR_ID:-}"
simulator_line=""
if [[ -z "$simulator_id" ]]; then
  simulator_line="$(
    xcrun simctl list devices available |
      awk -v name="$simulator_name" '$0 ~ "^[[:space:]]*" name " \\(" { line = $0 } END { print line }'
  )"

  simulator_id="$(sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' <<<"$simulator_line")"
fi

if [[ -z "$simulator_id" || "$simulator_id" == "$simulator_line" ]]; then
  echo "Could not find an available simulator named '$simulator_name'." >&2
  echo "Set VIBEMAP_SIMULATOR_NAME or VIBEMAP_SIMULATOR_ID and rerun." >&2
  exit 1
fi

echo "Building VibeMap for $simulator_name with production API access."
xcodebuild build \
  -project "$project" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -destination "id=$simulator_id" \
  -derivedDataPath "$derived_data_path"

app_path="$derived_data_path/Build/Products/Debug-iphonesimulator/VibeMap.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app was not found at $app_path." >&2
  exit 1
fi

xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl install "$simulator_id" "$app_path"

# Persist the token for Debug builds so later manual launches still reach production.
xcrun simctl spawn "$simulator_id" defaults write "$bundle_id" vibes-yall.debug-beta-access-token "$VIBE_BETA_ACCESS_TOKEN"

xcrun simctl terminate "$simulator_id" "$bundle_id" >/dev/null 2>&1 || true
SIMCTL_CHILD_VIBE_BETA_ACCESS_TOKEN="$VIBE_BETA_ACCESS_TOKEN" \
  xcrun simctl launch --terminate-running-process "$simulator_id" "$bundle_id"

echo "Launched VibeMap on $simulator_name ($simulator_id) with https://api.vibesyall.com access."
