# Vibe Map Backend Deployment

This backend is a Cloudflare Worker with a D1 database.

Temporary Worker URL:

```text
https://vibe-map-api.rainvis-hak.workers.dev
```

The `rainvis-hak.workers.dev` suffix is only the Cloudflare account's current Workers subdomain. It is not a RainVis app resource. Keep RainVis projects, routes, databases, and app settings untouched.
Do not rename the account-wide Workers subdomain for branding because that could affect unrelated Workers. Move VIBES Y'ALL to custom domains instead.

Target VIBES Y'ALL domains after DNS cutover:

```text
https://vibesyall.com
https://www.vibesyall.com
https://api.vibesyall.com
```

## One-Time Cloudflare Auth

Authenticate Wrangler from a normal terminal. Codex cannot complete this OAuth flow because Wrangler needs to bind a local callback port.

```bash
cd /Users/brianhakel2/Projects/vibe-map/backend
npx wrangler login
```

Or use a Cloudflare API token without storing it in this repo:

```bash
export CLOUDFLARE_API_TOKEN="..."
```

## Deploy

```bash
npm run deploy:production
```

The deploy runner:

- checks Cloudflare auth
- creates the production D1 database if `wrangler.jsonc` still has the placeholder id
- runs TypeScript and Wrangler dry-run checks
- applies `schema.sql` to remote D1
- deploys the Worker
- prints the Worker URL

Set the iOS TestFlight backend URL from the printed Worker URL:

```bash
npm run ios:set-backend-url -- https://vibe-map-api.<your-workers-subdomain>.workers.dev
```

Verify the deployed API:

```bash
curl https://vibe-map-api.<your-workers-subdomain>.workers.dev/health
```

Then archive a fresh TestFlight build. The app reads `VIBE_MAP_BACKEND_BASE_URL` from `Info.plist` at runtime, so future pushes only need this setting changed when the Worker URL changes.

## VIBES Y'ALL DNS Cutover

The domain was bought at GoDaddy, so GoDaddy controls DNS until the nameservers are changed.
Preferred setup:

1. Add `vibesyall.com` to the same Cloudflare account that owns `vibe-map-api`.
2. Copy the Cloudflare-assigned nameservers.
3. In GoDaddy, replace the existing `domaincontrol.com` nameservers with Cloudflare's nameservers.
4. In Cloudflare Workers, attach this Worker to:
   - `vibesyall.com`
   - `www.vibesyall.com`
   - `api.vibesyall.com`
5. Update `APP_BASE_URL` to `https://api.vibesyall.com`.
6. Run:

```bash
npm run domains:check
```

7. After the API hostname passes, run:

```bash
npm run ios:set-backend-url -- https://api.vibesyall.com
```

Then push a new TestFlight build.

## Scale Notes

- Map filters read from `place_vibe_counts`, not raw ratings.
- Community top vibes read from compact per-place counts.
- Raw ratings stay unique by `(place_id, device_id_hash)`, so one device updates its vote rather than spamming duplicates.
- Nearby lookups use latitude/longitude indexes and radius caps.
- Worker observability sampling is set to `0.1` to avoid full-volume trace overhead.
- Submitted vibes do not fall back to mock storage in production; data either reaches Cloudflare or the user gets an error.
