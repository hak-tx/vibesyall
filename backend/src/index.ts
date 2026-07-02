import { LANDING_ASSETS } from "./landing-assets";

const DEFAULT_NEARBY_RADIUS_METERS = 5_000;
const MIN_NEARBY_RADIUS_METERS = 100;
const MAX_NEARBY_RADIUS_METERS = 2_500_000;
const MAX_NEARBY_QUERY_ROWS = 1_500;
const MAX_NEARBY_RESPONSE_PLACES = 320;
const MAX_MAP_CELL_QUERY_ROWS = 8_000;
const MAX_MAP_CELL_RESPONSE_CELLS = 260;
const MIN_MAP_CELL_SIZE_METERS = 10_000;
const MAX_MAP_CELL_SIZE_METERS = 300_000;
const CACHE_VERSION = "2026-07-01-vibesyall-site-2";
const CACHE_TTL_SECONDS = {
  marketing: 3_600,
  vibeTaxonomy: 3_600,
  publicPlace: 30,
  nearby: 300,
  mapCells: 600,
} as const;

const VIBE_TAG_DEFINITIONS = [
  {
    id: "changed_my_life",
    slug: "changed_my_life",
    display_name: "Changed my Life",
    emoji: "⭐",
    sentiment_group: "positive",
    sort_order: 10,
  },
  { id: "fire", slug: "fire", display_name: "Fire", emoji: "🔥", sentiment_group: "positive", sort_order: 20 },
  {
    id: "worth_the_drive",
    slug: "worth_the_drive",
    display_name: "Worth the Drive",
    emoji: "🚗",
    sentiment_group: "positive",
    sort_order: 30,
  },
  { id: "iconic", slug: "iconic", display_name: "Iconic", emoji: "🌟", sentiment_group: "identity", sort_order: 40 },
  { id: "hidden_gem", slug: "hidden_gem", display_name: "Hidden Gem", emoji: "💎", sentiment_group: "positive", sort_order: 50 },
  { id: "underrated", slug: "underrated", display_name: "Underrated", emoji: "📈", sentiment_group: "positive", sort_order: 60 },
  { id: "mid", slug: "mid", display_name: "Mid", emoji: "😐", sentiment_group: "neutral", sort_order: 70 },
  { id: "chaos", slug: "chaos", display_name: "Chaos", emoji: "🌪", sentiment_group: "neutral", sort_order: 80 },
  { id: "overrated", slug: "overrated", display_name: "Overrated", emoji: "👎", sentiment_group: "negative", sort_order: 90 },
  {
    id: "tourist_trap",
    slug: "tourist_trap",
    display_name: "Tourist Trap",
    emoji: "📸",
    sentiment_group: "negative",
    sort_order: 100,
  },
  {
    id: "needs_prayer",
    slug: "needs_prayer",
    display_name: "Needs Prayer",
    emoji: "🙏",
    sentiment_group: "negative",
    sort_order: 110,
  },
  {
    id: "emotionally_damaging",
    slug: "emotionally_damaging",
    display_name: "Emotionally Damaging",
    emoji: "💀",
    sentiment_group: "negative",
    sort_order: 120,
  },
] as const;

const CLIENT_VIBES = [
  "Changed my Life",
  "Fire",
  "Worth the Drive",
  "Iconic",
  "Hidden Gem",
  "Underrated",
  "Mid",
  "Chaos",
  "Overrated",
  "Tourist Trap",
  "Needs Prayer",
  "Emotionally Damaging",
] as const;

const REPORT_REASONS = ["wrong_place", "duplicate_place", "spam_or_brigading", "inappropriate", "other"] as const;
const REPORT_STATUSES = ["open", "reviewed", "dismissed", "action_taken"] as const;
const ACTIVE_EVENT_WHERE = "moderation_status = 'active' AND is_deleted = 0";
const ACCOUNT_SIGNUP_THRESHOLD_DEFAULT = 10;
const EMAIL_CONFIRMATION_TTL_MS = 24 * 60 * 60 * 1000;
const PROFILE_SESSION_TTL_MS = 365 * 24 * 60 * 60 * 1000;
const VIBES_MARKETING_HOST = "vibesyall.com";
const SUPPORT_EMAIL = "vibesyall@gmail.com";
const BETA_ACCESS_HEADER = "X-Vibe-Beta-Token";

type VibeTagID = (typeof VIBE_TAG_DEFINITIONS)[number]["id"];
type SentimentGroup = (typeof VIBE_TAG_DEFINITIONS)[number]["sentiment_group"];
type ReportReason = (typeof REPORT_REASONS)[number];
type ReportStatus = (typeof REPORT_STATUSES)[number];

type VibeTagRow = {
  id: VibeTagID;
  slug: string;
  display_name: string;
  emoji: string | null;
  sentiment_group: SentimentGroup;
  sort_order: number;
  is_active: number;
};

type PlaceRow = {
  id: string;
  provider: string | null;
  provider_place_id: string | null;
  name: string;
  latitude: number;
  longitude: number;
  street_address: string | null;
  category: string | null;
  city: string | null;
  region: string | null;
  country: string | null;
  created_at: string;
  updated_at: string;
};

type PlaceStatsRow = {
  place_id: string;
  total_vibes: number;
  top_vibe_tag_id: VibeTagID | null;
  top_vibe_percent: number | null;
  second_vibe_tag_id: VibeTagID | null;
  second_vibe_percent: number | null;
  last_30_day_total_vibes: number;
  last_30_day_top_vibe_tag_id: VibeTagID | null;
  last_30_day_top_vibe_percent: number | null;
  last_year_total_vibes: number;
  last_year_top_vibe_tag_id: VibeTagID | null;
  last_year_top_vibe_percent: number | null;
  updated_at: string;
};

type NearbyPlaceRow = PlaceRow & {
  stats_total_vibes: number;
  stats_top_vibe_tag_id: VibeTagID | null;
  stats_top_vibe_percent: number | null;
  stats_second_vibe_tag_id: VibeTagID | null;
  stats_second_vibe_percent: number | null;
  stats_last_30_day_total_vibes: number;
  stats_last_30_day_top_vibe_tag_id: VibeTagID | null;
  stats_last_30_day_top_vibe_percent: number | null;
  stats_last_year_total_vibes: number;
  stats_last_year_top_vibe_tag_id: VibeTagID | null;
  stats_last_year_top_vibe_percent: number | null;
  stats_updated_at: string;
};

type MapCellPlaceRow = {
  id: string;
  latitude: number;
  longitude: number;
  stats_total_vibes: number;
  stats_top_vibe_tag_id: VibeTagID | null;
  stats_top_vibe_percent: number | null;
  stats_second_vibe_tag_id: VibeTagID | null;
  stats_second_vibe_percent: number | null;
};

type VibeEventRow = {
  id: string;
  place_id: string;
  anonymous_user_id: string;
  primary_vibe_tag_id: VibeTagID;
  secondary_vibe_tag_id: VibeTagID | null;
  third_vibe_tag_id: VibeTagID | null;
  source: string;
  app_version: string | null;
  created_at: string;
  updated_at: string;
  is_flagged: number;
  is_deleted: number;
  moderation_status: string;
};

type TagCountRow = {
  vibe_tag_id: VibeTagID;
  tag_count: number;
};

type EventTotalRow = {
  total_vibes: number;
};

type PlaceInput = {
  provider?: unknown;
  provider_place_id?: unknown;
  providerPlaceId?: unknown;
  name?: unknown;
  latitude?: unknown;
  longitude?: unknown;
  street_address?: unknown;
  streetAddress?: unknown;
  category?: unknown;
  city?: unknown;
  region?: unknown;
  country?: unknown;
};

type VibeInput = {
  place_id?: unknown;
  placeId?: unknown;
  anonymous_user_id?: unknown;
  anonymousUserId?: unknown;
  device_id_hash?: unknown;
  deviceIdHash?: unknown;
  device_id?: unknown;
  deviceId?: unknown;
  primary_vibe_tag_id?: unknown;
  primaryVibeTagId?: unknown;
  primary_vibe_tag_slug?: unknown;
  primaryVibeTagSlug?: unknown;
  primary_vibe_tag?: unknown;
  primaryVibeTag?: unknown;
  secondary_vibe_tag_id?: unknown;
  secondaryVibeTagId?: unknown;
  secondary_vibe_tag_slug?: unknown;
  secondaryVibeTagSlug?: unknown;
  secondary_vibe_tag?: unknown;
  secondaryVibeTag?: unknown;
  third_vibe_tag_id?: unknown;
  thirdVibeTagId?: unknown;
  third_vibe_tag_slug?: unknown;
  thirdVibeTagSlug?: unknown;
  third_vibe_tag?: unknown;
  thirdVibeTag?: unknown;
  vibe_tag?: unknown;
  vibeTag?: unknown;
  vibe_tag_secondary?: unknown;
  vibeTagSecondary?: unknown;
  vibe_tag_third?: unknown;
  vibeTagThird?: unknown;
  vibe_tags?: unknown;
  vibeTags?: unknown;
  source?: unknown;
  app_version?: unknown;
  appVersion?: unknown;
};

type ReportInput = {
  place_id?: unknown;
  placeId?: unknown;
  anonymous_user_id?: unknown;
  anonymousUserId?: unknown;
  device_id_hash?: unknown;
  deviceIdHash?: unknown;
  device_id?: unknown;
  deviceId?: unknown;
  reason?: unknown;
};

type DeviceIdentityInput = {
  device_id_hash?: unknown;
  deviceIdHash?: unknown;
  device_id?: unknown;
  deviceId?: unknown;
};

type AccountSignupInput = DeviceIdentityInput & {
  email?: unknown;
  redirect_url?: unknown;
  redirectUrl?: unknown;
};

type AccountEmailSender = {
  send(message: {
    from: string;
    to: string;
    subject: string;
    text?: string;
    html?: string;
    headers?: Record<string, string>;
  }): Promise<unknown>;
};

type RuntimeEnv = Env & {
  APP_BASE_URL?: string;
  APP_STORE_URL?: string;
  IOS_DEEP_LINK_SCHEME?: string;
  ACCOUNT_EMAIL_FROM?: string;
  ACCOUNT_SIGNUP_THRESHOLD?: string;
  VIBE_BETA_ACCESS_TOKEN?: string;
  VIBE_BETA_GATE_MODE?: string;
  SIGNUP_EMAIL?: AccountEmailSender;
};

type ProfileRow = {
  id: string;
  email: string;
  email_normalized: string;
  email_hash: string;
  email_verified_at: string | null;
  created_at: string;
  updated_at: string;
  last_seen_at: string;
};

type ProfileTokenRow = {
  id: string;
  profile_id: string;
  token_hash: string;
  redirect_url: string | null;
  expires_at: string;
  consumed_at: string | null;
  email: string;
  email_normalized: string;
  email_verified_at: string | null;
};

type AnonymousUserAliasRow = {
  alias_anonymous_user_id: string;
};

