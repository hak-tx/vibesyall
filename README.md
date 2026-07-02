# Vibe Map

Vibe Map is a silly, low-friction native iOS MVP for tagging real-world places with one to three predefined vibes. No visible score, comments, reviews, profiles, follows, DMs, feeds, or push notifications in V1.

## What is included

- Native SwiftUI iOS app using MapKit
- MapKit search through `MKLocalSearch`
- Map user-location display when permission is granted
- Search-result selection and native MapKit POI selection
- Nearby vibes with direct-to-picker actions and visible pick counts
- One to three predefined vibe tags per place; hidden scores are derived internally for ranking
- Anonymous device UUID persisted locally and SHA-256 hashed before rating submission
- Cloudflare Worker backend with D1 schema
- Local seed SQL and in-app mock service for UI testing

Production API: `https://api.vibesyall.com`.

The legacy `vibe-map-api.rainvis-hak.workers.dev` hostname was only the Cloudflare account Workers subdomain. It is not a RainVis code, data, or routing dependency.

## iOS Setup

Requirements:

- Xcode 26+
- XcodeGen (`brew install xcodegen`)

Generate the project:

```bash
xcodegen generate
open VibeMap.xcodeproj
```

Backend URL is supplied through the `VIBE_MAP_BACKEND_BASE_URL` build setting and read from `Info.plist` at launch:

```swift
Bundle.main.object(forInfoDictionaryKey: "VIBE_MAP_BACKEND_BASE_URL")
```

For UI-only local testing without a Worker, run the `VibeMap Demo` scheme or launch with `--demo`.
Demo mode uses `MockVibeService`, opens on the Austin mock data, and keeps the normal search/rating flow intact.
Edit quick proof-of-concept data in `VibeMap/Demo/DemoScenario.swift`.

Map POI selection is available in the app flow: tap a visible MapKit POI label to open the vibe picker directly. When a dense building or business complex has multiple very close POI matches, Vibe Map shows only the closest choices before rating.

## Cloudflare Setup

Requirements:

- Cloudflare account
- Wrangler CLI through the backend package

Install backend dependencies:

```bash
cd backend
npm install
```

For production, authenticate Wrangler from a normal Terminal:

```bash
npx wrangler login
```

Then deploy the full Worker and D1 lane:

```bash
npm run deploy:production
```

Set the iOS backend URL from the Worker URL printed by the deploy script:

```bash
npm run ios:set-backend-url -- https://vibe-map-api.<account>.workers.dev
```

To point iOS builds at the branded production API, use:

```bash
npm run ios:set-backend-url -- https://api.vibesyall.com
```

For local development, apply the D1 schema locally:

```bash
npm run db:migrate:local
npm run db:seed:local
```

Run the Worker locally:

```bash
npm run dev
```

The iOS app currently points at the production Worker URL through the default build setting.

## TestFlight

The repeatable upload lane is:

```bash
./scripts/push-testflight.sh
```

It bumps from the current local build number, archives the app with App Store distribution signing, and uploads to App Store Connect/TestFlight. Build `4` is already in TestFlight, so the next successful push uploads build `5`.

See [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md) for the one-time API-key setup.

## Privacy Approach

V1 does not collect names, email, phone, comments, reviews, profiles, or social graph data. The app creates an anonymous UUID on-device and stores it locally in `UserDefaults`; before the app sends a rating, it hashes that UUID with SHA-256. The backend stores only `device_id_hash`, never the raw local UUID.

The backend also hashes non-SHA-256-looking device identifiers before storage as a defensive fallback. Duplicate voting is limited by `UNIQUE(place_id, device_id_hash)`, so the same anonymous device can update or replace its rating for a place instead of creating repeated votes.

## API Docs

See [backend/docs/API.md](backend/docs/API.md).

## TODO

- Share card image generation
- Rich/promoter campaign pages
- Web version
- Sponsored vibe challenges
- Push notifications
- User accounts
- Leaderboards
- Abuse/reporting dashboard
- App Store polish
