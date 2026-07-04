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
- `place_external_ids`: provider-specific IDs for a canonical place, so future enrichment can map MapKit/Google/OSM-style IDs without duplicating human labels.
- `vibe_tags`: the controlled vocabulary users can choose from.
- `taxonomy_versions`: version labels for the active structured vibe taxonomy.
- `anonymous_users`: one anonymous row per hashed device identifier.
- `profiles`: optional email-backed accounts after the user has contributed enough places.
- `profile_devices`: links an optional profile to the anonymous device identity that created past vibes.
- `email_confirmation_tokens`: short-lived confirmation and login tokens.
- `profile_sessions`: private app sessions created after email confirmation.
- `vibe_events`: the private raw contribution event for one anonymous user at one place.
- `place_vibe_stats`: derived public aggregate stats for fast map and place-card reads.
- `place_vibe_tag_stats`: full per-place tag distributions for all-time, 30-day, and 365-day windows, derived from raw events for future API/licensing use.
- `reports`: lightweight moderation and data-quality reports.
- `analytics_devices`, `analytics_device_days`, and `analytics_events`: first-party anonymous product analytics for the private admin dashboard.
- `admin_device_labels`: private admin-only labels for known internal/test devices, used to exclude Brian/Rich seed activity from public-growth dashboard trends.

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
Each new event records the taxonomy version, submission context, and a compact place snapshot so later audits can tell which label set and place metadata were present when the user made the selection.

`place_vibe_stats` is intentionally derived from raw events.
It can be rebuilt at any time from active, non-deleted `vibe_events`.
This avoids corrupting the long-term dataset when the app changes how it summarizes places.
`place_vibe_tag_stats` is also derived and can be rebuilt; it exists so future APIs can return the complete tag distribution without scanning raw private event rows.

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

Product analytics uses a separate server-side salted identifier derived from the app's hashed device id.
This keeps the admin dashboard useful for early growth metrics without exposing raw device hashes or using ad identifiers.
Search analytics stores query length and result counts, not raw search text.

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
3. The Worker creates or updates a profile, links the current anonymous device, creates a short-lived confirmation token, and sends a confirmation email through `hello@vibesyall.com`.
4. The user opens `/account/confirm?token=...`.
5. The Worker verifies the token, marks the email as confirmed, creates a private profile session, and redirects the user back to the app with a deep link.
6. If iOS opens the confirmation in a browser instead of returning through the deep link, the app can refresh account status from the same hashed device and receive a fresh session for that already-confirmed profile.

Recovery and forgot-password behavior use passwordless email links.
`POST /account/recovery` and `POST /account/login` send a fresh sign-in link when an account exists, while returning a generic success response for unknown emails so profile emails are not exposed.

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
- `POST /account/signup`: creates or updates an email profile and sends a confirmation email.
- `POST /account/recovery`: sends a passwordless recovery/sign-in link for an existing account.
- `POST /account/login`: alias for passwordless recovery/sign-in link delivery.
- `GET /account/confirm?token=`: confirms an email account and opens the app with a private session token.
- `POST /analytics/events`: accepts first-party anonymous app events.
- `GET /admin`: private hosted admin analytics dashboard.
- `GET /admin/analytics.json`: private JSON backing the admin dashboard.
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

`wrangler.jsonc` keeps the Worker on branded VIBES Y'ALL URLs. The legacy `rainvis-hak.workers.dev` suffix was only the Cloudflare account's existing Workers subdomain, not a RainVis app dependency, database, route, or repo.
Do not change RainVis Cloudflare resources while deploying VIBES Y'ALL.
Do not rename the account-wide `workers.dev` subdomain to solve branding; use VIBES Y'ALL custom domains instead.

The same Worker serves the API, landing page, support page, privacy policy, and terms. Branded domains are:

- `https://vibesyall.com` for the App Store landing page, support, privacy, and terms
- `https://www.vibesyall.com` for the same marketing pages
- `https://api.vibesyall.com` for iOS API traffic

If the domain needs to be reattached, the safe sequence is:

1. Add `vibesyall.com` as a Cloudflare zone in the VIBES Y'ALL Cloudflare account.
2. Copy the Cloudflare nameservers.
3. In GoDaddy, replace the current `domaincontrol.com` nameservers with Cloudflare's nameservers.
4. In Cloudflare, attach Worker custom domains or routes for `vibesyall.com`, `www.vibesyall.com`, and `api.vibesyall.com`.
5. Set `APP_BASE_URL` to `https://vibesyall.com`.
6. Run `npm run domains:check` from `backend/` to verify DNS and HTTP routing.
7. Run `npm run ios:set-backend-url -- https://api.vibesyall.com`, then push a new TestFlight build.

Account confirmation, recovery, and passwordless sign-in delivery use the Cloudflare Email Sending binding named `SIGNUP_EMAIL`.
The verified sender is `hello@vibesyall.com`, with replies directed to `vibesyall@gmail.com`.
V1 does not store passwords; forgot-password behavior is a fresh email sign-in link from `POST /account/recovery` or `POST /account/login`.
Production has `ACCOUNT_AUTO_CONFIRM_IF_EMAIL_UNAVAILABLE=false`, so account creation fails cleanly if email cannot be delivered.

`APP_STORE_URL` points to the live App Store listing:
`https://apps.apple.com/us/app/vibes-yall/id6783989332?mt=8`

## Private Admin Analytics

The admin dashboard is served by the same Worker and is designed for a Cloudflare Access-protected hostname such as:

```text
https://admin.vibesyall.com
```

Create a Cloudflare Zero Trust Access application for the admin hostname and allow only Brian's Cloudflare login/email.
Then configure these Worker values:

- `ADMIN_EMAILS`: comma-separated allowed admin emails, currently `brianhakel@gmail.com,hakelbrian@gmail.com`.
- `CF_ACCESS_TEAM_DOMAIN`: the Cloudflare Access team domain, including `https://`, for example `https://your-team.cloudflareaccess.com`.
- `CF_ACCESS_AUD`: the Access application Audience (AUD) tag from the admin Access app.
- `ANALYTICS_SECRET`: Worker secret used to derive analytics-only device ids from the app's hashed device id.

The admin routes fail closed if the Access JWT configuration or allowed emails are missing.
Do not put `ANALYTICS_SECRET` in this repo; set it as a Worker secret.

The dashboard currently tracks:

- active devices today, 7 days, and 30 days
- new anonymous devices
- app opens
- searches without raw search text
- place selections
- submitted vibes from saved `vibe_events` history, so pre-analytics seed submissions stay visible in top-line content metrics
- account-flow events
- D1 and D7 retention
- app version mix
- admin-only device labels, with the default view excluding devices marked `excluded_from_core_metrics`
