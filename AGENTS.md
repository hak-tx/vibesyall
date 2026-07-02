# VibeMap Codex Instructions

## Remote TestFlight Push

When Brian asks from Codex, including iOS Codex, to push VibeMap to TestFlight, do not ask him to run Terminal commands.

Run this from the repo root:

```bash
./scripts/codex-testflight.sh
```

Behavior:

- The script reads App Store Connect credentials from `fastlane/.env.testflight`.
- The private `.p8` key lives at `fastlane/AuthKey_H86Z6M875N.p8` and is intentionally ignored by git.
- Build `4` is already in TestFlight, so the next successful push should upload build `5`.
- The script bumps `CURRENT_PROJECT_VERSION`, archives Release with automatic signing, uploads to App Store Connect, and keeps the bumped build only after successful upload.
- If upload fails, the script restores the previous build number.
- Runner state and queue files are written under `build/testflight-runner-state/` so remote Codex sessions can enqueue uploads without needing `~/Library/Application Support` write access.
- Release output is written to `build/codex-testflight.log`.

Before claiming success, verify the command actually completed and quote the uploaded build number from the script output.

If the command fails, report the exact blocking error and do not claim TestFlight was updated.
