#!/usr/bin/env bash
set -euo pipefail

cd "/Users/brianhakel2/Projects/vibe-map"
mkdir -p build
log_path="$PWD/build/testflight-terminal.log"
{
  echo "Starting VibeMap TestFlight upload at $(date)"
  VIBEMAP_SKIP_NETWORK_CHECK=1 ./scripts/testflight.sh
  echo "Finished VibeMap TestFlight upload at $(date)"
} 2>&1 | tee "$log_path"

echo
echo "Log written to $log_path"
read -r -p "Press Return to close this window..."
