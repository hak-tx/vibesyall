# TestFlight

The repeatable upload command is:

```bash
./scripts/push-testflight.sh
```

This uses Xcode's native archive and App Store Connect upload flow with the App Store Connect API key in `fastlane/.env.testflight`.
Build `4` is already in TestFlight, so the next successful run uploads build `5`.

Remote Codex trigger:

```bash
./scripts/codex-testflight.sh
```

Use this when Brian asks from iOS Codex to push TestFlight. He should not need to run Terminal manually; the Codex agent should run this script from the VibeMap workspace, watch it complete, and report the uploaded build number.

This command queues the upload for the Mac mini LaunchAgent runner, which runs as Brian's normal macOS user outside Codex's shell sandbox. The runner can use the Mac mini's normal Xcode signing, keychain, network, and App Store Connect access.

Install or refresh the runner:

```bash
./scripts/install-testflight-runner.sh
```

Runner files:

- LaunchAgent: `~/Library/LaunchAgents/com.brianhakel.vibemap.testflight-runner.plist`
- Queue: `build/testflight-runner-state/queue`
- Status: `build/testflight-status.json`
- Request log: `build/codex-testflight-request.log`
- Per-upload log: `build/testflight-<request-id>.log`

Check runner status:

```bash
./scripts/testflight-status.sh
```

Queue a request without waiting:

```bash
./scripts/request-testflight.sh
```

Queue a request and wait:

```bash
./scripts/request-testflight.sh --wait
```

Fastlane calls the same script:

```bash
fastlane ios beta
```

Optional API-key setup:

The VibeMap key is stored locally as an ignored file under `fastlane/AuthKey_*.p8`.
If a new key is ever created, save the `.p8` file as `fastlane/AuthKey_<key id>.p8`, update `fastlane/.env.testflight`, and run:

```bash
fastlane --env testflight ios doctor
fastlane --env testflight ios beta
```

Each upload bumps `CURRENT_PROJECT_VERSION` in both `project.yml` and `VibeMap.xcodeproj/project.pbxproj`, archives a Release build with automatic signing, uploads the archive to App Store Connect, and keeps the bumped build number only if the upload succeeds.

No-upload archive preflight:

```bash
VIBEMAP_SKIP_UPLOAD=1 ./scripts/push-testflight.sh
```