const TAG_BY_ID = new Map(VIBE_TAG_DEFINITIONS.map((tag) => [tag.id, tag]));
const POSITIVE_TAG_IDS = new Set<VibeTagID>([
  "changed_my_life",
  "fire",
  "worth_the_drive",
  "iconic",
  "hidden_gem",
  "underrated",
]);

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = normalizedPath(url.pathname);
    if (!hasBetaAccess(request, env, path)) {
      return json({ error: "Beta access required." }, { status: 403 });
    }

    const rateLimit = rateLimitDecision(request);
    if (!rateLimit.allowed) {
      return json({ error: "Too many vibes too quickly." }, { status: 429 });
    }

    try {
      const isReadRequest = request.method === "GET" || request.method === "HEAD";

      if (isReadRequest && path === "/") {
        if (request.method === "HEAD") {
          return headResponse(landingPage(request, env));
        }
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.marketing, () => landingPage(request, env));
      }

      if (isReadRequest && path === "/privacy") {
        if (request.method === "HEAD") {
          return headResponse(privacyPage(request, env));
        }
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.marketing, () => privacyPage(request, env));
      }

      if (isReadRequest && path === "/terms") {
        if (request.method === "HEAD") {
          return headResponse(termsPage(request, env));
        }
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.marketing, () => termsPage(request, env));
      }

      if (isReadRequest && path === "/support") {
        if (request.method === "HEAD") {
          return headResponse(supportPage(request, env));
        }
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.marketing, () => supportPage(request, env));
      }

      if (isReadRequest && path === "/health") {
        const response = json({ ok: true, service: "vibe-map-api", data_model: "human_labeled_place_sentiment_v1" });
        return request.method === "HEAD" ? headResponse(response) : response;
      }

      if (request.method === "GET" && path === "/vibes") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.vibeTaxonomy, () =>
          json({ vibes: CLIENT_VIBES }, { headers: publicCacheHeaders(CACHE_TTL_SECONDS.vibeTaxonomy) })
        );
      }

      if (request.method === "GET" && path === "/vibes/tags") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.vibeTaxonomy, () => getVibeTags(env));
      }

      if (request.method === "GET" && path === "/account/eligibility") {
        return getAccountEligibility(request, env);
      }

      if (request.method === "GET" && path === "/account/status") {
        return getAccountEligibility(request, env);
      }

      if (request.method === "POST" && path === "/account/signup") {
        return requestAccountSignup(request, env);
      }

      if (request.method === "GET" && path === "/account/confirm") {
        return confirmAccountEmail(url, env);
      }

      if (request.method === "GET" && path === "/places/nearby") {
        if (!hasDeviceIdentity(request)) {
          return cachedGET(request, ctx, CACHE_TTL_SECONDS.nearby, () => getNearbyPlaces(request, url, env));
        }
        return getNearbyPlaces(request, url, env);
      }

      if (request.method === "GET" && path === "/places/map-cells") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.mapCells, () => getPlaceMapCells(url, env));
      }

      if (request.method === "POST" && path === "/places") {
        return upsertPlace(request, env);
      }

      if (request.method === "POST" && (path === "/vibes" || path === "/ratings")) {
        return upsertVibe(request, env);
      }

      if (request.method === "POST" && path === "/reports") {
        return reportPlace(request, env);
      }

      const legacyReportMatch = path.match(/^\/places\/([^/]+)\/report$/);
      if (request.method === "POST" && legacyReportMatch) {
        return reportPlace(request, env, decodeURIComponent(legacyReportMatch[1]));
      }

      const placeMatch = path.match(/^\/places\/([^/]+)$/);
      if (request.method === "GET" && placeMatch) {
        if (!hasDeviceIdentity(request)) {
          return cachedGET(request, ctx, CACHE_TTL_SECONDS.publicPlace, () => getPlace(decodeURIComponent(placeMatch[1]), request, env));
        }
        return getPlace(decodeURIComponent(placeMatch[1]), request, env);
      }

      return json({ error: "Route not found." }, { status: 404 });
    } catch (error) {
      console.error(JSON.stringify({ message: "Unhandled Worker error", error: String(error) }));
      return json({ error: "Something went sideways." }, { status: 500 });
    }
  },
} satisfies ExportedHandler<Env>;

async function getVibeTags(env: Env): Promise<Response> {
  const tags = await fetchActiveVibeTags(env);
  return json({ tags }, { headers: publicCacheHeaders(CACHE_TTL_SECONDS.vibeTaxonomy) });
}

async function getAccountEligibility(request: Request, env: Env): Promise<Response> {
  const deviceIDHash = await deviceHashFromRequest(request);
  if (!deviceIDHash) {
    return json({ error: "X-Vibe-Device-ID-Hash is required." }, { status: 400 });
  }

  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  return json({ account: await buildAccountEligibility(env, deviceIDHash, anonymousUserID) });
}

async function requestAccountSignup(request: Request, env: Env): Promise<Response> {
  const body = await readJson<AccountSignupInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const email = normalizeEmail(body.value.email);
  if (!email) {
    return json({ error: "A valid email address is required." }, { status: 400 });
  }

  const deviceIDHash = await deviceHashFromBody(body.value);
  if (!deviceIDHash) {
    return json({ error: "device_id_hash is required." }, { status: 400 });
  }

  const now = new Date().toISOString();
  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  await upsertAnonymousUser(env, anonymousUserID, deviceIDHash, now);

  const eligibility = await buildAccountEligibility(env, deviceIDHash, anonymousUserID);
  if (!eligibility.eligible) {
    return json(
      {
        error: `Create an account after ${eligibility.threshold} vibed places.`,
        account: eligibility,
      },
      { status: 403 }
    );
  }

  const profile = await upsertProfileForEmailAndDevice(env, email, deviceIDHash, anonymousUserID, now);
  const rawToken = await randomToken();
  const tokenHash = await sha256Hex(`vibes-yall-email-token:${rawToken}`);
  const tokenID = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + EMAIL_CONFIRMATION_TTL_MS).toISOString();
  const redirectURL = cleanString(body.value.redirect_url ?? body.value.redirectUrl);

  await env.DB.prepare(
    `INSERT INTO email_confirmation_tokens (id, profile_id, token_hash, purpose, redirect_url, expires_at, created_at)
     VALUES (?, ?, ?, 'email_confirmation', ?, ?, ?)`
  )
    .bind(tokenID, profile.id, tokenHash, redirectURL, expiresAt, now)
    .run();

  const confirmationURL = confirmationURLForToken(request, env, rawToken);
  const emailSent = await sendAccountConfirmationEmail(env, email, confirmationURL);

  return json(
    {
      status: "confirmation_sent",
      email_sent: emailSent,
      account: {
        ...eligibility,
        profile: serializeProfile(profile),
      },
      message: emailSent
        ? "Check your email to confirm your VIBES Y'ALL account."
        : "Confirmation token created. Configure Cloudflare email sending to deliver it automatically.",
    },
    { status: 202 }
  );
}

async function confirmAccountEmail(url: URL, env: Env): Promise<Response> {
  const token = cleanString(url.searchParams.get("token"));
  if (!token) {
    return accountResultPage("That confirmation link is missing its token.", false, env);
  }

  const tokenHash = await sha256Hex(`vibes-yall-email-token:${token}`);
  const row = await env.DB.prepare(
    `SELECT
       ect.id,
       ect.profile_id,
       ect.token_hash,
       ect.redirect_url,
       ect.expires_at,
       ect.consumed_at,
       p.email,
       p.email_normalized,
       p.email_verified_at
     FROM email_confirmation_tokens ect
     JOIN profiles p ON p.id = ect.profile_id
     WHERE ect.token_hash = ?
     LIMIT 1`
  )
    .bind(tokenHash)
    .first<ProfileTokenRow>();

  if (!row) {
    return accountResultPage("That confirmation link is not valid.", false, env);
  }

  if (row.consumed_at) {
    return accountResultPage("That confirmation link was already used.", false, env);
  }

  if (Date.parse(row.expires_at) < Date.now()) {
    return accountResultPage("That confirmation link expired. Request a new one from the app.", false, env);
  }

  const now = new Date().toISOString();
  const rawSessionToken = await randomToken();
  const sessionHash = await sha256Hex(`vibes-yall-profile-session:${rawSessionToken}`);
  const sessionID = crypto.randomUUID();
  const sessionExpiresAt = new Date(Date.now() + PROFILE_SESSION_TTL_MS).toISOString();

  await env.DB.batch([
    env.DB.prepare("UPDATE email_confirmation_tokens SET consumed_at = ? WHERE id = ?").bind(now, row.id),
    env.DB.prepare(
      `UPDATE profiles
       SET email_verified_at = COALESCE(email_verified_at, ?),
           updated_at = ?,
           last_seen_at = ?
       WHERE id = ?`
    ).bind(now, now, now, row.profile_id),
    env.DB.prepare(
      `INSERT INTO profile_sessions (id, profile_id, token_hash, created_at, expires_at, last_seen_at)
       VALUES (?, ?, ?, ?, ?, ?)`
    ).bind(sessionID, row.profile_id, sessionHash, now, sessionExpiresAt, now),
  ]);

  const appURL = deepLinkURLForAccount(env, rawSessionToken, row.redirect_url);
  return accountResultPage("Your account is confirmed.", true, env, appURL);
}

async function buildAccountEligibility(env: Env, deviceIDHash: string, anonymousUserID: string) {
  const threshold = accountSignupThreshold(env);
  const anonymousUserIDs = await anonymousUserIDsForPrimary(env, anonymousUserID);
  const vibedPlaceCount = await countVibedPlacesForAnonymousUsers(env, anonymousUserIDs);
  const profile = await fetchProfileForDeviceHash(env, deviceIDHash);

  return {
    eligible: vibedPlaceCount >= threshold,
    threshold,
    vibed_place_count: vibedPlaceCount,
    remaining_places: Math.max(threshold - vibedPlaceCount, 0),
    benefits: [
      "Keep your past and future vibes tied to one account.",
      "Move phones without losing your place history.",
      "Edit past vibes when your opinion changes.",
      "Help keep the map authentic and harder to spam.",
    ],
    profile: profile ? serializeProfile(profile) : null,
  };
}

async function countVibedPlacesForAnonymousUsers(env: Env, anonymousUserIDs: string[]): Promise<number> {
  const uniqueAnonymousUserIDs = [...new Set(anonymousUserIDs)].filter(Boolean);
  if (uniqueAnonymousUserIDs.length === 0) {
    return 0;
  }

  const placeholders = uniqueAnonymousUserIDs.map(() => "?").join(", ");
  const result = await env.DB.prepare(
    `SELECT COUNT(DISTINCT place_id) AS total_vibes
     FROM vibe_events
     WHERE anonymous_user_id IN (${placeholders}) AND ${ACTIVE_EVENT_WHERE}`
  )
    .bind(...uniqueAnonymousUserIDs)
    .first<EventTotalRow>();

  return result?.total_vibes ?? 0;
}

async function fetchProfileForDeviceHash(env: Env, deviceIDHash: string): Promise<ProfileRow | null> {
  return env.DB.prepare(
    `SELECT p.*
     FROM profiles p
     JOIN profile_devices pd ON pd.profile_id = p.id
     WHERE pd.device_id_hash = ?
     LIMIT 1`
  )
    .bind(deviceIDHash)
    .first<ProfileRow>();
}

async function upsertProfileForEmailAndDevice(
  env: Env,
  email: string,
  deviceIDHash: string,
  anonymousUserID: string,
  now: string
): Promise<ProfileRow> {
  const emailHash = await sha256Hex(`vibes-yall-email:${email}`);
  const profileID = `profile_${emailHash.slice(0, 32)}`;

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO profiles (id, email, email_normalized, email_hash, created_at, updated_at, last_seen_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(email_normalized) DO UPDATE SET
         email = excluded.email,
         email_hash = excluded.email_hash,
         updated_at = excluded.updated_at,
         last_seen_at = excluded.last_seen_at`
    ).bind(profileID, email, email, emailHash, now, now, now),
    env.DB.prepare(
      `INSERT INTO profile_devices (profile_id, anonymous_user_id, device_id_hash, linked_at)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(device_id_hash) DO UPDATE SET
         profile_id = excluded.profile_id,
         anonymous_user_id = excluded.anonymous_user_id,
         linked_at = excluded.linked_at`
    ).bind(profileID, anonymousUserID, deviceIDHash, now),
  ]);

  const profile = await env.DB.prepare("SELECT * FROM profiles WHERE email_normalized = ?").bind(email).first<ProfileRow>();
  if (!profile) {
    throw new Error("Profile could not be saved.");
  }
  return profile;
}

function serializeProfile(profile: ProfileRow) {
  return {
    id: profile.id,
    email: profile.email,
    email_verified: Boolean(profile.email_verified_at),
    email_verified_at: profile.email_verified_at,
    created_at: profile.created_at,
    updated_at: profile.updated_at,
  };
}

function normalizeEmail(value: unknown): string | null {
  const email = cleanString(value)?.toLowerCase();
  if (!email || email.length > 254) {
    return null;
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return null;
  }
  return email;
}

function accountSignupThreshold(env: Env): number {
  const configured = Number((env as RuntimeEnv).ACCOUNT_SIGNUP_THRESHOLD ?? "");
  return Number.isFinite(configured) && configured > 0 ? configured : ACCOUNT_SIGNUP_THRESHOLD_DEFAULT;
}

function confirmationURLForToken(request: Request, env: Env, token: string): string {
  const runtimeEnv = env as RuntimeEnv;
  const baseURL = cleanString(runtimeEnv.APP_BASE_URL) ?? originForRequest(request);
  const url = new URL("/account/confirm", baseURL);
  url.searchParams.set("token", token);
  return url.toString();
}

function originForRequest(request: Request): string {
  const url = new URL(request.url);
  if (url.hostname.endsWith(".workers.dev")) {
    return `${url.protocol}//${url.host}`;
  }
  return `https://${VIBES_MARKETING_HOST}`;
}

