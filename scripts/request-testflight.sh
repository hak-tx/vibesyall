#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
state_root="${VIBEMAP_TESTFLIGHT_RUNNER_ROOT:-$repo_root/build/testflight-runner-state}"
queue_dir="$state_root/queue"
lock_dir="$state_root/runner.lock"
status_file="$repo_root/build/testflight-status.json"
action="testflight"
requested_build_number=""
wait_mode="0"
force="0"

usage() {
  cat <<USAGE
Usage: $0 [--wait] [--force] [--build-number N] [--health]

Queues a VibeMap TestFlight upload for the Mac mini LaunchAgent runner.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wait)
      wait_mode="1"
      shift
      ;;
    --force)
      force="1"
      shift
      ;;
    --build-number)
      requested_build_number="${2:-}"
      if [[ -z "$requested_build_number" ]]; then
        echo "--build-number requires a value" >&2
        exit 64
      fi
      shift 2
      ;;
    --health)
      action="health"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

mkdir -p "$queue_dir" "$repo_root/build"

pending_count="$(find "$queue_dir" -maxdepth 1 -type f -name '*.request' -print | wc -l | tr -d '[:space:]')"
if [[ "$force" != "1" && ( "$pending_count" != "0" || -d "$lock_dir" ) ]]; then
  echo "A TestFlight runner job is already pending or running." >&2
  echo "Use --force only if you intentionally want another queued upload." >&2
  exit 75
fi

request_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
tmp_path="$queue_dir/$request_id.tmp"
request_path="$queue_dir/$request_id.request"

{
  printf 'ACTION=%q\n' "$action"
  printf 'REQUEST_ID=%q\n' "$request_id"
  printf 'CREATED_AT=%q\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf 'REQUESTED_BUILD_NUMBER=%q\n' "$requested_build_number"
  printf 'REPO_ROOT=%q\n' "$repo_root"
} > "$tmp_path"
mv "$tmp_path" "$request_path"

echo "Queued VibeMap $action request $request_id"
echo "Queue file: $request_path"

if [[ "$wait_mode" == "1" ]]; then
  deadline=$((SECONDS + ${VIBEMAP_TESTFLIGHT_WAIT_SECONDS:-3600}))
  last_state=""
  while [[ "$SECONDS" -lt "$deadline" ]]; do
    if [[ -f "$status_file" ]]; then
      state="$(node -e 'const fs=require("fs"); const p=process.argv[1]; const s=JSON.parse(fs.readFileSync(p,"utf8")); if (s.requestId===process.argv[2]) console.log(s.state);' "$status_file" "$request_id")"
      if [[ -n "$state" && "$state" != "$last_state" ]]; then
        node -e 'const fs=require("fs"); const s=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); console.log(`${s.state}: ${s.message}`);' "$status_file"
        last_state="$state"
      fi
      case "$state" in
        succeeded)
          exit 0
          ;;
        failed)
          exit 1
          ;;
      esac
    fi
    sleep 5
  done
  echo "Timed out waiting for TestFlight runner request $request_id" >&2
  exit 124
fi
