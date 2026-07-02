#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
label="com.brianhakel.vibemap.testflight-runner"
plist_path="$HOME/Library/LaunchAgents/$label.plist"
state_root="$repo_root/build/testflight-runner-state"
log_root="$HOME/Library/Logs/VibeMapTestFlight"
uid="$(id -u)"

mkdir -p "$HOME/Library/LaunchAgents" "$state_root/queue" "$state_root/processing" "$state_root/done" "$state_root/failed" "$state_root/logs" "$log_root" "$repo_root/build"
chmod +x "$repo_root/scripts/testflight-runner.sh" "$repo_root/scripts/request-testflight.sh" "$repo_root/scripts/testflight-status.sh" "$repo_root/scripts/codex-testflight.sh" "$repo_root/scripts/push-testflight.sh" "$repo_root/scripts/testflight.sh"

cat > "$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$repo_root/scripts/testflight-runner.sh</string>
    <string>daemon</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$repo_root</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$log_root/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$log_root/launchd.err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>LANG</key>
    <string>en_US.UTF-8</string>
    <key>LC_ALL</key>
    <string>en_US.UTF-8</string>
    <key>VIBEMAP_TESTFLIGHT_RUNNER_ROOT</key>
    <string>$state_root</string>
  </dict>
</dict>
</plist>
PLIST

plutil -lint "$plist_path" >/dev/null

if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
  launchctl bootout "gui/$uid/$label" >/dev/null 2>&1 || true
fi

launchctl bootstrap "gui/$uid" "$plist_path"
launchctl kickstart -k "gui/$uid/$label"

echo "Installed and started $label"
echo "Plist: $plist_path"
echo "Status: $repo_root/build/testflight-status.json"
echo "Queue: $state_root/queue"
