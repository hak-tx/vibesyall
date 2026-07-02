# VIBES Y'ALL Backend

This Worker backs VIBES Y'ALL as a structured, human-labeled place sentiment dataset.
The product does not collect comments, star ratings, photos, emails, phone numbers, or public profiles in V1.
Users pick one to three predefined vibe tags for a real-world place, and the backend stores that contribution as structured data.

New visitors still use the app without signing up.
Anonymous usage is tied to a hashed device identifier so one device can edit its own vibe for a place without creating duplicate votes.
After 10 vibed places, the app can offer an optional email account to preserve that history across devices.

## Data Model

The core tables are:

- `places`: normalized real-world points of interest from providers such as MapKit.
- `vibe_tags`: the controlled vocabulary users can choose from.
- `anonymous_users`: one anonymous row per hashed device identifier.
- `profiles`: optional email-backed accounts after the user has contributed enough places.
- `profile_devices`: links an optional profile to the anonymous device identity that created past vibes.
- `email_confirmation_tokens`: short-lived confirmation and login tokens.
- `profile_sessions`: private app sessions created after email confirmation.
- `vibe_events`: the private raw contribution event for one anonymous user at one place.
- `place_vibe_stats`: derived public aggregate stats for fast map and place-card reads.
- `reports`: lightweight moderation and data-quality reports.

`places` are upserted by `provider + provider_place_id` when a provider id is available.
When a provider id is missing, the API falls back to a conservative nearby-name match before creating a new place id.

## Vibe Tags

Active V1 tags are seeded in `vibe_tags`:

| Slug | Display | Group |
| --- | --- | --- |
| `changed_my_life` | Changed my Life | positive |
| `fire` | Fire | positive |
| `worth_the_drive` | Worth the Drive | positive |
| `iconic` | Iconic | identity |
| `hidden_gem` | Hidden Gem | positive |
| `underrated` | Underrated | positive |
| `mid` | Mid | neutral |
| `chaos` | Chaos | neutral |
| `overrated` | Overrated | negative |
| `tourist_trap` | Tourist Trap | negative |
| `needs_prayer` | Needs Prayer | negative |
| `emotionally_damaging` | Emotionally Damaging | negative |

The Worker accepts tag ids, slugs, display names, and known legacy labels from earlier prototypes.
Legacy labels are normalized into the canonical tag ids before storage.
Examples: `Inspiring` maps to `changed_my_life`; `Elite`, `Great`, `Unreasonably good`, and `Surprisingly solid` map to `fire`; `Certified` and `America` map to `iconic`; `Cringe`, `UnAmerican`, and `Never again` map to `emotionally_damaging`.

## Why Raw Events Are Separate From Aggregate Stats

Every submitted vibe is stored in `vibe_events` as the private source of truth.
That keeps the dataset useful beyond the app UI: licensing, commercial API access, trend reports, city analytics, data-quality audits, and future AI training datasets all need the original structured human labels, not only a rolled-up count.

`place_vibe_stats` is intentionally derived from raw events.
It can be rebuilt at any time from active, non-deleted `vibe_events`.
This avoids corrupting the long-term dataset when the app changes how it summarizes places.

If a user changes their vibe for the same place, the backend updates that user's existing `vibe_events` row because V1 enforces one current contribution per anonymous user per place.
The row keeps `created_at` and updates `updated_at`, so the current user-place opinion is stable without allowing unlimited duplicate votes.

## Public Aggregate Data vs Private Raw Data

Public API responses expose place details and aggregate stats only:

- total vibe submissions
- top vibe and percent
- second vibe and percent
- last 30 day top vibe and count
- last year top vibe and count
- compact top-vibe breakdowns for the app UI

Raw `vibe_events` stay private.
They include anonymous user ids, source, app version, moderation status, and tag choices, but no names, emails, phone numbers, photos, written reviews, or raw device ids.

Device identifiers must be hashed before storage.
The API accepts a pre-hashed `device_id_hash`; if a raw device token is accidentally sent as `device_id`, the Worker hashes it before writing `anonymous_users`.

Optional profiles store email addresses only for account confirmation and account recovery.
Email addresses are never exposed in public place or aggregate responses.
Profile-device linking exists so a user can claim the anonymous vibe history already created on that device.

## Optional Accounts

The first-run product flow stays anonymous and signup-free.
The app should only offer account creation after the current device has vibed at least 10 distinct places.

The account pitch is intentionally practical:

