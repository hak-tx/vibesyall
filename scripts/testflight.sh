#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f fastlane/.env.testflight ]]; then
  set -a
  source fastlane/.env.testflight
  set +a
fi

project="VibeMap.xcodeproj"
scheme="VibeMap"
configuration="Release"
team_id="${DEVELOPMENT_TEAM:-${FASTLANE_TEAM_ID:-9S372WGPR4}}"
date_stamp="$(date +%Y-%m-%d)"
time_stamp="$(date +%Y-%m-%d_%H-%M-%S)"
archive_dir="${VIBEMAP_ARCHIVE_DIR:-$PWD/build/Archives/$date_stamp}"
archive_path="${VIBEMAP_ARCHIVE_PATH:-$archive_dir/VibeMap $time_stamp.xcarchive}"
export_path="${VIBEMAP_EXPORT_PATH:-$PWD/build/testflight-upload/$time_stamp}"
export_options="$PWD/fastlane/ExportOptions.TestFlight.plist"
local_export_options="$PWD/fastlane/ExportOptions.TestFlightLocal.plist"
derived_data_path="${VIBEMAP_DERIVED_DATA_PATH:-$PWD/DerivedData/TestFlight}"
project_yml_backup="$(mktemp)"
pbxproj_backup="$(mktemp)"
success=0
skip_upload="${VIBEMAP_SKIP_UPLOAD:-0}"
requested_build_number="${VIBEMAP_BUILD_NUMBER:-}"

cp project.yml "$project_yml_backup"
cp VibeMap.xcodeproj/project.pbxproj "$pbxproj_backup"

ensure_beta_access_token() {
  if [[ -n "${VIBE_BETA_ACCESS_TOKEN:-}" ]]; then
    return
  fi

  VIBE_BETA_ACCESS_TOKEN="$(node -e 'process.stdout.write(require("crypto").randomBytes(32).toString("base64url"))')"
  {
    printf '\n'
    printf 'VIBE_BETA_ACCESS_TOKEN=%s\n' "$VIBE_BETA_ACCESS_TOKEN"
  } >> fastlane/.env.testflight
}

restore_build_number() {
  if [[ "$success" != "1" ]]; then
    cp "$project_yml_backup" project.yml
    cp "$pbxproj_backup" VibeMap.xcodeproj/project.pbxproj
  fi
  rm -f "$project_yml_backup" "$pbxproj_backup"
}
trap restore_build_number EXIT

mkdir -p "$archive_dir" "$export_path" "$derived_data_path"
ensure_beta_access_token

auth_args=()
if [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" && -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]]; then
  if [[ "$APP_STORE_CONNECT_API_KEY_PATH" != /* ]]; then
    APP_STORE_CONNECT_API_KEY_PATH="$PWD/$APP_STORE_CONNECT_API_KEY_PATH"
  fi
  if [[ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
    echo "Missing App Store Connect API key file: $APP_STORE_CONNECT_API_KEY_PATH" >&2
    exit 1
  fi
  auth_args=(
    -authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
    -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_API_ISSUER_ID"
  )
elif [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}${APP_STORE_CONNECT_API_KEY_ID:-}${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]]; then
  echo "Set all App Store Connect auth vars: APP_STORE_CONNECT_API_KEY_PATH, APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_API_ISSUER_ID." >&2
  exit 1
fi

if [[ "${VIBEMAP_REQUIRE_NETWORK_CHECK:-0}" == "1" ]]; then
  /usr/bin/curl -IsS --connect-timeout 10 --max-time 15 https://api.appstoreconnect.apple.com/v1/apps >/dev/null
fi

if [[ -n "$requested_build_number" ]]; then
  build_number="$(node scripts/bump-build-number.mjs "$requested_build_number")"
else
  build_number="$(node scripts/bump-build-number.mjs)"
fi

echo "Archiving VibeMap build $build_number"

archive_command=(
  xcodebuild archive
  -project "$project"
  -scheme "$scheme"
  -configuration "$configuration"
  -destination "generic/platform=iOS"
  -archivePath "$archive_path"
  -derivedDataPath "$derived_data_path"
  -allowProvisioningUpdates
  DEVELOPMENT_TEAM="$team_id"
  CODE_SIGN_STYLE=Automatic
  VIBE_BETA_ACCESS_TOKEN="$VIBE_BETA_ACCESS_TOKEN"
)

if [[ "${#auth_args[@]}" -gt 0 ]]; then
  archive_command+=("${auth_args[@]}")
fi

if ! "${archive_command[@]}"; then
  if [[ "${#auth_args[@]}" -eq 0 ]]; then
    echo ""
    echo "Archive failed before upload. This shell could not use an Xcode account."
    echo "For fully automated Codex uploads, fill fastlane/.env.testflight with an App Store Connect API key."
  fi
  exit 1
fi

if [[ "$skip_upload" == "1" ]]; then
  echo "Archive preflight succeeded for VibeMap build $build_number. Upload skipped; local build number will be restored."
  exit 0
fi

echo "Uploading VibeMap build $build_number to App Store Connect"

export_command=(
  xcodebuild -exportArchive
  -archivePath "$archive_path"
  -exportPath "$export_path"
  -exportOptionsPlist "$local_export_options"
  -allowProvisioningUpdates
)

if [[ "${#auth_args[@]}" -gt 0 ]]; then
  export_command+=("${auth_args[@]}")
fi

if ! "${export_command[@]}"; then
  if [[ "${#auth_args[@]}" -eq 0 ]]; then
    echo ""
    echo "IPA export failed. This shell could not use an Xcode account."
    echo "For fully automated Codex uploads, fill fastlane/.env.testflight with an App Store Connect API key."
  fi
  exit 1
fi

ipa_path="$(find "$export_path" -maxdepth 1 -type f -name '*.ipa' -print | head -n 1)"
if [[ -z "$ipa_path" || ! -f "$ipa_path" ]]; then
  echo "IPA export did not produce an .ipa in $export_path" >&2
  exit 1
fi

if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" || -z "${APP_STORE_CONNECT_API_KEY_ID:-}" || -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]]; then
  echo "Set App Store Connect API key env vars before uploading with altool." >&2
  exit 1
fi

echo "Exported IPA: $ipa_path"

upload_command=(
  xcrun altool --upload-app
  -f "$ipa_path"
  --type ios
  --api-key "$APP_STORE_CONNECT_API_KEY_ID"
  --api-issuer "$APP_STORE_CONNECT_API_ISSUER_ID"
  --p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"
  --show-progress
)

if ! "${upload_command[@]}"; then
  echo "altool upload failed for VibeMap build $build_number." >&2
  exit 1
fi

success=1
mkdir -p "$PWD/build"
printf "%s\n" "$build_number" > "$PWD/build/last-testflight-build.txt"
echo "Uploaded VibeMap build $build_number to App Store Connect."
