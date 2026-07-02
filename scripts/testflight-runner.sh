#!/usr/bin/env bash
set -u

repo_root="/Users/brianhakel2/Projects/vibe-map"
state_root="${VIBEMAP_TESTFLIGHT_RUNNER_ROOT:-$repo_root/build/testflight-runner-state}"
queue_dir="$state_root/queue"
processing_dir="$state_root/processing"
done_dir="$state_root/done"
failed_dir="$state_root/failed"
log_dir="$state_root/logs"
lock_dir="$state_root/runner.lock"
status_file="$repo_root/build/testflight-status.json"
launcher_log="$repo_root/build/testflight-runner.log"

export HOME="${HOME:-/Users/brianhakel2}"
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

mkdir -p "$queue_dir" "$processing_dir" "$done_dir" "$failed_dir" "$log_dir" "$repo_root/build"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

write_status() {
  local state="$1"
  local request_id="${2:-}"
  local message="${3:-}"
  local build_number="${4:-}"
  local log_path="${5:-}"
  STATUS_STATE="$state" \
  STATUS_REQUEST_ID="$request_id" \
  STATUS_MESSAGE="$message" \
  STATUS_BUILD_NUMBER="$build_number" \
  STATUS_LOG_PATH="$log_path" \
  STATUS_UPDATED_AT="$(now_utc)" \
  STATUS_QUEUE_DIR="$queue_dir" \
  node <<'NODE' > "$status_file.tmp"
const fs = require("fs");
const status = {
  state: process.env.STATUS_STATE,
  requestId: process.env.STATUS_REQUEST_ID || null,
  message: process.env.STATUS_MESSAGE || "",
  buildNumber: process.env.STATUS_BUILD_NUMBER || null,
  logPath: process.env.STATUS_LOG_PATH || null,
  updatedAt: process.env.STATUS_UPDATED_AT,
  queueDir: process.env.STATUS_QUEUE_DIR,
};
process.stdout.write(`${JSON.stringify(status, null, 2)}\n`);
NODE
  mv "$status_file.tmp" "$status_file"
}

log_runner() {
  printf '[%s] %s\n' "$(now_utc)" "$*" >> "$launcher_log"
}

next_job() {
  find "$queue_dir" -maxdepth 1 -type f -name '*.request' -print | sort | head -n 1
}

run_health_job() {
  local request_id="$1"
  local log_path="$2"
  {
    echo "VibeMap TestFlight runner health check"
    echo "Started: $(date)"
    echo "Repo: $repo_root"
    echo "User: $(id -un)"
    echo "Network check:"
    /usr/bin/curl -IsS --connect-timeout 10 --max-time 20 https://api.appstoreconnect.apple.com/v1/apps | sed -n '1,5p'
    echo "Finished: $(date)"
  } > "$log_path" 2>&1
  local exit_code=$?
  if [[ "$exit_code" -eq 0 ]]; then
    write_status "succeeded" "$request_id" "Runner health check succeeded." "" "$log_path"
  else
    write_status "failed" "$request_id" "Runner health check failed." "" "$log_path"
  fi
  return "$exit_code"
}

run_testflight_job() {
  local request_id="$1"
  local requested_build_number="$2"
  local log_path="$3"
  local repo_job_log="$repo_root/build/testflight-$request_id.log"

  cd "$repo_root" || return 1
  write_status "running" "$request_id" "Uploading VibeMap to TestFlight." "" "$repo_job_log"

  set +e
  {
    echo "Starting VibeMap TestFlight upload"
    echo "Started: $(date)"
    echo "Repo: $repo_root"
    echo "Request: $request_id"
    if [[ -n "$requested_build_number" ]]; then
      echo "Requested build: $requested_build_number"
      export VIBEMAP_BUILD_NUMBER="$requested_build_number"
    else
      unset VIBEMAP_BUILD_NUMBER
    fi
    ./scripts/push-testflight.sh
    upload_exit="$?"
    echo "Finished: $(date)"
    echo "__SCRIPT_EXIT__:$upload_exit"
    exit "$upload_exit"
  } 2>&1 | tee "$log_path" "$repo_job_log"
  local exit_code="${PIPESTATUS[0]}"
  local build_number=""
  if [[ -f "$repo_root/build/last-testflight-build.txt" ]]; then
    build_number="$(tr -d '[:space:]' < "$repo_root/build/last-testflight-build.txt")"
  fi

  if [[ "$exit_code" -eq 0 ]]; then
    write_status "succeeded" "$request_id" "Uploaded VibeMap build $build_number to TestFlight." "$build_number" "$repo_job_log"
  else
    write_status "failed" "$request_id" "TestFlight upload failed. See log." "" "$repo_job_log"
  fi
  return "$exit_code"
}

process_one_job() {
  local job_path
  job_path="$(next_job)"
  [[ -n "$job_path" ]] || return 2

  if ! mkdir "$lock_dir" 2>/dev/null; then
    return 3
  fi
  trap 'rm -rf "$lock_dir"' RETURN

  local job_name request_id action requested_build_number started_at processing_path log_path exit_code
  job_name="$(basename "$job_path")"
  processing_path="$processing_dir/$job_name"
  if ! mv "$job_path" "$processing_path" 2>/dev/null; then
    return 4
  fi

  request_id=""
  action=""
  requested_build_number=""
  source "$processing_path"
  request_id="${REQUEST_ID:-${job_name%.request}}"
  action="${ACTION:-testflight}"
  requested_build_number="${REQUESTED_BUILD_NUMBER:-}"
  started_at="$(date -u +"%Y%m%dT%H%M%SZ")"
  log_path="$log_dir/$started_at-$request_id.log"

  log_runner "processing $request_id ($action)"

  case "$action" in
    testflight)
      run_testflight_job "$request_id" "$requested_build_number" "$log_path"
      exit_code=$?
      ;;
    health)
      write_status "running" "$request_id" "Running TestFlight runner health check." "" "$log_path"
      run_health_job "$request_id" "$log_path"
      exit_code=$?
      ;;
    *)
      echo "Unknown action: $action" > "$log_path"
      write_status "failed" "$request_id" "Unknown runner action: $action." "" "$log_path"
      exit_code=1
      ;;
  esac

  if [[ "$exit_code" -eq 0 ]]; then
    mv "$processing_path" "$done_dir/${job_name%.request}.$(date -u +%Y%m%dT%H%M%SZ).request"
  else
    mv "$processing_path" "$failed_dir/${job_name%.request}.$(date -u +%Y%m%dT%H%M%SZ).request"
  fi
  log_runner "finished $request_id with exit $exit_code"
  return "$exit_code"
}

case "${1:-daemon}" in
  daemon)
    write_status "idle" "" "Runner is watching for TestFlight requests." "" ""
    while true; do
      process_one_job
      result=$?
      if [[ "$result" -eq 2 || "$result" -eq 3 ]]; then
        sleep "${VIBEMAP_TESTFLIGHT_RUNNER_INTERVAL:-5}"
      fi
    done
    ;;
  once)
    process_one_job
    ;;
  *)
    echo "Usage: $0 [daemon|once]" >&2
    exit 64
    ;;
esac
