# VIBES Y'ALL Session Handoff

Last updated: 2026-07-04.

This is the first file future Codex chats should read for this repo. It captures the current working context from the long VIBES Y'ALL iOS, backend, Cloudflare, TestFlight, and App Store session.

## Project Identity

- Local repo: `/Users/brianhakel2/Projects/vibe-map`
- Product name: `VIBES Y'ALL`
- iOS target/project is still named `VibeMap` internally in places.
- Bundle identifier: `com.brianhakel.vibemap`
- App Store listing: `https://apps.apple.com/us/app/vibes-yall/id6783989332`
- Production API: `https://api.vibesyall.com`
- Marketing site: `https://vibesyall.com`
- Support email: `vibesyall@gmail.com`
- Account email sender: `hello@vibesyall.com`

The old `vibe-map-api.rainvis-hak.workers.dev` hostname is only the Cloudflare account Workers subdomain. It is not a RainVis project dependency. Do not touch RainVis Cloudflare, app, database, routes, or repo when working on VIBES Y'ALL.

## Product Rules

- Map-first iOS app.
- Users can use the app without signup.
- Anonymous identity is tied to a local device id hash, not a raw device id.
- One current vibe event per anonymous device per place. A repeat submission updates the existing event.
- Optional account creation is offered after 10 vibed places so users can preserve/edit history across devices.
- No comments, no star ratings, no public profiles, no followers, no messaging, no coins, no streaks, no leaderboards.
- A place can receive one to three vibe tags.
- Raw vibe events are the private source of truth; aggregate place stats are derived.
- Public API responses should expose aggregate stats, not raw event rows.

## Current Vibe Tags

Canonical active tags:

- Changed my Life
- Fire
- Worth the Drive
- Iconic
- Hidden Gem
- Underrated
- Mid
- Chaos
- Overrated
- Tourist Trap
- Needs Prayer
- Emotionally Damaging

The backend normalizes legacy labels to current tags. Do not lose old data when tag names change.

## iOS UX Decisions

- Search bar belongs near the top where it originally was, clear of the Dynamic Island. Do not push it down unnecessarily.
- Search bar uses translucent `#102c6b` navy with `#dfd771` hint text and the VIBES Y'ALL logo to the left.
- Default map mode should be standard unless the user has saved a preference.
- My-location dot and location button should read as blue, like normal map apps.
- Filter chips sit below the search bar. Selected chip is navy/brand; unselected chips are translucent neutral with a thin navy border.
- Filter chips also filter search result suggestions when the user is searching.
- Search suggestions should keep the search bar fixed, scroll above the keyboard, allow keyboard dismissal, and never cut off distance labels.
- Previously vibed/reviewed matching places should appear at the top of search results with compact vibe summary.
- What's Nearby card starts on the bottom and is about 40% of the screen when open.
- What's Nearby can be minimized by tapping the map or swiping down on the grabber.
- What's Nearby title is `What's Nearby`; do not use `Nearby needs your opinion`.
- Nearby count should represent the actual place count for the visible/current map area, with a load-more/list behavior if needed.
- When many places are visible, avoid pin flicker and avoid blocking pinch-to-zoom. Do not remove old pins until replacement data is ready.
- Use server-side map-cell clustering at far zoom levels. Increase clustering at state/region/country zoom to reduce overload.
- Clusters should be less visually noisy than raw pin spam. At broad zoom, prefer summary clusters/heat-style aggregation over thousands of individual badges.

## Place Card UX

- The place card is the hero.
- Place name is large, bold, and must never be clipped at the top.
- Keep consistent top padding inside the sheet.
- Address should show on two lines where needed: street number/name on line one, city/state on line two.
- Address is a directions link and should use a small map icon to the left.
- Category should be directly below the address, slightly prominent but not overpowering, and human-readable with spaces such as `Music venue`.
- Place card needs a share button even before the user rates, so people can share already-vibed places.
- Vibe picker should show all buttons without nested scrolling inside the card.
- The submit/update button's whole visible button area must be tappable, not only the text.
- Help text says select one to three vibes and must not be cut off.
- Leave only minimal bottom padding; no large negative space below the submit/help area.

## Post-Submit UX

- Completion card should be sized to its actual content and not leave a huge blank lower half.
- Confirmation should compare `You picked` vs `Everyone else` without repeating the same information multiple times.
- Share card is available after submitting and should be shareable to Instagram, Facebook, X, etc.
- Share card should include place, selected vibes, community vibe summary, and VIBES Y'ALL branding.

## Website / Landing Page

- The Worker serves the landing page, support page, privacy policy, and terms.
- `vibesyall.com`, `www.vibesyall.com`, and `api.vibesyall.com` are the branded targets.
- All site contact email references should use `vibesyall@gmail.com`.
- App Store links should use `https://apps.apple.com/us/app/vibes-yall/id6783989332`.
- Use an official-looking App Store badge for the download CTA.
- Do not keep a separate privacy button next to the App Store button; footer privacy link is enough.
- Hero/title font should use the prior reliable system/app font stack. Do not use `Sailors Condensed` unless a licensed webfont file is added to the repo.
- A recent interrupted turn removed the Sailors-specific CSS override from `backend/src/index.ts`; verify before deploying if needed.

