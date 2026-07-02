#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build
log_path="$PWD/build/codex-testflight-request.log"

{
  echo "Requesting VibeMap TestFlight push at $(date)"
  request_output="$(mktemp)"
  if ./scripts/request-testflight.sh --wait "$@" > "$request_output" 2>&1; then
    cat "$request_output"
    rm -f "$request_output"
    :
  else
    request_exit="$?"
    cat "$request_output"
    if grep -q "Operation not permitted" "$request_output"; then
      rm -f "$request_output"
      echo "Runner queue is not writable from this shell; refusing direct Xcode upload because this shell may not have signing, Keychain, or network access."
      exit "$request_exit"
    else
      rm -f "$request_output"
      exit "$request_exit"
    fi
  fi
  echo "Finished VibeMap TestFlight request at $(date)"
} 2>&1 | tee "$log_path"