function deepLinkURLForAccount(env: Env, sessionToken: string, redirectURL?: string | null): string {
  if (redirectURL) {
    const url = new URL(redirectURL);
    url.searchParams.set("session", sessionToken);
    return url.toString();
  }

  const scheme = cleanString((env as RuntimeEnv).IOS_DEEP_LINK_SCHEME) ?? "vibesyall";
  return `${scheme}://account/confirmed?session=${encodeURIComponent(sessionToken)}`;
}

async function sendAccountConfirmationEmail(env: Env, email: string, confirmationURL: string): Promise<boolean> {
  const runtimeEnv = env as RuntimeEnv;
  const sender = runtimeEnv.SIGNUP_EMAIL;
  const from = cleanString(runtimeEnv.ACCOUNT_EMAIL_FROM) ?? SUPPORT_EMAIL;

  if (!sender) {
    console.log(JSON.stringify({ message: "Account email sender is not configured.", email, confirmation_url: confirmationURL }));
    return false;
  }

  await sender.send({
    from,
    to: email,
    subject: "Confirm your VIBES Y'ALL account",
    text: [
      "Confirm your VIBES Y'ALL account:",
      confirmationURL,
      "",
      "This keeps your past and future vibes tied to you when you switch devices.",
    ].join("\n"),
    html: `
      <p>Confirm your <strong>VIBES Y'ALL</strong> account:</p>
      <p><a href="${escapeHTML(confirmationURL)}">Confirm account</a></p>
      <p>This keeps your past and future vibes tied to you when you switch devices.</p>
    `,
  });
  return true;
}

async function randomToken(): Promise<string> {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function landingPage(request: Request, env: Env): Response {
  const appStoreURL = cleanString((env as RuntimeEnv).APP_STORE_URL) ?? "https://apps.apple.com/";
  const privacyURL = new URL("/privacy", request.url).toString();
  const termsURL = new URL("/terms", request.url).toString();
  const supportURL = new URL("/support", request.url).toString();
  const screenshots = LANDING_ASSETS.screenshots
    .filter((screenshot) => {
      const alt = screenshot.alt.toLowerCase();
      return alt.includes("selected vibes") || alt.includes("clustered vibe map");
    })
    .map(
      (screenshot, index) => `
        <figure class="phone-shot shot-${index + 1}">
          <img src="${escapeHTML(screenshot.src)}" alt="${escapeHTML(screenshot.alt)}" loading="${index === 0 ? "eager" : "lazy"}">
        </figure>`
    )
    .join("");
  const screenshotsSection = screenshots
    ? `<section class="showcase two-up" aria-label="VIBES Y'ALL app screenshots">
      ${screenshots}
    </section>`
    : "";

  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>VIBES Y'ALL</title>
  <meta name="description" content="Find places by how they feel, not by star ratings.">
  <style>${landingCSS()}</style>
</head>
<body>
  <main class="hero">
    <section class="hero-copy">
      <img class="app-icon" src="${escapeHTML(LANDING_ASSETS.appIcon)}" alt="VIBES Y'ALL app icon">
      <p class="eyebrow">Map-first place discovery</p>
      <h1>Find places by the vibe.</h1>
      <p class="lede">No stars, no comments, no noise. Tap a real place, pick up to three vibes, and see what everyone else felt.</p>
      <div class="actions">
        <a class="button primary" href="${escapeHTML(appStoreURL)}">Download on the App Store</a>
        <a class="button ghost" href="${escapeHTML(privacyURL)}">Privacy</a>
      </div>
    </section>
    ${screenshotsSection}
  </main>
  <section class="features">
    <article><strong>Structured vibes</strong><span>Clean human labels instead of messy written reviews.</span></article>
    <article><strong>Anonymous first</strong><span>Start contributing without an account.</span></article>
    <article><strong>Account optional</strong><span>After 10 places, save your history across devices.</span></article>
  </section>
  <footer>
    <span>© ${new Date().getUTCFullYear()} VIBES Y'ALL</span>
    <a href="${escapeHTML(supportURL)}">Support</a>
    <a href="${escapeHTML(privacyURL)}">Privacy Policy</a>
    <a href="${escapeHTML(termsURL)}">Terms</a>
  </footer>
</body>
</html>`);
}

function privacyPage(_request: Request, _env: Env): Response {
  return documentPage(
    "Privacy Policy",
    [
      "VIBES Y'ALL is built around lightweight, structured place sentiment. In V1, we do not collect comments, photos, public profiles, phone numbers, or star ratings.",
      "You can use the app anonymously. Anonymous activity is tied to a hashed device identifier so one device can update its own vibe for a place without creating duplicate votes.",
      "If you choose to create an account after contributing enough places, we collect your email address to confirm the account and let you keep your vibe history if you switch devices.",
      "Public app responses show aggregate place vibe data. Raw vibe events, anonymous user ids, device hashes, and email addresses are not public.",
      `Contact: ${SUPPORT_EMAIL}`,
    ],
    "Last updated June 30, 2026"
  );
}

function termsPage(_request: Request, _env: Env): Response {
  return documentPage(
    "Terms of Use",
    [
      "VIBES Y'ALL lets users submit structured vibe labels for real-world places. Do not use the app to spam, manipulate, harass, or misrepresent places.",
      "The app is provided as-is while it is being developed. Map, place, and community-vibe data may be incomplete or change over time.",
      "We may remove or hide suspicious, abusive, or low-quality submissions to protect data quality.",
      "By using the app, you agree that aggregate, non-personal place-vibe data may be used to operate the app and build future place analytics products.",
      `Contact: ${SUPPORT_EMAIL}`,
    ],
    "Last updated June 30, 2026"
  );
}

function supportPage(_request: Request, _env: Env): Response {
  const email = SUPPORT_EMAIL;
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Support | VIBES Y'ALL</title>
  <style>${landingCSS()}</style>
</head>
<body>
  <main class="document support">
    <a class="back" href="/">VIBES Y'ALL</a>
    <h1>Support</h1>
    <p class="updated">Need help with VIBES Y'ALL?</p>
    <p>Email us for app support, account help, place corrections, privacy questions, or TestFlight feedback.</p>
    <div class="actions">
      <a class="button primary" href="mailto:${escapeHTML(email)}">${escapeHTML(email)}</a>
    </div>
  </main>
</body>
</html>`);
}

function documentPage(title: string, paragraphs: string[], updated: string): Response {
  const body = paragraphs.map((paragraph) => `<p>${escapeHTML(paragraph)}</p>`).join("");
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHTML(title)} | VIBES Y'ALL</title>
  <style>${landingCSS()}</style>
</head>
<body>
  <main class="document">
    <a class="back" href="/">VIBES Y'ALL</a>
    <h1>${escapeHTML(title)}</h1>
    <p class="updated">${escapeHTML(updated)}</p>
    ${body}
  </main>
</body>
</html>`);
}

function accountResultPage(message: string, success: boolean, env: Env, appURL?: string): Response {
  const appStoreURL = cleanString((env as RuntimeEnv).APP_STORE_URL) ?? "https://apps.apple.com/";
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${success ? "Account confirmed" : "Account link issue"} | VIBES Y'ALL</title>
  <style>${landingCSS()}</style>
</head>
<body>
  <main class="document center">
    <div class="brand small">VIBES<br>Y'ALL</div>
    <h1>${escapeHTML(message)}</h1>
    <p>${success ? "You can go back to the app and keep building your place history." : "Open the app and request a fresh confirmation email."}</p>
    <div class="actions centered">
      ${appURL ? `<a class="button primary" href="${escapeHTML(appURL)}">Open the app</a>` : ""}
      <a class="button ghost" href="${escapeHTML(appStoreURL)}">App Store</a>
    </div>
  </main>
</body>
</html>`);
}

function landingCSS(): string {
  return `
    :root {
      color-scheme: light;
      --navy: #102c6b;
      --yellow: #dfd771;
      --warm: #faf8f4;
      --cream: #fffaf0;
      --ink: #071321;
      --muted: #657184;
      --line: rgba(16, 44, 107, 0.14);
      --shadow: rgba(16, 44, 107, 0.18);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at 78% 10%, rgba(223, 215, 113, 0.38), transparent 26rem),
        radial-gradient(circle at 15% 68%, rgba(16, 44, 107, 0.12), transparent 24rem),
        var(--warm);
      color: var(--ink);
    }
    .hero {
      min-height: 86vh;
      display: grid;
      grid-template-columns: minmax(0, 0.92fr) minmax(20rem, 1.08fr);
      align-items: center;
      gap: clamp(2rem, 6vw, 5rem);
      padding: clamp(2rem, 8vw, 7rem);
      overflow: hidden;
    }
    .brand {
      display: grid;
      place-items: center;
      aspect-ratio: 1;
      border-radius: 2rem;
      background: var(--navy);
      color: var(--yellow);
      font-size: clamp(2rem, 5vw, 4.8rem);
      font-weight: 950;
      line-height: 0.82;
      letter-spacing: 0;
      box-shadow: 0 2rem 5rem rgba(16, 44, 107, 0.22);
    }
    .brand.small {
      width: 7rem;
      font-size: 2rem;
      margin: 0 auto 1.5rem;
    }
    .hero-copy {
      position: relative;
      z-index: 2;
    }
    .app-icon {
      width: clamp(5rem, 12vw, 8rem);
      height: clamp(5rem, 12vw, 8rem);
      display: block;
      border-radius: 1.5rem;
      box-shadow: 0 1.4rem 3rem var(--shadow);
      margin-bottom: clamp(1.4rem, 3vw, 2.2rem);
    }
    .eyebrow {
      color: var(--navy);
      font-weight: 850;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      font-size: 0.82rem;
    }
    h1 {
      margin: 0;
      max-width: 12ch;
      font-size: clamp(3.6rem, 8vw, 6.6rem);
      line-height: 0.9;
      letter-spacing: 0;
    }
    .lede {
      max-width: 38rem;
      color: var(--muted);
      font-size: clamp(1.1rem, 2vw, 1.45rem);
      line-height: 1.42;
      font-weight: 600;
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 0.85rem;
      margin-top: 2rem;
    }
    .actions.centered { justify-content: center; }
    .button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 3.25rem;
      padding: 0 1.2rem;
      border-radius: 999px;
      font-weight: 850;
      text-decoration: none;
      border: 1px solid var(--line);
    }
    .primary { background: var(--navy); color: white; }
    .ghost { background: rgba(255, 255, 255, 0.74); color: var(--navy); }
    .showcase {
      position: relative;
      min-height: clamp(32rem, 54vw, 48rem);
      isolation: isolate;
    }
    .phone-shot {
      position: absolute;
      margin: 0;
      width: min(36vw, 18.5rem);
      border: 0.48rem solid #071321;
      border-radius: 2.5rem;
      overflow: hidden;
      background: #071321;
      box-shadow: 0 2rem 4.5rem rgba(7, 19, 33, 0.2);
    }
    .phone-shot img {
      display: block;
      width: 100%;
      height: auto;
    }
    .shot-1 {
      left: 0;
      top: 9%;
      z-index: 3;
      transform: rotate(-4deg);
    }
    .shot-2 {
      left: 31%;
      top: 0;
      z-index: 2;
      transform: rotate(3deg);
    }
    .shot-3 {
      right: 0;
      top: 13%;
      z-index: 1;
      transform: rotate(5deg);
    }
    .two-up .shot-1 {
      left: 10%;
      top: 5%;
      transform: rotate(-3deg);
    }
    .two-up .shot-2 {
      left: auto;
      right: 11%;
      top: 0;
      transform: rotate(4deg);
    }
    .features {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 1rem;
      padding: 0 clamp(2rem, 8vw, 7rem) 4rem;
    }
    .features article {
      padding: 1.25rem;
      border: 1px solid var(--line);
      border-radius: 1.25rem;
      background: rgba(255, 255, 255, 0.66);
      box-shadow: 0 1rem 2.5rem rgba(16, 44, 107, 0.08);
    }
    .features strong,
    .features span {
      display: block;
    }
    .features strong {
      font-size: 1.05rem;
      margin-bottom: 0.35rem;
    }
    .features span {
      color: var(--muted);
      line-height: 1.35;
      font-weight: 600;
    }
    footer {
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
      padding: 1.5rem clamp(2rem, 8vw, 7rem) 2rem;
      color: var(--muted);
      font-weight: 650;
    }
    footer a,
    .back {
      color: var(--navy);
      font-weight: 850;
      text-decoration: none;
    }
    .document {
      width: min(100%, 48rem);
      margin: 0 auto;
      padding: clamp(2rem, 8vw, 5rem) 1.5rem;
    }
    .document.center { text-align: center; }
    .document h1 {
      max-width: none;
      font-size: clamp(2.6rem, 7vw, 5.5rem);
      margin: 1rem 0;
    }
    .document p {
      color: var(--muted);
      font-size: 1.08rem;
      line-height: 1.55;
      font-weight: 600;
    }
    .updated {
      color: var(--navy) !important;
      font-weight: 850 !important;
    }
    @media (max-width: 720px) {
      .hero {
        min-height: auto;
        grid-template-columns: 1fr;
        padding: 2rem 1.25rem 2.5rem;
      }
      .showcase {
        min-height: 30rem;
        margin: 0 -0.5rem;
      }
      .phone-shot {
        width: 42vw;
        border-width: 0.32rem;
        border-radius: 1.6rem;
      }
      .shot-1 {
        left: 0;
        top: 2rem;
      }
      .shot-2 {
        left: 29%;
        top: 0;
      }
      .shot-3 {
        right: 0;
        top: 2.6rem;
      }
      .two-up .shot-1 {
        left: 4%;
        top: 1.5rem;
      }
      .two-up .shot-2 {
        right: 4%;
        top: 0;
      }
      .features {
        grid-template-columns: 1fr;
        padding: 0 1.25rem 2rem;
      }
      footer {
        padding: 1.25rem;
      }
    }
  `;
}

