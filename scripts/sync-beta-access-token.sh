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

cd backend
printf "%s" "$VIBE_BETA_ACCESS_TOKEN" | npx wrangler secret put VIBE_BETA_ACCESS_TOKEN
echo "Synced VIBE_BETA_ACCESS_TOKEN to the vibe-map-api Worker."