- keep past and future vibes tied to one account
- switch devices without losing place history
- edit past vibes when an opinion changes
- make spam and bot abuse harder than anonymous-only voting

Account creation uses email confirmation:

1. The app calls `GET /account/eligibility` with `X-Vibe-Device-ID-Hash`.
2. If eligible, the app calls `POST /account/signup` with `email` and `device_id_hash`.
3. The Worker creates or updates a profile, links the current anonymous device, creates a short-lived confirmation token, and sends a confirmation email when the Cloudflare email binding is configured.
4. The user opens `/account/confirm?token=...`.
5. The Worker verifies the token, marks the email as confirmed, creates a private profile session, and redirects the user back to the app with a deep link.

Raw device ids are not stored.
The profile layer does not change `vibe_events`; one current vibe event per place per anonymous device remains the anti-duplicate rule.

## API

- `GET /health`: service health and data-model marker.
- `POST /places`: create or upsert a place.
- `GET /places/:id`: read place details and aggregate stats.
- `GET /places/nearby?lat=&lng=&radius=`: read nearby places with aggregate stats.
- `POST /vibes`: submit or update one anonymous user's vibe for a place.
- `GET /vibes/tags`: read active tags in sort order.
- `POST /reports`: report wrong places, duplicates, spam, inappropriate data, or other issues.
- `GET /account/eligibility`: returns whether the current hashed device has reached the optional signup threshold.
- `POST /account/signup`: creates or updates an email profile and sends a confirmation email when email sending is configured.
- `GET /account/confirm?token=`: confirms an email account and opens the app with a private session token.
- `GET /privacy`: App Store privacy-policy page.
- `GET /terms`: App Store terms page.
- `GET /`: public one-page App Store landing page for `vibesyall.com`.

Legacy compatibility routes still exist for current iOS builds:

- `GET /vibes`: returns the older display-name list used by the current client.
- `POST /ratings`: aliases to `POST /vibes`.
- `POST /places/:id/report`: aliases to `POST /reports`.

## Stats Rules

Core stats use raw counts only:

- all-time stats count active, non-deleted `vibe_events`
- last 30 day stats count active, non-deleted `vibe_events.created_at` within 30 days
- last year stats count active, non-deleted `vibe_events.created_at` within 365 days

No hidden weighting or time decay is applied to `place_vibe_stats`.
Trending can be added later as a separate clearly labeled algorithmic view.

## Cloudflare Notes

`wrangler.jsonc` currently enables the temporary Worker URL at `https://vibe-map-api.rainvis-hak.workers.dev`.
The `rainvis-hak.workers.dev` suffix is the Cloudflare account's existing Workers subdomain, not a RainVis app dependency, database, route, or repo.
Do not change RainVis Cloudflare resources while deploying VIBES Y'ALL.
Do not rename the account-wide `workers.dev` subdomain to solve branding; use VIBES Y'ALL custom domains instead.

The same Worker serves the API, landing page, support page, privacy policy, and terms. Target branded domains are:

- `https://vibesyall.com` for the App Store landing page, support, privacy, and terms
- `https://www.vibesyall.com` for the same marketing pages
- `https://api.vibesyall.com` for iOS API traffic

`vibesyall.com` should be attached after the domain exists as a Cloudflare zone in this account. The current DNS is still at GoDaddy, so the safe sequence is:

1. Add `vibesyall.com` as a Cloudflare zone in the VIBES Y'ALL Cloudflare account.
2. Copy the Cloudflare nameservers.
3. In GoDaddy, replace the current `domaincontrol.com` nameservers with Cloudflare's nameservers.
4. In Cloudflare, attach Worker custom domains or routes for `vibesyall.com`, `www.vibesyall.com`, and `api.vibesyall.com`.
5. Set `APP_BASE_URL` to `https://api.vibesyall.com`.
6. Run `npm run domains:check` from `backend/` to verify DNS and HTTP routing.
7. Run `npm run ios:set-backend-url -- https://api.vibesyall.com`, then push a new TestFlight build.

Email delivery is intentionally optional in code so the Worker can still deploy before Cloudflare Email Routing is fully verified for the domain.
To enable real confirmation email delivery, add a Cloudflare email-send binding named `SIGNUP_EMAIL` and keep `ACCOUNT_EMAIL_FROM` set to the verified sender `vibesyall@gmail.com`.

`APP_STORE_URL` is currently a deploy-time variable.
Point it at the real App Store URL when the public listing is ready.
