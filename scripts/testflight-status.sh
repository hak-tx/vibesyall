#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
status_file="$repo_root/build/testflight-status.json"

if [[ ! -f "$status_file" ]]; then
  echo "No TestFlight runner status has been written yet."
  exit 0
fi

node - "$status_file" <<'NODE'
const fs = require("fs");
const status = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
console.log(`State: ${status.state}`);
if (status.message) console.log(`Message: ${status.message}`);
if (status.buildNumber) console.log(`Build: ${status.buildNumber}`);
if (status.requestId) console.log(`Request: ${status.requestId}`);
if (status.logPath) console.log(`Log: ${status.logPath}`);
if (status.updatedAt) console.log(`Updated: ${status.updatedAt}`);
NODE