function html(markup: string, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "text/html; charset=utf-8");
  if (!headers.has("Cache-Control")) {
    headers.set("Cache-Control", "no-store");
  }
  return new Response(markup, { ...init, headers });
}

function headResponse(response: Response): Response {
  return new Response(null, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

function escapeHTML(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

async function getNearbyPlaces(request: Request, url: URL, env: Env): Promise<Response> {
  const latitude = numberParam(url, "lat");
  const longitude = numberParam(url, "lng");
  const radius = Math.min(
    Math.max(numberParam(url, "radius") ?? DEFAULT_NEARBY_RADIUS_METERS, MIN_NEARBY_RADIUS_METERS),
    MAX_NEARBY_RADIUS_METERS
  );
  const rawVibeTagFilter = cleanString(url.searchParams.get("vibe_tag") ?? url.searchParams.get("vibe_tag_id"));
  const vibeTagFilter = rawVibeTagFilter ? normalizeVibeTagID(rawVibeTagFilter) : null;

  if (latitude === null || longitude === null) {
    return json({ error: "lat and lng are required." }, { status: 400 });
  }

  if (rawVibeTagFilter !== null && vibeTagFilter === null) {
    return json({ error: "vibe_tag must be an active vibe tag id, slug, or display name." }, { status: 400 });
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return json({ error: "lat or lng is out of range." }, { status: 400 });
  }

  const latDelta = radius / 111_320;
  const lngDelta = radius / Math.max(111_320 * Math.cos((latitude * Math.PI) / 180), 1);

  const result = await env.DB.prepare(
    `SELECT p.id,
            p.provider,
            p.provider_place_id,
            p.name,
            p.latitude,
            p.longitude,
            p.street_address,
            p.category,
            p.city,
            p.region,
            p.country,
            p.created_at,
            p.updated_at,
            pvs.total_vibes AS stats_total_vibes,
            pvs.top_vibe_tag_id AS stats_top_vibe_tag_id,
            pvs.top_vibe_percent AS stats_top_vibe_percent,
            pvs.second_vibe_tag_id AS stats_second_vibe_tag_id,
            pvs.second_vibe_percent AS stats_second_vibe_percent,
            pvs.last_30_day_total_vibes AS stats_last_30_day_total_vibes,
            pvs.last_30_day_top_vibe_tag_id AS stats_last_30_day_top_vibe_tag_id,
            pvs.last_30_day_top_vibe_percent AS stats_last_30_day_top_vibe_percent,
            pvs.last_year_total_vibes AS stats_last_year_total_vibes,
            pvs.last_year_top_vibe_tag_id AS stats_last_year_top_vibe_tag_id,
            pvs.last_year_top_vibe_percent AS stats_last_year_top_vibe_percent,
            pvs.updated_at AS stats_updated_at
     FROM places p
     JOIN place_vibe_stats pvs ON pvs.place_id = p.id
     WHERE p.latitude BETWEEN ? AND ?
       AND p.longitude BETWEEN ? AND ?
       AND pvs.total_vibes > 0
       AND (
         ? IS NULL OR EXISTS (
           SELECT 1
             FROM vibe_events ve
             WHERE ve.place_id = p.id
             AND ve.moderation_status = 'active'
             AND ve.is_deleted = 0
             AND (ve.primary_vibe_tag_id = ? OR ve.secondary_vibe_tag_id = ? OR ve.third_vibe_tag_id = ?)
         )
       )
     ORDER BY ((p.latitude - ?) * (p.latitude - ?)) + ((p.longitude - ?) * (p.longitude - ?)) ASC,
              pvs.total_vibes DESC
     LIMIT ${MAX_NEARBY_QUERY_ROWS}`
  )
    .bind(
      latitude - latDelta,
      latitude + latDelta,
      longitude - lngDelta,
      longitude + lngDelta,
      vibeTagFilter,
      vibeTagFilter,
      vibeTagFilter,
      vibeTagFilter,
      latitude,
      latitude,
      longitude,
      longitude
    )
    .all<NearbyPlaceRow>();

  const entries = (result.results ?? [])
    .map((row) => ({
      row,
      distance: distanceMeters(latitude, longitude, row.latitude, row.longitude),
    }))
    .filter((entry) => entry.distance <= radius)
    .sort((a, b) => a.distance - b.distance)
    .slice(0, MAX_NEARBY_RESPONSE_PLACES);

  const deviceIDHash = await deviceHashFromRequest(request);
  const eventByPlaceID = deviceIDHash
    ? await fetchVibeEventsForDeviceByPlaceIDs(
        env,
        entries.map((entry) => entry.row.id),
        deviceIDHash
      )
    : new Map<string, VibeEventRow>();
  const places = entries.map((entry) => serializeNearbyPlace(entry.row, entry.distance, eventByPlaceID.get(entry.row.id) ?? null));

  return json({ places }, deviceIDHash ? undefined : { headers: publicCacheHeaders(CACHE_TTL_SECONDS.nearby) });
}

async function getPlaceMapCells(url: URL, env: Env): Promise<Response> {
  const latitude = numberParam(url, "lat");
  const longitude = numberParam(url, "lng");
  const radius = Math.min(
    Math.max(numberParam(url, "radius") ?? DEFAULT_NEARBY_RADIUS_METERS, MIN_NEARBY_RADIUS_METERS),
    MAX_NEARBY_RADIUS_METERS
  );
  const cellSize = Math.min(
    Math.max(numberParam(url, "cell_size") ?? recommendedMapCellSize(radius), MIN_MAP_CELL_SIZE_METERS),
    MAX_MAP_CELL_SIZE_METERS
  );
  const rawVibeTagFilter = cleanString(url.searchParams.get("vibe_tag") ?? url.searchParams.get("vibe_tag_id"));
  const vibeTagFilter = rawVibeTagFilter ? normalizeVibeTagID(rawVibeTagFilter) : null;

  if (latitude === null || longitude === null) {
    return json({ error: "lat and lng are required." }, { status: 400 });
  }

  if (rawVibeTagFilter !== null && vibeTagFilter === null) {
    return json({ error: "vibe_tag must be an active vibe tag id, slug, or display name." }, { status: 400 });
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return json({ error: "lat or lng is out of range." }, { status: 400 });
  }

  const latDelta = radius / 111_320;
  const lngDelta = radius / Math.max(111_320 * Math.cos((latitude * Math.PI) / 180), 1);
  const result = await env.DB.prepare(
    `SELECT p.id,
            p.latitude,
            p.longitude,
            pvs.total_vibes AS stats_total_vibes,
            pvs.top_vibe_tag_id AS stats_top_vibe_tag_id,
            pvs.top_vibe_percent AS stats_top_vibe_percent,
            pvs.second_vibe_tag_id AS stats_second_vibe_tag_id,
            pvs.second_vibe_percent AS stats_second_vibe_percent
     FROM places p
     JOIN place_vibe_stats pvs ON pvs.place_id = p.id
     WHERE p.latitude BETWEEN ? AND ?
       AND p.longitude BETWEEN ? AND ?
       AND pvs.total_vibes > 0
       AND (
         ? IS NULL OR EXISTS (
           SELECT 1
             FROM vibe_events ve
             WHERE ve.place_id = p.id
             AND ve.moderation_status = 'active'
             AND ve.is_deleted = 0
             AND (ve.primary_vibe_tag_id = ? OR ve.secondary_vibe_tag_id = ? OR ve.third_vibe_tag_id = ?)
         )
       )
     ORDER BY pvs.total_vibes DESC
     LIMIT ${MAX_MAP_CELL_QUERY_ROWS}`
  )
    .bind(
      latitude - latDelta,
      latitude + latDelta,
      longitude - lngDelta,
      longitude + lngDelta,
      vibeTagFilter,
      vibeTagFilter,
      vibeTagFilter,
      vibeTagFilter
    )
    .all<MapCellPlaceRow>();

  const cells = aggregateMapCells(
    (result.results ?? []).filter((row) => distanceMeters(latitude, longitude, row.latitude, row.longitude) <= radius),
    cellSize
  ).slice(0, MAX_MAP_CELL_RESPONSE_CELLS);

  return json(
    {
      cells,
      meta: {
        radius_meters: radius,
        cell_size_meters: cellSize,
        source_place_count: result.results?.length ?? 0,
      },
    },
    { headers: publicCacheHeaders(CACHE_TTL_SECONDS.mapCells) }
  );
}

async function getPlace(id: string, request: Request, env: Env): Promise<Response> {
  const place = await fetchPlaceByID(env, id);
  if (!place) {
    return json({ error: "Place not found." }, { status: 404 });
  }

  const deviceIDHash = await deviceHashFromRequest(request);
  return json({ place: await serializePlace(place, undefined, env, deviceIDHash) });
}

async function upsertPlace(request: Request, env: Env): Promise<Response> {
  const body = await readJson<PlaceInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const name = cleanString(body.value.name);
  const latitude = numberValue(body.value.latitude);
  const longitude = numberValue(body.value.longitude);

  if (!name) {
    return json({ error: "name is required." }, { status: 400 });
  }

  if (latitude === null || longitude === null) {
    return json({ error: "latitude and longitude are required." }, { status: 400 });
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return json({ error: "latitude or longitude is out of range." }, { status: 400 });
  }

  const provider = cleanString(body.value.provider) ?? "mapkit";
  const providerPlaceID = cleanString(body.value.provider_place_id ?? body.value.providerPlaceId);
  const streetAddress = cleanString(body.value.street_address ?? body.value.streetAddress);
  const category = cleanString(body.value.category);
  const city = cleanString(body.value.city);
  const region = cleanString(body.value.region);
  const country = cleanString(body.value.country);
  const now = new Date().toISOString();
  const existingPlace = await findExistingPlaceForInput(env, provider, providerPlaceID, name, latitude, longitude);
  const id = existingPlace?.id ?? (await stablePlaceID(provider, providerPlaceID, name, latitude, longitude));

  await env.DB.prepare(
    `INSERT INTO places (
       id, provider, provider_place_id, name, latitude, longitude, street_address, city, region, country, category, created_at, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET
       provider = excluded.provider,
       provider_place_id = excluded.provider_place_id,
       name = excluded.name,
       latitude = excluded.latitude,
       longitude = excluded.longitude,
       street_address = COALESCE(excluded.street_address, places.street_address),
       city = COALESCE(excluded.city, places.city),
       region = COALESCE(excluded.region, places.region),
       country = COALESCE(excluded.country, places.country),
       category = COALESCE(excluded.category, places.category),
       updated_at = excluded.updated_at`
  )
    .bind(id, provider, providerPlaceID, name, latitude, longitude, streetAddress, city, region, country, category, now, now)
    .run();

  const place = await fetchPlaceByID(env, id);
  if (!place) {
    return json({ error: "Place could not be saved." }, { status: 500 });
  }

  return json({ place: await serializePlace(place, undefined, env) }, { status: 201 });
}

async function upsertVibe(request: Request, env: Env): Promise<Response> {
  const body = await readJson<VibeInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const placeID = cleanString(body.value.place_id ?? body.value.placeId);
  if (!placeID) {
    return json({ error: "place_id is required." }, { status: 400 });
  }

  const placeExists = await env.DB.prepare("SELECT id FROM places WHERE id = ?").bind(placeID).first<{ id: string }>();
  if (!placeExists) {
    return json({ error: "Place not found." }, { status: 404 });
  }

  const parsedTags = parseVibeTags(body.value);
  if (!parsedTags.ok) {
    return json({ error: parsedTags.error }, { status: 400 });
  }

  const primaryTagID = parsedTags.tagIDs[0];
  const secondaryTagID = parsedTags.tagIDs[1] ?? null;
  const thirdTagID = parsedTags.tagIDs[2] ?? null;
  if (secondaryTagID !== null && secondaryTagID === primaryTagID) {
    return json({ error: "primary and secondary vibes must be different." }, { status: 400 });
  }

  const deviceIDHash = await deviceHashFromBody(body.value);
  const explicitAnonymousUserID = cleanString(body.value.anonymous_user_id ?? body.value.anonymousUserId);
  if (!deviceIDHash && !explicitAnonymousUserID) {
    return json({ error: "device_id_hash or anonymous_user_id is required." }, { status: 400 });
  }

  const now = new Date().toISOString();
  const anonymousUserID = explicitAnonymousUserID ?? anonymousUserIDForDeviceHash(deviceIDHash ?? "");
  if (deviceIDHash) {
    await upsertAnonymousUser(env, anonymousUserID, deviceIDHash, now);
  }

  const candidateAnonymousUserIDs = deviceIDHash && !explicitAnonymousUserID
    ? await anonymousUserIDsForPrimary(env, anonymousUserID)
    : [anonymousUserID];
  const existing = await fetchVibeEventForUsers(env, placeID, candidateAnonymousUserIDs);
  const eventAnonymousUserID = existing?.anonymous_user_id ?? anonymousUserID;

  const previousTotal = await env.DB.prepare("SELECT total_vibes FROM place_vibe_stats WHERE place_id = ?")
    .bind(placeID)
    .first<{ total_vibes: number }>();
  const wasFirstVibe = !existing && (previousTotal?.total_vibes ?? 0) === 0;
  const eventID = existing?.id ?? crypto.randomUUID();
  const source = cleanString(body.value.source) ?? sourceFromRequest(request);
  const appVersion = cleanString(body.value.app_version ?? body.value.appVersion) ?? cleanString(request.headers.get("X-Vibe-App-Version"));

  await env.DB.prepare(
    `INSERT INTO vibe_events (
       id, place_id, anonymous_user_id, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id, source, app_version,
       created_at, updated_at, is_flagged, is_deleted, moderation_status
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 'active')
     ON CONFLICT(place_id, anonymous_user_id) DO UPDATE SET
       primary_vibe_tag_id = excluded.primary_vibe_tag_id,
       secondary_vibe_tag_id = excluded.secondary_vibe_tag_id,
       third_vibe_tag_id = excluded.third_vibe_tag_id,
       source = excluded.source,
       app_version = excluded.app_version,
       updated_at = excluded.updated_at,
       is_deleted = 0,
       moderation_status = 'active'`
  )
    .bind(eventID, placeID, eventAnonymousUserID, primaryTagID, secondaryTagID, thirdTagID, source, appVersion, existing?.created_at ?? now, now)
    .run();

  await refreshPlaceVibeStats(env, placeID, now);
  await mirrorLegacyRating(env, eventID, placeID, deviceIDHash, primaryTagID, secondaryTagID, thirdTagID, existing?.created_at ?? now, now);

  if (wasFirstVibe) {
    await env.DB.prepare(
      `INSERT OR IGNORE INTO discovery_events (id, place_id, rating_id, event_type, created_at)
       VALUES (?, ?, ?, ?, ?)`
    )
      .bind(crypto.randomUUID(), placeID, eventID, "first_to_vibe", now)
      .run();
  }

  const place = await fetchPlaceByID(env, placeID);
  const event = await fetchVibeEventForUser(env, placeID, eventAnonymousUserID);

  if (!place || !event) {
    return json({ error: "Vibe could not be saved." }, { status: 500 });
  }

  return json({
    place: await serializePlace(place, undefined, env, deviceIDHash),
    vibe_event: serializeVibeEvent(event),
    rating: serializeLegacyRating(event),
    discovery: {
      was_first_vibe: wasFirstVibe,
    },
  });
}

async function reportPlace(request: Request, env: Env, routePlaceID?: string): Promise<Response> {
  const body = await readOptionalJson<ReportInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const placeID = routePlaceID ?? cleanString(body.value.place_id ?? body.value.placeId);
  if (!placeID) {
    return json({ error: "place_id is required." }, { status: 400 });
  }

  const place = await env.DB.prepare("SELECT id FROM places WHERE id = ?").bind(placeID).first<{ id: string }>();
  if (!place) {
    return json({ error: "Place not found." }, { status: 404 });
  }

  const reason = normalizeReportReason(cleanString(body.value.reason)) ?? "other";
  const now = new Date().toISOString();
  const deviceHash = await deviceHashFromBody(body.value);
  const explicitAnonymousUserID = cleanString(body.value.anonymous_user_id ?? body.value.anonymousUserId);
  const anonymousUserID = explicitAnonymousUserID ?? (deviceHash ? anonymousUserIDForDeviceHash(deviceHash) : null);
  if (anonymousUserID && deviceHash) {
    await upsertAnonymousUser(env, anonymousUserID, deviceHash, now);
  }

  const reportID = crypto.randomUUID();
  const status: ReportStatus = "open";
  await env.DB.prepare(
    `INSERT INTO reports (id, place_id, anonymous_user_id, reason, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(reportID, placeID, anonymousUserID, reason, status, now, now)
    .run();

  return json(
    {
      report: {
        id: reportID,
        place_id: placeID,
        anonymous_user_id: anonymousUserID,
        reason,
        status,
        created_at: now,
        updated_at: now,
      },
      status: "accepted",
    },
    { status: 202 }
  );
}

async function fetchPlaceByID(env: Env, id: string): Promise<PlaceRow | null> {
  return env.DB.prepare(
    `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, city, region, country, created_at, updated_at
     FROM places
     WHERE id = ?`
  )
    .bind(id)
    .first<PlaceRow>();
}

async function findExistingPlaceForInput(
  env: Env,
  provider: string,
  providerPlaceID: string | null,
  name: string,
  latitude: number,
  longitude: number
): Promise<PlaceRow | null> {
  if (providerPlaceID) {
    const exactProviderMatch = await env.DB.prepare(
      `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, city, region, country, created_at, updated_at
       FROM places
       WHERE provider = ? AND provider_place_id = ?
       LIMIT 1`
    )
      .bind(provider, providerPlaceID)
      .first<PlaceRow>();

    if (exactProviderMatch) {
      return exactProviderMatch;
    }
  }

  const matchRadiusMeters = 35;
  const latDelta = matchRadiusMeters / 111_320;
  const lngDelta = matchRadiusMeters / Math.max(111_320 * Math.cos((latitude * Math.PI) / 180), 1);
  const normalizedName = normalizePlaceName(name);
  const candidates = await env.DB.prepare(
    `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, city, region, country, created_at, updated_at
     FROM places
     WHERE latitude BETWEEN ? AND ?
       AND longitude BETWEEN ? AND ?
     LIMIT 20`
  )
    .bind(latitude - latDelta, latitude + latDelta, longitude - lngDelta, longitude + lngDelta)
    .all<PlaceRow>();

  const nearestNameMatch = (candidates.results ?? [])
    .map((row) => ({
      row,
      distance: distanceMeters(latitude, longitude, row.latitude, row.longitude),
    }))
    .filter((entry) => entry.distance <= matchRadiusMeters && normalizePlaceName(entry.row.name) === normalizedName)
    .sort((a, b) => a.distance - b.distance)[0];

  return nearestNameMatch?.row ?? null;
}

async function serializePlace(
  row: PlaceRow,
  distanceMetersValue: number | undefined,
  env: Env,
  deviceIDHash?: string | null
) {
  const stats = await fetchPlaceVibeStats(env, row.id);
  const topVibes = stats && stats.total_vibes > 0 ? await fetchTopVibes(env, row.id, stats.total_vibes, 3) : [];
  const myEvent = deviceIDHash ? await fetchVibeEventForDevice(env, row.id, deviceIDHash) : null;
  const recentPositivePercentage =
    stats && stats.last_30_day_total_vibes > 0 ? await fetchRecentPositivePercentage(env, row.id, stats.last_30_day_total_vibes, 30) : 0;

  return {
    id: row.id,
    provider: row.provider,
    provider_place_id: row.provider_place_id,
    name: row.name,
    latitude: row.latitude,
    longitude: row.longitude,
    street_address: row.street_address,
    category: row.category,
    city: row.city,
    region: row.region,
    country: row.country,
    created_at: row.created_at,
    updated_at: row.updated_at,
    stats:
      stats === null
        ? null
        : {
            rating_count: stats.total_vibes,
            total_vibes: stats.total_vibes,
            average_score: averageScoreForStats(topVibes),
            top_vibe_tag: stats.top_vibe_tag_id ? legacyDisplayNameForTag(stats.top_vibe_tag_id) : null,
            top_vibe_tag_id: stats.top_vibe_tag_id,
            top_vibe_percent: stats.top_vibe_percent,
            second_vibe_tag_id: stats.second_vibe_tag_id,
            second_vibe_percent: stats.second_vibe_percent,
            last_30_day_total_vibes: stats.last_30_day_total_vibes,
            last_30_day_top_vibe_tag_id: stats.last_30_day_top_vibe_tag_id,
            last_30_day_top_vibe_percent: stats.last_30_day_top_vibe_percent,
            last_year_total_vibes: stats.last_year_total_vibes,
            last_year_top_vibe_tag_id: stats.last_year_top_vibe_tag_id,
            last_year_top_vibe_percent: stats.last_year_top_vibe_percent,
            top_vibes: topVibes,
            recent_vibe_count: stats.last_30_day_total_vibes,
            recent_positive_percentage: recentPositivePercentage,
            updated_at: stats.updated_at,
          },
    my_rating: myEvent ? serializeLegacyRating(myEvent) : null,
    my_vibe_event: myEvent ? serializeVibeEvent(myEvent) : null,
    distance_meters: distanceMetersValue,
  };
}

function serializeNearbyPlace(row: NearbyPlaceRow, distanceMetersValue: number | undefined, myEvent: VibeEventRow | null) {
  const topVibes = topVibesFromNearbyStats(row);
  const recentPositivePercentage =
    row.stats_last_30_day_total_vibes > 0 && row.stats_last_30_day_top_vibe_tag_id && POSITIVE_TAG_IDS.has(row.stats_last_30_day_top_vibe_tag_id)
      ? Math.round(row.stats_last_30_day_top_vibe_percent ?? 0)
      : 0;

  return {
    id: row.id,
    provider: row.provider,
    provider_place_id: row.provider_place_id,
    name: row.name,
    latitude: row.latitude,
    longitude: row.longitude,
    street_address: row.street_address,
    category: row.category,
    city: row.city,
    region: row.region,
    country: row.country,
    created_at: row.created_at,
    updated_at: row.updated_at,
    stats: {
      rating_count: row.stats_total_vibes,
      total_vibes: row.stats_total_vibes,
      average_score: averageScoreForStats(topVibes),
      top_vibe_tag: row.stats_top_vibe_tag_id ? legacyDisplayNameForTag(row.stats_top_vibe_tag_id) : null,
      top_vibe_tag_id: row.stats_top_vibe_tag_id,
      top_vibe_percent: row.stats_top_vibe_percent,
      second_vibe_tag_id: row.stats_second_vibe_tag_id,
      second_vibe_percent: row.stats_second_vibe_percent,
      last_30_day_total_vibes: row.stats_last_30_day_total_vibes,
      last_30_day_top_vibe_tag_id: row.stats_last_30_day_top_vibe_tag_id,
      last_30_day_top_vibe_percent: row.stats_last_30_day_top_vibe_percent,
      last_year_total_vibes: row.stats_last_year_total_vibes,
      last_year_top_vibe_tag_id: row.stats_last_year_top_vibe_tag_id,
      last_year_top_vibe_percent: row.stats_last_year_top_vibe_percent,
      top_vibes: topVibes,
      recent_vibe_count: row.stats_last_30_day_total_vibes,
      recent_positive_percentage: recentPositivePercentage,
      updated_at: row.stats_updated_at,
    },
    my_rating: myEvent ? serializeLegacyRating(myEvent) : null,
    my_vibe_event: myEvent ? serializeVibeEvent(myEvent) : null,
    distance_meters: distanceMetersValue,
  };
}

function aggregateMapCells(rows: MapCellPlaceRow[], cellSizeMeters: number) {
  type MapCellAccumulator = {
    id: string;
    x: number;
    y: number;
    latitudeSum: number;
    longitudeSum: number;
    count: number;
    totalVibes: number;
    tagCounts: Map<VibeTagID, number>;
  };

  const cells = new Map<string, MapCellAccumulator>();

  for (const row of rows) {
    const keyPoint = mapCellPoint(row.latitude, row.longitude, cellSizeMeters);
    const id = `cell:${cellSizeMeters}:${keyPoint.x}:${keyPoint.y}`;
    const cell =
      cells.get(id) ??
      {
        id,
        x: keyPoint.x,
        y: keyPoint.y,
        latitudeSum: 0,
        longitudeSum: 0,
        count: 0,
        totalVibes: 0,
        tagCounts: new Map<VibeTagID, number>(),
      };

    cell.latitudeSum += row.latitude;
    cell.longitudeSum += row.longitude;
    cell.count += 1;
    cell.totalVibes += row.stats_total_vibes;
    addMapCellTagCount(cell.tagCounts, row.stats_top_vibe_tag_id, row.stats_top_vibe_percent, row.stats_total_vibes);
    addMapCellTagCount(cell.tagCounts, row.stats_second_vibe_tag_id, row.stats_second_vibe_percent, row.stats_total_vibes);
    cells.set(id, cell);
  }

  return Array.from(cells.values())
    .map((cell) => {
      const topTag = dominantMapCellTag(cell.tagCounts);
      const topTagCount = topTag ? cell.tagCounts.get(topTag) ?? 0 : 0;
      return {
        id: cell.id,
        latitude: cell.latitudeSum / Math.max(cell.count, 1),
        longitude: cell.longitudeSum / Math.max(cell.count, 1),
        count: cell.count,
        total_vibes: cell.totalVibes,
        top_vibe_tag: topTag ? legacyDisplayNameForTag(topTag) : null,
        top_vibe_tag_id: topTag,
        top_vibe_percent: topTag ? Math.round((topTagCount / Math.max(cell.totalVibes, 1)) * 100) : null,
        cell_size_meters: cellSizeMeters,
      };
    })
    .sort((a, b) => {
      if (a.count === b.count) {
        if (a.total_vibes === b.total_vibes) {
          return a.id.localeCompare(b.id);
        }
        return b.total_vibes - a.total_vibes;
      }
      return b.count - a.count;
    });
}

function addMapCellTagCount(
  counts: Map<VibeTagID, number>,
  tagID: VibeTagID | null,
  percentage: number | null,
  totalVibes: number
): void {
  if (!tagID || percentage === null || percentage <= 0 || totalVibes <= 0) {
    return;
  }

  counts.set(tagID, (counts.get(tagID) ?? 0) + Math.max(1, Math.round((totalVibes * percentage) / 100)));
}

function dominantMapCellTag(counts: Map<VibeTagID, number>): VibeTagID | null {
  return (
    Array.from(counts.entries()).sort((lhs, rhs) => {
      if (lhs[1] === rhs[1]) {
        return (TAG_BY_ID.get(rhs[0])?.sort_order ?? 0) - (TAG_BY_ID.get(lhs[0])?.sort_order ?? 0);
      }
      return rhs[1] - lhs[1];
    })[0]?.[0] ?? null
  );
}

function mapCellPoint(latitude: number, longitude: number, cellSizeMeters: number): { x: number; y: number } {
  const earthRadiusMeters = 6_378_137;
  const clampedLatitude = Math.min(Math.max(latitude, -85.05112878), 85.05112878);
  const xMeters = (longitude * Math.PI * earthRadiusMeters) / 180;
  const yMeters =
    Math.log(Math.tan(Math.PI / 4 + (clampedLatitude * Math.PI) / 360)) * earthRadiusMeters;
  return {
    x: Math.floor(xMeters / cellSizeMeters),
    y: Math.floor(yMeters / cellSizeMeters),
  };
}

function recommendedMapCellSize(radiusMeters: number): number {
  return Math.min(Math.max(Math.round(radiusMeters / 10_000) * 1_000, MIN_MAP_CELL_SIZE_METERS), MAX_MAP_CELL_SIZE_METERS);
}

function topVibesFromNearbyStats(row: NearbyPlaceRow) {
  const topVibes: Array<{
    vibe_tag: string;
    vibe_tag_id: VibeTagID;
    slug: string;
    display_name: string;
    emoji: string | null;
    sentiment_group: SentimentGroup;
    count: number;
    percentage: number;
  }> = [];

  addNearbyTopVibe(topVibes, row.stats_top_vibe_tag_id, row.stats_top_vibe_percent, row.stats_total_vibes);
  addNearbyTopVibe(topVibes, row.stats_second_vibe_tag_id, row.stats_second_vibe_percent, row.stats_total_vibes);
  return topVibes;
}

function addNearbyTopVibe(
  output: Array<{
    vibe_tag: string;
    vibe_tag_id: VibeTagID;
    slug: string;
    display_name: string;
    emoji: string | null;
    sentiment_group: SentimentGroup;
    count: number;
    percentage: number;
  }>,
  tagID: VibeTagID | null,
  percentage: number | null,
  totalVibes: number
): void {
  if (!tagID || percentage === null || percentage <= 0) {
    return;
  }

  const tag = TAG_BY_ID.get(tagID);
  output.push({
    vibe_tag: legacyDisplayNameForTag(tagID),
    vibe_tag_id: tagID,
    slug: tag?.slug ?? tagID,
    display_name: tag?.display_name ?? tagID,
    emoji: tag?.emoji ?? null,
    sentiment_group: tag?.sentiment_group ?? "neutral",
    count: Math.max(1, Math.round((totalVibes * percentage) / 100)),
    percentage: Math.round(percentage),
  });
}

async function fetchPlaceVibeStats(env: Env, placeID: string): Promise<PlaceStatsRow | null> {
  return env.DB.prepare("SELECT * FROM place_vibe_stats WHERE place_id = ?").bind(placeID).first<PlaceStatsRow>();
}

async function fetchVibeEventForDevice(env: Env, placeID: string, deviceIDHash: string): Promise<VibeEventRow | null> {
  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  const anonymousUserIDs = await anonymousUserIDsForPrimary(env, anonymousUserID);
  return fetchVibeEventForUsers(env, placeID, anonymousUserIDs);
}

async function fetchVibeEventsForDeviceByPlaceIDs(
  env: Env,
  placeIDs: string[],
  deviceIDHash: string
): Promise<Map<string, VibeEventRow>> {
  const uniquePlaceIDs = [...new Set(placeIDs)].slice(0, MAX_NEARBY_RESPONSE_PLACES);
  if (uniquePlaceIDs.length === 0) {
    return new Map();
  }

  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  const anonymousUserIDs = await anonymousUserIDsForPrimary(env, anonymousUserID);
  if (anonymousUserIDs.length === 0) {
    return new Map();
  }

  const userPlaceholders = anonymousUserIDs.map(() => "?").join(", ");
  const placeholders = uniquePlaceIDs.map(() => "?").join(", ");
  const result = await env.DB.prepare(
    `SELECT *
     FROM vibe_events
     WHERE anonymous_user_id IN (${userPlaceholders})
       AND is_deleted = 0
       AND place_id IN (${placeholders})`
  )
    .bind(...anonymousUserIDs, ...uniquePlaceIDs)
    .all<VibeEventRow>();

  const priority = new Map(anonymousUserIDs.map((id, index) => [id, index]));
  const rows = [...(result.results ?? [])].sort(
    (left, right) => (priority.get(left.anonymous_user_id) ?? 999) - (priority.get(right.anonymous_user_id) ?? 999)
  );
  const eventByPlaceID = new Map<string, VibeEventRow>();
  for (const row of rows) {
    if (!eventByPlaceID.has(row.place_id)) {
      eventByPlaceID.set(row.place_id, row);
    }
  }
  return eventByPlaceID;
}

async function fetchVibeEventForUsers(env: Env, placeID: string, anonymousUserIDs: string[]): Promise<VibeEventRow | null> {
  const uniqueAnonymousUserIDs = [...new Set(anonymousUserIDs)].filter(Boolean);
  if (uniqueAnonymousUserIDs.length === 0) {
    return null;
  }

  const placeholders = uniqueAnonymousUserIDs.map(() => "?").join(", ");
  const result = await env.DB.prepare(
    `SELECT *
     FROM vibe_events
     WHERE place_id = ? AND anonymous_user_id IN (${placeholders}) AND is_deleted = 0`
  )
    .bind(placeID, ...uniqueAnonymousUserIDs)
    .all<VibeEventRow>();

  const priority = new Map(uniqueAnonymousUserIDs.map((id, index) => [id, index]));
  return [...(result.results ?? [])].sort(
    (left, right) => (priority.get(left.anonymous_user_id) ?? 999) - (priority.get(right.anonymous_user_id) ?? 999)
  )[0] ?? null;
}

async function fetchVibeEventForUser(env: Env, placeID: string, anonymousUserID: string): Promise<VibeEventRow | null> {
  return env.DB.prepare(
    `SELECT *
     FROM vibe_events
     WHERE place_id = ? AND anonymous_user_id = ? AND is_deleted = 0
     LIMIT 1`
  )
    .bind(placeID, anonymousUserID)
    .first<VibeEventRow>();
}

async function fetchTopVibes(env: Env, placeID: string, totalVibes: number, limit: number) {
  const rows = await fetchTagCounts(env, placeID, undefined, limit);
  return rows.map((row) => ({
    vibe_tag: legacyDisplayNameForTag(row.vibe_tag_id),
    vibe_tag_id: row.vibe_tag_id,
    slug: TAG_BY_ID.get(row.vibe_tag_id)?.slug ?? row.vibe_tag_id,
    display_name: TAG_BY_ID.get(row.vibe_tag_id)?.display_name ?? row.vibe_tag_id,
    emoji: TAG_BY_ID.get(row.vibe_tag_id)?.emoji ?? null,
    sentiment_group: TAG_BY_ID.get(row.vibe_tag_id)?.sentiment_group ?? "neutral",
    count: row.tag_count,
    percentage: Math.round((row.tag_count / Math.max(totalVibes, 1)) * 100),
  }));
}

async function fetchRecentPositivePercentage(env: Env, placeID: string, denominator: number, days: number): Promise<number> {
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  const result = await env.DB.prepare(
    `SELECT COUNT(*) AS total_vibes
     FROM (
       SELECT primary_vibe_tag_id AS vibe_tag_id
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND created_at >= ?
       UNION ALL
       SELECT secondary_vibe_tag_id AS vibe_tag_id
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND created_at >= ? AND secondary_vibe_tag_id IS NOT NULL
       UNION ALL
       SELECT third_vibe_tag_id AS vibe_tag_id
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND created_at >= ? AND third_vibe_tag_id IS NOT NULL
     )
     WHERE vibe_tag_id IN (${Array.from(POSITIVE_TAG_IDS)
       .map(() => "?")
       .join(", ")})`
  )
    .bind(placeID, since, placeID, since, placeID, since, ...Array.from(POSITIVE_TAG_IDS))
    .first<EventTotalRow>();

  return Math.round(((result?.total_vibes ?? 0) / Math.max(denominator, 1)) * 100);
}

async function refreshPlaceVibeStats(env: Env, placeID: string, updatedAt: string): Promise<void> {
  const allTimeTotal = await fetchEventTotal(env, placeID);
  if (allTimeTotal === 0) {
    await env.DB.prepare(
      `INSERT INTO place_vibe_stats (place_id, total_vibes, updated_at)
       VALUES (?, 0, ?)
       ON CONFLICT(place_id) DO UPDATE SET
         total_vibes = 0,
         top_vibe_tag_id = NULL,
         top_vibe_percent = NULL,
         second_vibe_tag_id = NULL,
         second_vibe_percent = NULL,
         last_30_day_total_vibes = 0,
         last_30_day_top_vibe_tag_id = NULL,
         last_30_day_top_vibe_percent = NULL,
         last_year_total_vibes = 0,
         last_year_top_vibe_tag_id = NULL,
         last_year_top_vibe_percent = NULL,
         updated_at = excluded.updated_at`
    )
      .bind(placeID, updatedAt)
      .run();
    return;
  }

  const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const sinceYear = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString();
  const last30Total = await fetchEventTotal(env, placeID, since30);
  const lastYearTotal = await fetchEventTotal(env, placeID, sinceYear);
  const allTimeTop = await fetchTagCounts(env, placeID, undefined, 2);
  const last30Top = await fetchTagCounts(env, placeID, since30, 1);
  const lastYearTop = await fetchTagCounts(env, placeID, sinceYear, 1);
  const top = allTimeTop[0] ?? null;
  const second = allTimeTop[1] ?? null;
  const top30 = last30Top[0] ?? null;
  const topYear = lastYearTop[0] ?? null;

  await env.DB.prepare(
    `INSERT INTO place_vibe_stats (
       place_id,
       total_vibes,
       top_vibe_tag_id,
       top_vibe_percent,
       second_vibe_tag_id,
       second_vibe_percent,
       last_30_day_total_vibes,
       last_30_day_top_vibe_tag_id,
       last_30_day_top_vibe_percent,
       last_year_total_vibes,
       last_year_top_vibe_tag_id,
       last_year_top_vibe_percent,
       updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(place_id) DO UPDATE SET
       total_vibes = excluded.total_vibes,
       top_vibe_tag_id = excluded.top_vibe_tag_id,
       top_vibe_percent = excluded.top_vibe_percent,
       second_vibe_tag_id = excluded.second_vibe_tag_id,
       second_vibe_percent = excluded.second_vibe_percent,
       last_30_day_total_vibes = excluded.last_30_day_total_vibes,
       last_30_day_top_vibe_tag_id = excluded.last_30_day_top_vibe_tag_id,
       last_30_day_top_vibe_percent = excluded.last_30_day_top_vibe_percent,
       last_year_total_vibes = excluded.last_year_total_vibes,
       last_year_top_vibe_tag_id = excluded.last_year_top_vibe_tag_id,
       last_year_top_vibe_percent = excluded.last_year_top_vibe_percent,
       updated_at = excluded.updated_at`
  )
    .bind(
      placeID,
      allTimeTotal,
      top?.vibe_tag_id ?? null,
      top ? percent(top.tag_count, allTimeTotal) : null,
      second?.vibe_tag_id ?? null,
      second ? percent(second.tag_count, allTimeTotal) : null,
      last30Total,
      top30?.vibe_tag_id ?? null,
      top30 ? percent(top30.tag_count, last30Total) : null,
      lastYearTotal,
      topYear?.vibe_tag_id ?? null,
      topYear ? percent(topYear.tag_count, lastYearTotal) : null,
      updatedAt
    )
    .run();
}

async function fetchEventTotal(env: Env, placeID: string, since?: string): Promise<number> {
  const result = await env.DB.prepare(
    `SELECT COUNT(*) AS total_vibes
     FROM vibe_events
     WHERE place_id = ?
       AND ${ACTIVE_EVENT_WHERE}
       AND (? IS NULL OR created_at >= ?)`
  )
    .bind(placeID, since ?? null, since ?? null)
    .first<EventTotalRow>();

  return result?.total_vibes ?? 0;
}

async function fetchTagCounts(env: Env, placeID: string, since: string | undefined, limit: number): Promise<TagCountRow[]> {
  const result = await env.DB.prepare(
    `SELECT vibe_tag_id, SUM(tag_count) AS tag_count
     FROM (
       SELECT primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND (? IS NULL OR created_at >= ?)
       GROUP BY primary_vibe_tag_id
       UNION ALL
       SELECT secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND secondary_vibe_tag_id IS NOT NULL AND (? IS NULL OR created_at >= ?)
       GROUP BY secondary_vibe_tag_id
       UNION ALL
       SELECT third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND third_vibe_tag_id IS NOT NULL AND (? IS NULL OR created_at >= ?)
       GROUP BY third_vibe_tag_id
     )
     GROUP BY vibe_tag_id
     ORDER BY tag_count DESC, vibe_tag_id ASC
     LIMIT ?`
  )
    .bind(
      placeID,
      since ?? null,
      since ?? null,
      placeID,
      since ?? null,
      since ?? null,
      placeID,
      since ?? null,
      since ?? null,
      limit
    )
    .all<TagCountRow>();

  return (result.results ?? []).filter((row): row is TagCountRow => Boolean(TAG_BY_ID.get(row.vibe_tag_id)));
}

async function mirrorLegacyRating(
  env: Env,
  id: string,
  placeID: string,
  deviceIDHash: string | null,
  primaryTagID: VibeTagID,
  secondaryTagID: VibeTagID | null,
  thirdTagID: VibeTagID | null,
  createdAt: string,
  updatedAt: string
): Promise<void> {
  if (!deviceIDHash) {
    return;
  }

  const primaryName = legacyDisplayNameForTag(primaryTagID);
  const secondaryName = secondaryTagID ? legacyDisplayNameForTag(secondaryTagID) : null;
  const scores = [
    scoreForTag(primaryTagID),
    secondaryTagID ? scoreForTag(secondaryTagID) : null,
    thirdTagID ? scoreForTag(thirdTagID) : null,
  ].filter((score): score is number => score !== null);
  const score = scores.reduce((total, value) => total + value, 0) / Math.max(scores.length, 1);
  await env.DB.prepare(
    `INSERT INTO ratings (id, place_id, device_id_hash, score, vibe_tag, vibe_tag_secondary, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(place_id, device_id_hash) DO UPDATE SET
       score = excluded.score,
       vibe_tag = excluded.vibe_tag,
       vibe_tag_secondary = excluded.vibe_tag_secondary,
       updated_at = excluded.updated_at`
  )
    .bind(id, placeID, deviceIDHash, score, primaryName, secondaryName, createdAt, updatedAt)
    .run();
}

function serializeVibeEvent(row: VibeEventRow) {
  return {
    id: row.id,
    place_id: row.place_id,
    anonymous_user_id: row.anonymous_user_id,
    primary_vibe_tag_id: row.primary_vibe_tag_id,
    secondary_vibe_tag_id: row.secondary_vibe_tag_id,
    third_vibe_tag_id: row.third_vibe_tag_id,
    vibe_tag_ids: [row.primary_vibe_tag_id, row.secondary_vibe_tag_id, row.third_vibe_tag_id].filter((tag): tag is VibeTagID =>
      Boolean(tag)
    ),
    source: row.source,
    app_version: row.app_version,
    created_at: row.created_at,
    updated_at: row.updated_at,
    moderation_status: row.moderation_status,
  };
}

function serializeLegacyRating(row: VibeEventRow) {
  const primaryName = legacyDisplayNameForTag(row.primary_vibe_tag_id);
  const secondaryName = row.secondary_vibe_tag_id ? legacyDisplayNameForTag(row.secondary_vibe_tag_id) : null;
  const thirdName = row.third_vibe_tag_id ? legacyDisplayNameForTag(row.third_vibe_tag_id) : null;
  const vibeTags = [primaryName, secondaryName, thirdName].filter((tag): tag is string => Boolean(tag));
  const scoreTotal = [
    scoreForTag(row.primary_vibe_tag_id),
    row.secondary_vibe_tag_id ? scoreForTag(row.secondary_vibe_tag_id) : null,
    row.third_vibe_tag_id ? scoreForTag(row.third_vibe_tag_id) : null,
  ].filter((score): score is number => score !== null);

  return {
    id: row.id,
    place_id: row.place_id,
    score: scoreTotal.reduce((total, score) => total + score, 0) / Math.max(scoreTotal.length, 1),
    vibe_tag: primaryName,
    vibe_tags: [...new Set(vibeTags)],
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

async function fetchActiveVibeTags(env: Env) {
  const result = await env.DB.prepare(
    `SELECT id, slug, display_name, emoji, sentiment_group, sort_order, is_active
     FROM vibe_tags
     WHERE is_active = 1
     ORDER BY sort_order ASC`
  ).all<VibeTagRow>();

  return (result.results ?? []).map((tag) => ({
    id: tag.id,
    slug: tag.slug,
    display_name: tag.display_name,
    emoji: tag.emoji,
    sentiment_group: tag.sentiment_group,
    sort_order: tag.sort_order,
    is_active: Boolean(tag.is_active),
  }));
}

async function upsertAnonymousUser(env: Env, anonymousUserID: string, deviceIDHash: string, now: string): Promise<void> {
  await env.DB.prepare(
    `INSERT INTO anonymous_users (id, device_id_hash, first_seen_at, last_seen_at, created_at)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(device_id_hash) DO UPDATE SET
       last_seen_at = excluded.last_seen_at`
  )
    .bind(anonymousUserID, deviceIDHash, now, now, now)
    .run();
}

async function anonymousUserIDsForPrimary(env: Env, anonymousUserID: string): Promise<string[]> {
  const result = await env.DB.prepare(
    `SELECT alias_anonymous_user_id
     FROM anonymous_user_aliases
     WHERE primary_anonymous_user_id = ?`
  )
    .bind(anonymousUserID)
    .all<AnonymousUserAliasRow>();

  return [anonymousUserID, ...(result.results ?? []).map((row) => row.alias_anonymous_user_id)].filter(Boolean);
}

async function stablePlaceID(
  provider: string,
  providerPlaceID: string | null,
  name: string,
  latitude: number,
  longitude: number
): Promise<string> {
  const source = [
    provider.toLowerCase(),
    providerPlaceID ?? "",
    name.trim().toLowerCase(),
    latitude.toFixed(5),
    longitude.toFixed(5),
  ].join("|");
  return `place_${(await sha256Hex(source)).slice(0, 32)}`;
}

async function deviceHashFromRequest(request: Request): Promise<string | null> {
  const headerValue = cleanString(request.headers.get("X-Vibe-Device-ID-Hash"));
  if (!headerValue) {
    return null;
  }
  return normalizeDeviceHash(headerValue);
}

async function deviceHashFromBody(input: VibeInput | ReportInput): Promise<string | null> {
  const raw =
    cleanString(input.device_id_hash ?? input.deviceIdHash) ??
    cleanString(input.device_id ?? input.deviceId);
  if (!raw) {
    return null;
  }
  return normalizeDeviceHash(raw);
}

async function normalizeDeviceHash(value: string): Promise<string> {
  const trimmed = value.trim().toLowerCase();
  if (/^[a-f0-9]{64}$/.test(trimmed)) {
    return trimmed;
  }
  return sha256Hex(`vibes-yall-device:${trimmed}`);
}

function anonymousUserIDForDeviceHash(deviceIDHash: string): string {
  return `anon_${deviceIDHash.slice(0, 32)}`;
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function parseVibeTags(input: VibeInput): { ok: true; tagIDs: VibeTagID[] } | { ok: false; error: string } {
  const directPrimary =
    input.primary_vibe_tag_id ??
    input.primaryVibeTagId ??
    input.primary_vibe_tag_slug ??
    input.primaryVibeTagSlug ??
    input.primary_vibe_tag ??
    input.primaryVibeTag ??
    input.vibe_tag ??
    input.vibeTag;
  const directSecondary =
    input.secondary_vibe_tag_id ??
    input.secondaryVibeTagId ??
    input.secondary_vibe_tag_slug ??
    input.secondaryVibeTagSlug ??
    input.secondary_vibe_tag ??
    input.secondaryVibeTag ??
    input.vibe_tag_secondary ??
    input.vibeTagSecondary;
  const directThird =
    input.third_vibe_tag_id ??
    input.thirdVibeTagId ??
    input.third_vibe_tag_slug ??
    input.thirdVibeTagSlug ??
    input.third_vibe_tag ??
    input.thirdVibeTag ??
    input.vibe_tag_third ??
    input.vibeTagThird;
  const rawTags = Array.isArray(input.vibe_tags)
    ? input.vibe_tags
    : Array.isArray(input.vibeTags)
      ? input.vibeTags
      : [directPrimary, directSecondary, directThird].filter((tag) => tag !== undefined && tag !== null);

  const tagIDs: VibeTagID[] = [];
  for (const rawTag of rawTags) {
    const tagID = normalizeVibeTagID(cleanString(rawTag));
    if (!tagID) {
      return { ok: false, error: "vibe tags must be active tag ids, slugs, or display names." };
    }
    if (!tagIDs.includes(tagID)) {
      tagIDs.push(tagID);
    }
  }

  if (tagIDs.length < 1) {
    return { ok: false, error: "Pick at least one vibe." };
  }

  if (tagIDs.length > 3) {
    return { ok: false, error: "Pick no more than three vibes." };
  }

  return { ok: true, tagIDs };
}

function normalizeVibeTagID(value: string | null): VibeTagID | null {
  if (value === null) {
    return null;
  }

  const normalized = value
    .trim()
    .toLowerCase()
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");

  switch (normalized) {
    case "changed_my_life":
    case "changed_life":
    case "inspiring":
      return "changed_my_life";
    case "fire":
    case "great":
    case "elite":
    case "unreasonably_good":
    case "surprisingly_solid":
      return "fire";
    case "worth_the_drive":
    case "worth_the_drive_":
      return "worth_the_drive";
    case "iconic":
    case "america":
    case "certified":
      return "iconic";
    case "hidden_gem":
      return "hidden_gem";
    case "underrated":
      return "underrated";
    case "mid":
      return "mid";
    case "chaos":
      return "chaos";
    case "overrated":
      return "overrated";
    case "tourist_trap":
      return "tourist_trap";
    case "needs_prayer":
      return "needs_prayer";
    case "emotionally_damaging":
    case "emotionally_damaging_":
    case "never_again":
    case "cringe":
    case "unamerican":
    case "un_american":
      return "emotionally_damaging";
    default:
      return null;
  }
}

function legacyDisplayNameForTag(tagID: VibeTagID): string {
  switch (tagID) {
    case "changed_my_life":
      return "Changed my Life";
    case "fire":
      return "Fire";
    case "worth_the_drive":
      return "Worth the Drive";
    case "iconic":
      return "Iconic";
    case "hidden_gem":
      return "Hidden Gem";
    case "underrated":
      return "Underrated";
    case "mid":
      return "Mid";
    case "chaos":
      return "Chaos";
    case "overrated":
      return "Overrated";
    case "tourist_trap":
      return "Tourist Trap";
    case "needs_prayer":
      return "Needs Prayer";
    case "emotionally_damaging":
      return "Emotionally Damaging";
  }
}

function scoreForTag(tagID: VibeTagID): number {
  switch (tagID) {
    case "changed_my_life":
      return 10;
    case "fire":
      return 9;
    case "worth_the_drive":
      return 8;
    case "iconic":
      return 7;
    case "hidden_gem":
      return 6.5;
    case "underrated":
      return 6;
    case "mid":
      return 5;
    case "chaos":
      return 4;
    case "overrated":
      return 3;
    case "tourist_trap":
      return 2;
    case "needs_prayer":
      return 1;
    case "emotionally_damaging":
      return 0;
  }
}

function averageScoreForStats(topVibes: Array<{ vibe_tag_id: VibeTagID; count: number }>): number {
  const totalCount = topVibes.reduce((sum, row) => sum + row.count, 0);
  if (totalCount === 0) {
    return 0;
  }
  const totalScore = topVibes.reduce((sum, row) => sum + scoreForTag(row.vibe_tag_id) * row.count, 0);
  return Math.round((totalScore / totalCount) * 10) / 10;
}

function percent(count: number, denominator: number): number {
  return Math.round((count / Math.max(denominator, 1)) * 1000) / 10;
}

function normalizeReportReason(value: string | null): ReportReason | null {
  if (!value) {
    return null;
  }
  return REPORT_REASONS.includes(value as ReportReason) ? (value as ReportReason) : null;
}

function sourceFromRequest(request: Request): string {
  const explicitSource = cleanString(request.headers.get("X-Vibe-Source"));
  if (explicitSource) {
    return explicitSource;
  }

  const userAgent = request.headers.get("User-Agent")?.toLowerCase() ?? "";
  if (userAgent.includes("cfnetwork") || userAgent.includes("darwin")) {
    return "ios";
  }
  return "api";
}

function numberParam(url: URL, name: string): number | null {
  return numberValue(url.searchParams.get(name));
}

function numberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function cleanString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizePlaceName(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function distanceMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const earthRadiusMeters = 6_371_000;
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  return 2 * earthRadiusMeters * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function readJson<T>(request: Request): Promise<{ ok: true; value: T } | { ok: false; error: string }> {
  try {
    return { ok: true, value: (await request.json()) as T };
  } catch {
    return { ok: false, error: "Request body must be valid JSON." };
  }
}

async function readOptionalJson<T>(request: Request): Promise<{ ok: true; value: Partial<T> } | { ok: false; error: string }> {
  const text = await request.text();
  if (text.trim() === "") {
    return { ok: true, value: {} };
  }

  try {
    return { ok: true, value: JSON.parse(text) as Partial<T> };
  } catch {
    return { ok: false, error: "Request body must be valid JSON." };
  }
}

function normalizedPath(pathname: string): string {
  return pathname.replace(/\/+$/, "") || "/";
}

function hasBetaAccess(request: Request, env: Env, path: string): boolean {
  if (!requiresBetaAccess(path)) {
    return true;
  }

  const runtimeEnv = env as RuntimeEnv;
  const configuredToken = cleanString(runtimeEnv.VIBE_BETA_ACCESS_TOKEN);
  if (!configuredToken) {
    return true;
  }

  if (cleanString(runtimeEnv.VIBE_BETA_GATE_MODE)?.toLowerCase() === "off") {
    return true;
  }

  const suppliedToken = cleanString(request.headers.get(BETA_ACCESS_HEADER));
  return timingSafeStringEqual(suppliedToken, configuredToken);
}

function requiresBetaAccess(path: string): boolean {
  if (
    path === "/" ||
    path === "/health" ||
    path === "/privacy" ||
    path === "/terms" ||
    path === "/support" ||
    path === "/account/confirm"
  ) {
    return false;
  }

  return true;
}

function timingSafeStringEqual(a: string | null, b: string | null): boolean {
  if (!a || !b) {
    return false;
  }

  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);
  const maxLength = Math.max(aBytes.length, bBytes.length);
  let diff = aBytes.length ^ bBytes.length;

  for (let index = 0; index < maxLength; index += 1) {
    diff |= (aBytes[index] ?? 0) ^ (bBytes[index] ?? 0);
  }

  return diff === 0;
}

function rateLimitDecision(request: Request): { allowed: boolean; key: string } {
  const key = request.headers.get("CF-Connecting-IP") ?? "local";
  return { allowed: true, key };
}

function corsHeaders(): Headers {
  const headers = new Headers();
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    `Content-Type, X-Vibe-Device-ID-Hash, X-Vibe-App-Version, X-Vibe-Source, ${BETA_ACCESS_HEADER}`
  );
  headers.set("X-RateLimit-Policy", "placeholder");
  return headers;
}

function hasDeviceIdentity(request: Request): boolean {
  return Boolean(cleanString(request.headers.get("X-Vibe-Device-ID-Hash")));
}

function publicCacheHeaders(seconds: number): Headers {
  const browserSeconds = Math.min(seconds, 300);
  const headers = new Headers();
  headers.set("Cache-Control", `public, max-age=${browserSeconds}, s-maxage=${seconds}, stale-while-revalidate=86400`);
  return headers;
}

async function cachedGET(
  request: Request,
  ctx: ExecutionContext,
  seconds: number,
  responseFactory: () => Response | Promise<Response>
): Promise<Response> {
  if (request.method !== "GET") {
    return responseFactory();
  }

  const cache = caches.default;
  const cacheURL = new URL(request.url);
  cacheURL.searchParams.set("__cache_version", CACHE_VERSION);
  const cacheKey = new Request(cacheURL.toString(), { method: "GET" });
  const cached = await cache.match(cacheKey);
  if (cached) {
    return cached;
  }

  const response = await responseFactory();
  if (!response.ok) {
    return response;
  }

  const headers = new Headers(response.headers);
  if (!headers.has("Cache-Control") || headers.get("Cache-Control") === "no-store") {
    const browserSeconds = Math.min(seconds, 300);
    headers.set("Cache-Control", `public, max-age=${browserSeconds}, s-maxage=${seconds}, stale-while-revalidate=86400`);
  }

  const cacheableResponse = new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
  ctx.waitUntil(cache.put(cacheKey, cacheableResponse.clone()));
  return cacheableResponse;
}

function json(data: unknown, init: ResponseInit = {}): Response {
  const headers = corsHeaders();
  const incomingHeaders = new Headers(init.headers);
  incomingHeaders.forEach((value, key) => headers.set(key, value));
  headers.set("Content-Type", "application/json; charset=utf-8");
  if (!headers.has("Cache-Control")) {
    headers.set("Cache-Control", "no-store");
  }
  return new Response(JSON.stringify(data), { ...init, headers });
}