## Cloudflare / Backend

- Backend package lives in `backend/`.
- Deploy production from `backend/` with `npm run deploy:production`.
- The same Worker handles API and marketing pages.
- D1 database is bound as `DB`.
- Email sending binding for account confirmation/recovery is `SIGNUP_EMAIL`.
- Production should fail cleanly if email cannot send; do not auto-confirm production accounts.
- Cache/read optimization matters. Use caching and viewport/map-cell endpoints for map data, but do not serve stale write responses.
- Do not put secrets in docs or committed files.
- Private admin analytics are hosted at `https://vibesyall.com/admin` behind Cloudflare Access.
- Cloudflare Zero Trust org: `vibesyall.cloudflareaccess.com`; Access app: `VIBES Y'ALL Admin Dashboard`; protected destinations: `vibesyall.com/admin` and `vibesyall.com/admin/*`.
- Access policy is `Brian only`, allowing `brianhakel@gmail.com` and the Cloudflare account email `hakelbrian@gmail.com`.
- Access login uses the `Email one-time code` identity provider, `auto_redirect_to_identity: true`, and `same_site_cookie_attribute: lax`; do not change SameSite back to `strict` because the Cloudflare Access callback can loop after email-code login on mobile browsers.
- Worker secrets required for admin/analytics are `ANALYTICS_SECRET`, `CF_ACCESS_AUD`, and `CF_ACCESS_TEAM_DOMAIN`; do not print or commit their values.
- Analytics tables are `analytics_devices`, `analytics_device_days`, and `analytics_events`.
- Admin-only device labels live in `admin_device_labels`; the dashboard defaults to excluding rows marked `excluded_from_core_metrics` so Brian/Rich seed activity can be filtered out before public launch.
- Analytics is first-party and anonymous. It stores app opens, search result counts without raw search text, place selections, account-flow events, and server-side vibe submissions.
- The admin dashboard reads saved-vibe top-line metrics and the 30-day vibe-history chart directly from `vibe_events`, so seed submissions made before analytics tracking still appear in submitted-vibe and per-device summaries. Search/app-open metrics remain analytics-only because those were not collected historically.
- As of 2026-07-04, a Codex smoke event was accepted by `POST /analytics/events` and landed in remote D1.

## TestFlight / App Store

- For TestFlight, do not ask Brian to run Terminal. From repo root run:

```bash
./scripts/codex-testflight.sh
```

- Quote the uploaded build number from script output before claiming success.
- Latest TestFlight upload in this session: build `29`, uploaded 2026-07-04 after admin analytics and What's Nearby expansion changes.
- If the script fails, report the exact blocking error.
- App Store review asked for Guideline 2.1 information. Brian handles screenshots/screen recordings when needed, but code/App Store metadata/support links should be kept ready.
- For review credentials, prefer a real test account in the database only if account-gated flows require it. The app is free and anonymous-first, but account creation exists after 10 vibes.

## Current Worktree Caution

The repo may be dirty from active iOS/backend/site work. Always start with:

```bash
git status --short --branch
```

Do not reset or revert user/previous-agent changes unless Brian explicitly asks.
