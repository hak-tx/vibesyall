import { LANDING_ASSETS } from "./landing-assets";
import { createRemoteJWKSet, jwtVerify } from "jose";

const DEFAULT_NEARBY_RADIUS_METERS = 5_000;
const MIN_NEARBY_RADIUS_METERS = 100;
const MAX_NEARBY_RADIUS_METERS = 2_500_000;
const MAX_NEARBY_QUERY_ROWS = 1_500;
const MAX_NEARBY_RESPONSE_PLACES = 320;
const MAX_MAP_CELL_QUERY_ROWS = 8_000;
const MAX_MAP_CELL_RESPONSE_CELLS = 260;
const MIN_MAP_CELL_SIZE_METERS = 10_000;
const MAX_MAP_CELL_SIZE_METERS = 300_000;
const MAX_PROVIDER_SEARCH_RESULTS = 8;
const GOOGLE_PLACES_TEXT_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";
const CACHE_VERSION = "2026-07-25-taxonomy-v3-low-key";
const LIVE_APP_STORE_URL = "https://apps.apple.com/us/app/vibes-yall/id6783989332?mt=8";
const CACHE_TTL_SECONDS = {
  marketing: 60,
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
  { id: "bougie", slug: "bougie", display_name: "Bougie", emoji: "👑", sentiment_group: "identity", sort_order: 70 },
  { id: "low_key", slug: "low_key", display_name: "Low-key", emoji: "🌿", sentiment_group: "identity", sort_order: 80 },
  { id: "mid", slug: "mid", display_name: "Mid", emoji: "😐", sentiment_group: "neutral", sort_order: 90 },
  { id: "chaos", slug: "chaos", display_name: "Chaos", emoji: "🌪", sentiment_group: "neutral", sort_order: 100 },
  { id: "overrated", slug: "overrated", display_name: "Overrated", emoji: "👎", sentiment_group: "negative", sort_order: 110 },
  {
    id: "tourist_trap",
    slug: "tourist_trap",
    display_name: "Tourist Trap",
    emoji: "📸",
    sentiment_group: "negative",
    sort_order: 120,
  },
  {
    id: "needs_prayer",
    slug: "needs_prayer",
    display_name: "Needs Prayer",
    emoji: "🙏",
    sentiment_group: "negative",
    sort_order: 130,
  },
  {
    id: "emotionally_damaging",
    slug: "emotionally_damaging",
    display_name: "Emotionally Damaging",
    emoji: "💀",
    sentiment_group: "negative",
    sort_order: 140,
  },
] as const;

const CLIENT_VIBES_V1 = [
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

const CLIENT_VIBES_CURRENT = [
  "Changed my Life",
  "Fire",
  "Worth the Drive",
  "Iconic",
  "Hidden Gem",
  "Underrated",
  "Bougie",
  "Low-key",
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
const CURRENT_TAXONOMY_VERSION_ID = "vibes_v3";
const PLACE_SNAPSHOT_VERSION = "place_snapshot_v1";
const ACCOUNT_SIGNUP_THRESHOLD_DEFAULT = 10;
const EMAIL_CONFIRMATION_TTL_MS = 24 * 60 * 60 * 1000;
const PROFILE_SESSION_TTL_MS = 365 * 24 * 60 * 60 * 1000;
const VIBES_MARKETING_HOST = "vibesyall.com";
const SUPPORT_EMAIL = "vibesyall@gmail.com";
const ACCOUNT_CONFIRMATION_FROM_EMAIL = "hello@vibesyall.com";
const BETA_ACCESS_HEADER = "X-Vibe-Beta-Token";
const TAXONOMY_VERSION_HEADER = "X-Vibe-Taxonomy-Version";
const ADMIN_HOST = "admin.vibesyall.com";
const ADMIN_ACCESS_JWT_HEADER = "cf-access-jwt-assertion";
const ADMIN_ACCESS_EMAIL_HEADER = "cf-access-authenticated-user-email";
const ANALYTICS_EVENT_NAMES = [
  "app_open",
  "search_performed",
  "place_selected",
  "rating_started",
  "vibe_submitted",
  "vibe_deleted",
  "account_signup_requested",
  "account_login_requested",
  "account_logout",
  "account_delete_requested",
] as const;
const MAX_ANALYTICS_PROPERTIES = 16;
const MAX_ANALYTICS_PROPERTY_KEY_LENGTH = 48;
const MAX_ANALYTICS_PROPERTY_VALUE_LENGTH = 160;
const ADMIN_DEVICE_LABEL_IDENTITY_TYPES = ["analytics_device", "anonymous_user"] as const;
const ADMIN_DEVICE_LABEL_CATEGORIES = ["internal", "reviewer", "external", "unknown"] as const;

type VibeTagID = (typeof VIBE_TAG_DEFINITIONS)[number]["id"];
type SentimentGroup = (typeof VIBE_TAG_DEFINITIONS)[number]["sentiment_group"];
type ReportReason = (typeof REPORT_REASONS)[number];
type ReportStatus = (typeof REPORT_STATUSES)[number];
type AdminDeviceLabelIdentityType = (typeof ADMIN_DEVICE_LABEL_IDENTITY_TYPES)[number];
type AdminDeviceLabelCategory = (typeof ADMIN_DEVICE_LABEL_CATEGORIES)[number];

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
  primary_category: string | null;
  provider_category: string | null;
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
  taxonomy_version_id: string | null;
  submission_context: string | null;
  place_snapshot_json: string | null;
  created_at: string;
  updated_at: string;
  is_flagged: number;
  is_deleted: number;
  moderation_status: string;
};

type TagCountRow = {
  vibe_tag_id: VibeTagID;
  tag_count: number;
  first_seen_at: string | null;
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
  primary_category?: unknown;
  primaryCategory?: unknown;
  provider_category?: unknown;
  providerCategory?: unknown;
  city?: unknown;
  region?: unknown;
  country?: unknown;
};

type ProviderPlaceCandidate = {
  provider: string;
  provider_place_id: string;
  name: string;
  latitude: number;
  longitude: number;
  street_address: string | null;
  category: string | null;
  primary_category: string | null;
  provider_category: string | null;
  city: string | null;
  region: string | null;
  country: string | null;
  distance_meters: number | null;
};

type GooglePlaceTextSearchRequest = {
  textQuery: string;
  maxResultCount: number;
  languageCode?: string;
  regionCode?: string;
  locationBias?: {
    circle: {
      center: {
        latitude: number;
        longitude: number;
      };
      radius: number;
    };
  };
};

type GooglePlaceTextSearchResponse = {
  places?: GooglePlace[];
};

type GooglePlace = {
  id?: string;
  displayName?: {
    text?: string;
  };
  formattedAddress?: string;
  location?: {
    latitude?: number;
    longitude?: number;
  };
  primaryType?: string;
  primaryTypeDisplayName?: {
    text?: string;
  };
  types?: string[];
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
  submission_context?: unknown;
  submissionContext?: unknown;
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

type AnalyticsEventName = (typeof ANALYTICS_EVENT_NAMES)[number];

type AnalyticsEventInput = DeviceIdentityInput & {
  event_name?: unknown;
  eventName?: unknown;
  platform?: unknown;
  app_version?: unknown;
  appVersion?: unknown;
  properties?: unknown;
};

type AdminAnalyticsOptions = {
  includeInternal: boolean;
  days?: AdminAnalyticsWindowDays;
};

type AdminAnalyticsWindowDays = 1 | 7 | 30;

type AdminDeviceLabelInput = {
  identity_type?: unknown;
  identityType?: unknown;
  identity_id?: unknown;
  identityId?: unknown;
  label?: unknown;
  category?: unknown;
  excluded_from_core_metrics?: unknown;
  excludedFromCoreMetrics?: unknown;
  notes?: unknown;
};

type AccountSignupInput = DeviceIdentityInput & {
  email?: unknown;
  redirect_url?: unknown;
  redirectUrl?: unknown;
};

type AccountRecoveryInput = {
  email?: unknown;
  redirect_url?: unknown;
  redirectUrl?: unknown;
};

type AccountDeletionInput = DeviceIdentityInput & {
  email?: unknown;
};

type AccountEmailSender = SendEmail;
type AccountEmailPurpose = "email_confirmation" | "login";

type RuntimeEnv = Env & {
  APP_BASE_URL?: string;
  APP_STORE_URL?: string;
  IOS_DEEP_LINK_SCHEME?: string;
  ACCOUNT_EMAIL_FROM?: string;
  ACCOUNT_SIGNUP_THRESHOLD?: string;
  ACCOUNT_AUTO_CONFIRM_IF_EMAIL_UNAVAILABLE?: string;
  APP_REVIEW_EMAIL?: string;
  APP_REVIEW_PASSWORD?: string;
  VIBE_BETA_ACCESS_TOKEN?: string;
  VIBE_BETA_GATE_MODE?: string;
  ADMIN_EMAILS?: string;
  CF_ACCESS_TEAM_DOMAIN?: string;
  CF_ACCESS_AUD?: string;
  ANALYTICS_SECRET?: string;
  GOOGLE_PLACES_API_KEY?: string;
  SIGNUP_EMAIL?: AccountEmailSender;
};

type AnalyticsRecord = {
  eventName: AnalyticsEventName;
  deviceIDHash: string;
  platform: string | null;
  appVersion: string | null;
  properties: Record<string, string>;
  createdAt?: string;
};

type AnalyticsCounters = {
  appOpen: number;
  search: number;
  placeSelect: number;
  vibeSubmit: number;
  accountEvent: number;
};

type AnalyticsDailyRow = {
  day: string;
  active_devices: number | null;
  new_devices: number | null;
  event_count: number | null;
  app_open_count: number | null;
  search_count: number | null;
  place_select_count: number | null;
  vibe_submit_count: number | null;
  account_event_count: number | null;
};

type AnalyticsHourlyRow = Omit<AnalyticsDailyRow, "day" | "new_devices"> & {
  bucket_index: number | null;
};

type AnalyticsHourlyNewDevicesRow = {
  bucket_index: number | null;
  new_devices: number | null;
};

type AnalyticsSummaryRow = {
  active_today: number | null;
  active_7d: number | null;
  active_30d: number | null;
  events_30d: number | null;
  app_opens_30d: number | null;
  searches_30d: number | null;
  place_selects_30d: number | null;
  vibes_30d: number | null;
  account_events_30d: number | null;
};

type AnalyticsNewDevicesRow = {
  new_devices_30d: number | null;
};

type AnalyticsContentTotalsRow = {
  total_vibes: number | null;
  total_vibed_places: number | null;
  total_anonymous_vibers: number | null;
  vibes_30d: number | null;
  vibes_previous_30d: number | null;
  anonymous_vibers_30d: number | null;
  anonymous_vibers_previous_30d: number | null;
  vibed_places_30d: number | null;
  vibed_places_previous_30d: number | null;
  first_vibe_at: string | null;
  last_vibe_at: string | null;
};

type AnalyticsPreviousPeriodRow = {
  active_devices: number | null;
  new_devices: number | null;
  app_opens: number | null;
  searches: number | null;
  place_selects: number | null;
};

type AnalyticsUsageDepthRow = {
  active_devices: number | null;
  one_day_devices: number | null;
  repeat_devices: number | null;
  loyal_devices: number | null;
  active_device_days: number | null;
};

type ViberDepthRow = {
  contributors: number | null;
  one_place_contributors: number | null;
  two_to_three_place_contributors: number | null;
  four_plus_place_contributors: number | null;
};

type VibeHistoryDailyRow = {
  day: string;
  vibe_submissions: number | null;
  unique_vibers: number | null;
  vibed_places: number | null;
};

type VibeHistoryHourlyRow = Omit<VibeHistoryDailyRow, "day"> & {
  bucket_index: number | null;
};

type AnalyticsRetentionRow = {
  cohort_devices: number | null;
  retained_devices: number | null;
};

type AnalyticsNameCountRow = {
  name: string | null;
  count: number | null;
};

type AdminDeviceLabelRow = {
  id: string;
  identity_type: AdminDeviceLabelIdentityType;
  identity_id: string;
  label: string;
  category: AdminDeviceLabelCategory;
  excluded_from_core_metrics: number;
  notes: string | null;
  created_at: string;
  updated_at: string;
  analytics_event_count: number | null;
  analytics_vibe_submit_count: number | null;
  historical_vibe_count: number | null;
  last_seen_at: string | null;
};

type AdminRecentDeviceRow = {
  identity_type: AdminDeviceLabelIdentityType;
  identity_id: string;
  label: string | null;
  category: AdminDeviceLabelCategory | null;
  excluded_from_core_metrics: number | null;
  event_count: number | null;
  vibe_submit_count: number | null;
  historical_vibe_count: number | null;
  first_seen_at: string | null;
  last_seen_at: string | null;
  app_version: string | null;
};

type AdminExcludedSummaryRow = {
  excluded_analytics_devices_30d: number | null;
  excluded_historical_vibers_30d: number | null;
  excluded_historical_vibes_30d: number | null;
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
  purpose: AccountEmailPurpose;
  redirect_url: string | null;
  expires_at: string;
  consumed_at: string | null;
  email: string;
  email_normalized: string;
  email_verified_at: string | null;
};

type ProfileSessionRow = ProfileRow & {
  session_id: string;
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
    if (isAdminRequest(url, path)) {
      return handleAdminRequest(request, url, path, env);
    }

    if (!hasBetaAccess(request, env, path)) {
      return json({ error: "Beta access required." }, { status: 403 });
    }

    const rateLimit = await rateLimitDecision(request, path, env);
    if (!rateLimit.allowed) {
      return json(
        { error: "Too many requests. Please try again shortly." },
        {
          status: 429,
          headers: {
            "Retry-After": "60",
            "X-RateLimit-Policy": rateLimit.policy,
          },
        }
      );
    }

    try {
      const isReadRequest = request.method === "GET" || request.method === "HEAD";

      if (isReadRequest && path === "/") {
        if (request.method === "HEAD") {
          return headResponse(landingPage(request, env));
        }
        return landingPage(request, env);
      }

      if (isReadRequest && path === "/privacy") {
        if (request.method === "HEAD") {
          return headResponse(privacyPage(request, env));
        }
        return privacyPage(request, env);
      }

      if (isReadRequest && path === "/terms") {
        if (request.method === "HEAD") {
          return headResponse(termsPage(request, env));
        }
        return termsPage(request, env);
      }

      if (isReadRequest && path === "/support") {
        if (request.method === "HEAD") {
          return headResponse(supportPage(request, env));
        }
        return supportPage(request, env);
      }

      if ((request.method === "GET" || request.method === "HEAD") && path === "/account/review-login") {
        const response = appReviewLoginPage(env);
        return request.method === "HEAD" ? headResponse(response) : response;
      }

      if (request.method === "POST" && path === "/account/review-login") {
        return appReviewLogin(request, env);
      }

      if (isReadRequest && path === "/health") {
        const response = json({ ok: true, service: "vibe-map-api", data_model: "human_labeled_place_sentiment_v1" });
        return request.method === "HEAD" ? headResponse(response) : response;
      }

      if (request.method === "GET" && path === "/vibes") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.vibeTaxonomy, () =>
          json(
            { vibes: requestSupportsCurrentTaxonomy(request) ? CLIENT_VIBES_CURRENT : CLIENT_VIBES_V1 },
            { headers: publicCacheHeaders(CACHE_TTL_SECONDS.vibeTaxonomy) }
          )
        );
      }

      if (request.method === "GET" && path === "/vibes/tags") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.vibeTaxonomy, () =>
          getVibeTags(env, requestSupportsCurrentTaxonomy(request))
        );
      }

      if (request.method === "GET" && path === "/account/eligibility") {
        return getAccountEligibility(request, env);
      }

      if (request.method === "GET" && path === "/account/status") {
        return getAccountEligibility(request, env);
      }

      if (request.method === "POST" && path === "/analytics/events") {
        return collectAnalyticsEvent(request, env, ctx);
      }

      if (request.method === "POST" && path === "/account/signup") {
        return requestAccountSignup(request, env);
      }

      if (request.method === "POST" && (path === "/account/recovery" || path === "/account/login")) {
        return requestAccountRecovery(request, env);
      }

      if (request.method === "POST" && path === "/account/logout") {
        return requestAccountLogout(request, env);
      }

      if (request.method === "POST" && path === "/account/delete") {
        return requestAccountDeletion(request, env);
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

      if (request.method === "GET" && path === "/places/search") {
        return searchSavedPlaces(request, url, env);
      }

      if (request.method === "GET" && path === "/places/map-cells") {
        return cachedGET(request, ctx, CACHE_TTL_SECONDS.mapCells, () => getPlaceMapCells(request, url, env));
      }

      if (request.method === "GET" && path === "/places/provider-search") {
        return searchProviderPlaces(url, env);
      }

      if (request.method === "POST" && path === "/places") {
        return upsertPlace(request, env);
      }

      if (request.method === "POST" && (path === "/vibes" || path === "/ratings")) {
        return upsertVibe(request, env, ctx);
      }

      const ratingDeleteMatch = path.match(/^\/(?:vibes|ratings)\/([^/]+)$/);
      if (request.method === "DELETE" && ratingDeleteMatch) {
        return deleteVibe(request, env, ctx, decodeURIComponent(ratingDeleteMatch[1]));
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
  async scheduled(_controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(drainAggregateRefreshJobs(env));
  },
} satisfies ExportedHandler<Env>;

async function handleAdminRequest(request: Request, url: URL, path: string, env: Env): Promise<Response> {
  const access = await verifyAdminAccess(request, env);
  if (!access.ok) {
    return access.response;
  }

  const adminPath = adminPathForRequest(url, path);
  const isReadRequest = request.method === "GET" || request.method === "HEAD";

  if (isReadRequest && (adminPath === "/admin" || adminPath === "/admin/")) {
    const response = adminDashboardPage(access.email);
    return request.method === "HEAD" ? headResponse(response) : response;
  }

  if (isReadRequest && adminPath === "/admin/analytics.json") {
    const response = json(await buildAdminAnalyticsPayload(env, adminAnalyticsOptions(url)), { headers: adminJSONHeaders() });
    return request.method === "HEAD" ? headResponse(response) : response;
  }

  if (request.method === "POST" && adminPath === "/admin/device-labels") {
    return upsertAdminDeviceLabel(request, env);
  }

  return adminMessagePage("Admin route not found.", 404);
}

function isAdminRequest(url: URL, path: string): boolean {
  return url.hostname.toLowerCase() === ADMIN_HOST || path === "/admin" || path.startsWith("/admin/");
}

function adminPathForRequest(url: URL, path: string): string {
  if (url.hostname.toLowerCase() !== ADMIN_HOST) {
    return path;
  }

  if (path === "/") {
    return "/admin";
  }

  if (path.startsWith("/admin/") || path === "/admin") {
    return path;
  }

  return `/admin${path}`;
}

async function verifyAdminAccess(
  request: Request,
  env: Env
): Promise<{ ok: true; email: string } | { ok: false; response: Response }> {
  const runtimeEnv = env as RuntimeEnv;
  const allowedEmails = allowedAdminEmails(runtimeEnv.ADMIN_EMAILS);
  const teamDomain = normalizedAccessTeamDomain(runtimeEnv.CF_ACCESS_TEAM_DOMAIN);
  const audience = cleanString(runtimeEnv.CF_ACCESS_AUD);

  if (allowedEmails.size === 0) {
    return { ok: false, response: adminMessagePage("Admin access is not configured.", 503) };
  }

  if (!teamDomain || !audience) {
    return {
      ok: false,
      response: adminMessagePage("Cloudflare Access JWT validation is not configured for this Worker.", 503),
    };
  }

  const token = cleanString(request.headers.get(ADMIN_ACCESS_JWT_HEADER));
  if (!token) {
    return { ok: false, response: adminMessagePage("Cloudflare Access sign-in is required.", 401) };
  }

  try {
    const jwks = createRemoteJWKSet(new URL(`${teamDomain}/cdn-cgi/access/certs`));
    const { payload } = await jwtVerify(token, jwks, {
      issuer: teamDomain,
      audience,
    });
    const payloadEmail = typeof payload.email === "string" ? normalizeEmail(payload.email) : null;
    const headerEmail = normalizeEmail(request.headers.get(ADMIN_ACCESS_EMAIL_HEADER));
    const email = payloadEmail ?? headerEmail;

    if (!email || !allowedEmails.has(email)) {
      return { ok: false, response: adminMessagePage("This Cloudflare account is not allowed here.", 403) };
    }

    return { ok: true, email };
  } catch (error) {
    console.log(JSON.stringify({ message: "Admin Access JWT rejected.", error: String(error) }));
    return { ok: false, response: adminMessagePage("Cloudflare Access could not verify this session.", 403) };
  }
}

function allowedAdminEmails(value: string | undefined): Set<string> {
  return new Set(
    (value ?? "")
      .split(",")
      .map((email) => normalizeEmail(email))
      .filter((email): email is string => Boolean(email))
  );
}

function normalizedAccessTeamDomain(value: string | undefined): string | null {
  const trimmed = cleanString(value);
  if (!trimmed) {
    return null;
  }

  const withProtocol = /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
  return withProtocol.replace(/\/+$/, "");
}

function adminMessagePage(message: string, status: number): Response {
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="robots" content="noindex,nofollow">
  <title>VIBES Y'ALL Admin</title>
  <style>${adminCSS()}</style>
</head>
<body>
  <main class="admin-shell narrow">
    <p class="eyebrow">VIBES Y'ALL Admin</p>
    <h1>${escapeHTML(message)}</h1>
  </main>
</body>
</html>`, { status, headers: adminHTMLHeaders() });
}

export function adminDashboardPage(email: string): Response {
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="robots" content="noindex,nofollow">
  <title>VIBES Y'ALL Analytics</title>
  <style>${adminCSS()}</style>
</head>
<body>
  <main class="admin-shell">
    <header class="admin-header">
      <div>
        <p class="eyebrow">VIBES Y'ALL Admin</p>
        <h1>App Activity</h1>
      </div>
      <p class="session">Signed in with Cloudflare Access as <strong>${escapeHTML(email)}</strong></p>
    </header>

    <section id="status" class="status">Loading analytics...</section>
    <section class="status controls">
      <label class="toggle-row">
        <input id="exclude-internal" type="checkbox" checked>
        <span>
          <strong>Exclude internal testers</strong>
          <small>Default public-growth view. Turn off to compare against all tracked traffic.</small>
        </span>
      </label>
      <div class="control-actions">
        <fieldset class="window-picker">
          <legend>Trend window</legend>
          <div role="group" aria-label="Trend window">
            <button type="button" data-days="1" aria-pressed="false">Last 24 hrs</button>
            <button type="button" data-days="7" aria-pressed="false">7 days</button>
            <button type="button" data-days="30" aria-pressed="true">30 days</button>
          </div>
        </fieldset>
        <span id="filter-mode" class="pill">Public trend view</span>
      </div>
    </section>
    <section id="summary" class="metric-grid"></section>
    <section class="panel insight-panel">
      <div class="panel-heading">
        <div>
          <p class="section-kicker">Plain-language readout</p>
          <h2>What stands out</h2>
        </div>
        <span>Signals worth watching now</span>
      </div>
      <div id="insights" class="insight-grid"></div>
    </section>
    <section class="panel">
      <div class="panel-heading">
        <div>
          <p class="section-kicker">Audience</p>
          <h2>New and returning devices</h2>
        </div>
        <span id="audience-window-copy">Daily anonymous devices, last 30 days</span>
      </div>
      <div id="audience-trend" class="trend"></div>
    </section>
    <section class="panel">
      <div class="panel-heading">
        <div>
          <p class="section-kicker">Contribution</p>
          <h2>Places getting vibed</h2>
        </div>
        <span id="vibe-window-copy">New place ratings and contributors, last 30 days</span>
      </div>
      <div id="vibe-trend" class="trend"></div>
    </section>
    <section class="two-column business-charts">
      <div class="panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Depth</p>
            <h2>One-and-done or engaged?</h2>
          </div>
          <span>Places vibed per contributor</span>
        </div>
        <div id="contribution-depth" class="distribution"></div>
      </div>
      <div class="panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Discovery</p>
            <h2>Searches and place taps</h2>
          </div>
          <span id="discovery-window-copy">Daily actions, last 30 days</span>
        </div>
        <div id="discovery-trend" class="trend compact-chart"></div>
      </div>
    </section>
    <section class="two-column">
      <div class="panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Release health</p>
            <h2>App versions in use</h2>
          </div>
          <span id="versions-window-copy">Active devices, last 30 days</span>
        </div>
        <div id="versions" class="list"></div>
      </div>
      <div class="panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Diagnostics</p>
            <h2>Tracked actions</h2>
          </div>
          <span id="events-window-copy">Last 30 days</span>
        </div>
        <div id="events" class="list"></div>
      </div>
    </section>
    <details class="admin-tools">
      <summary>Internal tester and device tools</summary>
      <div class="admin-tools-body">
        <section class="panel">
          <div class="panel-heading">
            <h2>Device Labels</h2>
            <span>Admin-only filters</span>
          </div>
          <form id="device-label-form" class="device-label-form">
            <select id="label-identity-type" aria-label="Identity type">
              <option value="analytics_device">Analytics device</option>
              <option value="anonymous_user">Vibe-history device</option>
            </select>
            <input id="label-identity-id" type="text" placeholder="Device id" autocomplete="off" required>
            <input id="label-name" type="text" placeholder="Label, e.g. Brian or Rich" autocomplete="off" required>
            <select id="label-category" aria-label="Category">
              <option value="internal">Internal</option>
              <option value="reviewer">Reviewer</option>
              <option value="external">External</option>
              <option value="unknown">Unknown</option>
            </select>
            <label class="compact-toggle">
              <input id="label-excluded" type="checkbox" checked>
              Exclude
            </label>
            <button type="submit">Save Label</button>
          </form>
          <div id="label-status" class="form-status"></div>
        </section>
        <section class="two-column">
          <div class="panel">
            <div class="panel-heading">
              <h2>Current Labels</h2>
              <span>Filtered when excluded</span>
            </div>
            <div id="device-labels" class="device-list"></div>
          </div>
          <div class="panel">
            <div class="panel-heading">
              <h2>Recent Unlabeled</h2>
              <span>Tap Tag to fill the form</span>
            </div>
            <div id="recent-devices" class="device-list"></div>
          </div>
        </section>
      </div>
    </details>
  </main>
  <script>
    const analyticsBasePath = location.hostname === "${ADMIN_HOST}" ? "/analytics.json" : "/admin/analytics.json";
    const labelPath = location.hostname === "${ADMIN_HOST}" ? "/device-labels" : "/admin/device-labels";
    const numberFormat = new Intl.NumberFormat();
    const centralDateFormat = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/Chicago",
      month: "short",
      day: "numeric",
      year: "numeric"
    });
    const centralDateTimeFormat = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/Chicago",
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
      timeZoneName: "short"
    });
    const centralHourFormat = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/Chicago",
      hour: "numeric"
    });
    const centralHourTooltipFormat = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/Chicago",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    });
    const requestedDays = Number(new URLSearchParams(location.search).get("days"));
    let currentPayload = null;
    let selectedDays = [1, 7, 30].includes(requestedDays) ? requestedDays : 30;

    function number(value) {
      return numberFormat.format(Number(value || 0));
    }

    function percent(value) {
      return Number.isFinite(value) ? value.toFixed(1) + "%" : "n/a";
    }

    function shortDate(value) {
      if (!value) return "n/a";
      return centralDateFormat.format(new Date(value));
    }

    function centralDateTime(value) {
      if (!value) return "n/a";
      return centralDateTimeFormat.format(new Date(value));
    }

    function escapeText(value) {
      return String(value ?? "").replace(/[&<>"']/g, (character) => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#039;"
      }[character]));
    }

    function shortID(value) {
      const text = String(value || "");
      return text.length > 24 ? text.slice(0, 18) + "..." + text.slice(-6) : text;
    }

    function analyticsPath() {
      const params = new URLSearchParams();
      params.set("days", String(selectedDays));
      if (!document.getElementById("exclude-internal").checked) {
        params.set("include_internal", "1");
      }
      const query = params.toString();
      return analyticsBasePath + (query ? "?" + query : "");
    }

    function percentRatio(numerator, denominator) {
      const top = Number(numerator || 0);
      const bottom = Number(denominator || 0);
      return bottom > 0 ? percent((top / bottom) * 100) : "n/a";
    }

    function cohortText(retained, cohort) {
      const retainedValue = Number(retained || 0);
      const cohortValue = Number(cohort || 0);
      return number(retainedValue) + " / " + number(cohortValue);
    }

    function changePercent(current, previous) {
      const currentValue = Number(current || 0);
      const previousValue = Number(previous || 0);
      if (previousValue <= 0) return null;
      return ((currentValue - previousValue) / previousValue) * 100;
    }

    function windowPhrase(days, capitalized) {
      const phrase = days === 1 ? "last 24 hours" : "last " + days + " days";
      return capitalized ? phrase.charAt(0).toUpperCase() + phrase.slice(1) : phrase;
    }

    function comparisonPhrase(days) {
      return days === 1 ? "previous 24 hours" : "prior " + days + " days";
    }

    function changeLabel(current, previous, days) {
      const change = changePercent(current, previous);
      if (change === null) return "No prior baseline";
      if (Math.abs(change) < 0.05) return "No change vs " + comparisonPhrase(days);
      return (change > 0 ? "Up " : "Down ") + Math.abs(change).toFixed(0) + "% vs " + comparisonPhrase(days);
    }

    function metricCard(title, value, detail, comparison, tone) {
      return '<article class="metric-card ' + escapeText(tone || "") + '">'
        + '<span>' + escapeText(title) + '</span>'
        + '<strong>' + escapeText(value) + '</strong>'
        + '<small>' + escapeText(detail) + '</small>'
        + '<em>' + escapeText(comparison) + '</em>'
        + '</article>';
    }

    function listRow(label, value, max) {
      const width = max > 0 ? Math.max(4, Math.round((Number(value || 0) / max) * 100)) : 0;
      return '<div class="list-row"><div><strong>' + label + '</strong><span>' + number(value) + '</span></div><i style="width:' + width + '%"></i></div>';
    }

    function chartScale(value) {
      const maximum = Math.max(1, Number(value || 0));
      const roughStep = maximum / 4;
      const magnitude = Math.pow(10, Math.floor(Math.log10(roughStep || 1)));
      const normalized = roughStep / magnitude;
      const step = Math.max(
        1,
        (normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10) * magnitude
      );
      const scaleMaximum = Math.max(step, Math.ceil(maximum / step) * step);
      const ticks = [];
      for (let tick = scaleMaximum; tick >= 0; tick -= step) {
        ticks.push(tick);
      }
      return { maximum: scaleMaximum, ticks };
    }

    function groupedColumnChart(rows, series, yAxisLabel, options) {
      const chartOptions = options || {};
      const values = rows.flatMap((row) => series.map((item) => Number(row[item.key] || 0)));
      const scale = chartScale(Math.max(...values, 1));
      const legend = '<div class="chart-legend">' + series.map((item) => (
        '<span><i class="' + escapeText(item.className) + '"></i>' + escapeText(item.label) + '</span>'
      )).join("") + '</div>';
      const yAxis = '<div class="y-axis" aria-hidden="true">'
        + '<strong>' + escapeText(yAxisLabel || "Count") + '</strong>'
        + '<div>' + scale.ticks.map((tick) => '<span>' + number(tick) + '</span>').join("") + '</div>'
        + '</div>';
      const grid = '<div class="chart-grid" aria-hidden="true">'
        + scale.ticks.map(() => '<i></i>').join("")
        + '</div>';
      const columns = '<div class="grouped-chart" style="--chart-columns:' + rows.length + ';">'
        + rows.map((row, rowIndex) => {
          const isHourly = Boolean(chartOptions.hourly && row.bucketStart);
          const label = isHourly ? centralHourFormat.format(new Date(row.bucketStart)) : row.day.slice(5);
          const labelStep = rows.length <= 7 ? 1 : Math.ceil(rows.length / 10);
          const showLabel = rowIndex === 0 || rowIndex === rows.length - 1 || rowIndex % labelStep === 0;
          const period = isHourly
            ? centralHourTooltipFormat.format(new Date(row.bucketStart)) + "–" + centralHourTooltipFormat.format(new Date(row.bucketEnd))
            : label;
          const title = period + ': ' + series.map((item) => number(row[item.key]) + ' ' + item.label.toLowerCase()).join(", ");
          return '<div class="grouped-day" tabindex="0" data-tooltip="' + escapeText(title) + '" aria-label="' + escapeText(title) + '">'
            + '<div class="bar-pair">' + series.map((item) => {
              const value = Number(row[item.key] || 0);
              const height = value > 0 ? Math.max(3, (value / scale.maximum) * 100) : 0;
              return '<span class="bar-column" style="--bar-height:' + height + '%">'
                + (value > 0 ? '<b>' + number(value) + '</b>' : '')
                + '<i class="' + escapeText(item.className) + '" style="height:' + height + '%"></i>'
                + '</span>';
            }).join("") + '</div>'
            + '<em' + (showLabel ? '' : ' aria-hidden="true" class="axis-label-hidden"') + '>'
            + (showLabel ? escapeText(label) : '') + '</em>'
            + '</div>';
        }).join("")
        + '</div>';
      return legend
        + '<div class="chart-shell">'
        + yAxis
        + '<div class="chart-viewport"><div class="chart-plot" style="--chart-columns:' + rows.length + ';">'
        + grid + columns
        + '</div><div class="x-axis-title">' + escapeText(chartOptions.xAxisLabel || "Date") + '</div></div>'
        + '</div>';
    }

    function trendLineChart(rows, series, yAxisLabel, options) {
      const chartOptions = options || {};
      const isHourly = Boolean(chartOptions.hourly);
      const values = rows.flatMap((row) => series.map((item) => Number(row[item.key] || 0)));
      const scale = chartScale(Math.max(...values, 1));
      const legend = '<div class="chart-legend">' + series.map((item) => (
        '<span><i class="' + escapeText(item.className) + '"></i>' + escapeText(item.label) + '</span>'
      )).join("") + '</div>';
      const yAxis = '<div class="y-axis line-y-axis" aria-hidden="true">'
        + '<strong>' + escapeText(yAxisLabel || "Count") + '</strong>'
        + '<div>' + scale.ticks.map((tick) => '<span>' + number(tick) + '</span>').join("") + '</div>'
        + '</div>';
      const grid = '<div class="chart-grid line-chart-grid" aria-hidden="true">'
        + scale.ticks.map(() => '<i></i>').join("")
        + '</div>';
      const denominator = Math.max(1, rows.length - 1);
      const paths = series.map((item) => {
        const points = rows.map((row, index) => {
          const x = (index / denominator) * 1000;
          const y = 100 - (Number(row[item.key] || 0) / scale.maximum) * 100;
          return x.toFixed(2) + "," + y.toFixed(2);
        }).join(" ");
        return '<polyline class="line-series ' + escapeText(item.className) + '" points="' + points + '"></polyline>';
      }).join("");
      const points = rows.map((row, rowIndex) => {
        const period = isHourly
          ? centralHourTooltipFormat.format(new Date(row.bucketStart))
            + "–" + centralHourTooltipFormat.format(new Date(row.bucketEnd))
          : row.day;
        return series.map((item, seriesIndex) => {
          const value = Number(row[item.key] || 0);
          if (value <= 0) return "";
          const x = (rowIndex / denominator) * 100;
          const y = (value / scale.maximum) * 100;
          const title = period + ": " + number(value) + " " + item.label.toLowerCase();
          const offset = (seriesIndex - (series.length - 1) / 2) * 5;
          const edgeClass = rowIndex === 0 ? " edge-start" : rowIndex === rows.length - 1 ? " edge-end" : "";
          return '<button type="button" class="line-point ' + escapeText(item.className) + edgeClass + '"'
            + ' style="left:calc(' + x.toFixed(3) + '% + ' + offset.toFixed(1) + 'px);bottom:' + y.toFixed(3) + '%;"'
            + ' aria-label="' + escapeText(title) + '">'
            + '<span>' + escapeText(title) + '</span>'
            + '</button>';
        }).join("");
      }).join("");
      const tickCount = 7;
      const tickIndexes = Array.from({ length: Math.min(tickCount, rows.length) }, (_, index) => (
        Math.round((index / Math.max(1, Math.min(tickCount, rows.length) - 1)) * denominator)
      )).filter((value, index, all) => index === 0 || value !== all[index - 1]);
      const xTicks = '<div class="line-x-axis' + (isHourly || rows.length >= 7 ? ' sparse-axis' : '') + '" aria-hidden="true">'
        + tickIndexes.map((rowIndex, tickIndex) => {
          const position = (rowIndex / denominator) * 100;
          const alignment = tickIndex === 0 ? "start" : tickIndex === tickIndexes.length - 1 ? "end" : "middle";
          const label = isHourly
            ? centralHourFormat.format(new Date(rows[rowIndex].bucketStart))
            : rows[rowIndex].day.slice(5);
          return '<span class="' + alignment + '" style="left:' + position.toFixed(3) + '%">'
            + escapeText(label)
            + '</span>';
        }).join("")
        + '</div>';
      return legend
        + '<div class="chart-shell line-chart-shell">'
        + yAxis
        + '<div class="line-chart-region">'
        + '<div class="line-chart-frame">'
        + grid
        + '<svg class="line-chart" viewBox="0 0 1000 100" preserveAspectRatio="none" aria-hidden="true">'
        + paths
        + '</svg>'
        + points
        + '</div>'
        + xTicks
        + '<div class="x-axis-title">' + escapeText(isHourly ? "Hour (Central Time)" : "Date") + '</div>'
        + '</div></div>';
    }

    function insightCard(title, body, tone) {
      return '<article class="insight ' + escapeText(tone) + '"><strong>' + escapeText(title) + '</strong><p>' + escapeText(body) + '</p></article>';
    }

    function distributionRow(label, value, total, detail, tone) {
      const share = total > 0 ? Math.round((Number(value || 0) / total) * 100) : 0;
      return '<div class="distribution-row">'
        + '<div><strong>' + escapeText(label) + '</strong><span>' + number(value) + ' · ' + share + '%</span></div>'
        + '<i><b class="' + escapeText(tone) + '" style="width:' + share + '%"></b></i>'
        + '<small>' + escapeText(detail) + '</small>'
        + '</div>';
    }

    function deviceMeta(row) {
      const parts = [];
      if (row.eventCount) parts.push(number(row.eventCount) + " events");
      if (row.vibeSubmitCount) parts.push(number(row.vibeSubmitCount) + " tracked vibe submits");
      if (row.historicalVibeCount) parts.push(number(row.historicalVibeCount) + " saved vibes");
      if (row.appVersion) parts.push(row.appVersion);
      if (row.lastSeenAt) parts.push("last " + centralDateTime(row.lastSeenAt));
      return parts.length ? parts.join(" · ") : "No activity yet";
    }

    function labelDeviceRow(row) {
      const excluded = row.excludedFromCoreMetrics ? "Excluded" : "Included";
      return '<div class="device-row">'
        + '<div><strong>' + escapeText(row.label) + '</strong><span>' + escapeText(row.category) + ' · ' + excluded + '</span></div>'
        + '<code title="' + escapeText(row.identityId) + '">' + escapeText(shortID(row.identityId)) + '</code>'
        + '<small>' + escapeText(row.identityType.replace("_", " ")) + ' · ' + escapeText(deviceMeta(row)) + '</small>'
        + '</div>';
    }

    function recentDeviceRow(row, index) {
      return '<div class="device-row actionable">'
        + '<div><strong>' + escapeText(row.identityType.replace("_", " ")) + '</strong><span>' + escapeText(deviceMeta(row)) + '</span></div>'
        + '<code title="' + escapeText(row.identityId) + '">' + escapeText(shortID(row.identityId)) + '</code>'
        + '<button type="button" data-recent-index="' + index + '">Tag</button>'
        + '</div>';
    }

    function render(payload) {
      currentPayload = payload;
      selectedDays = Number(payload.filters.days || 30);
      document.querySelectorAll("[data-days]").forEach((button) => {
        button.setAttribute("aria-pressed", String(Number(button.dataset.days) === selectedDays));
        button.disabled = false;
      });
      const publicMode = !payload.filters.includeInternal;
      const period = windowPhrase(selectedDays, false);
      const periodTitle = windowPhrase(selectedDays, true);
      const chartGrain = selectedDays === 1 ? "Hourly" : "Daily";
      document.getElementById("filter-mode").textContent = publicMode ? "Public trend view" : "All tracked traffic";
      document.getElementById("status").textContent = "Updated " + centralDateTime(payload.generatedAt)
        + (publicMode ? " · internal testers excluded" : " · internal testers included");
      document.getElementById("audience-window-copy").textContent = chartGrain + " anonymous devices, " + period;
      document.getElementById("vibe-window-copy").textContent = "New place ratings and contributors, " + period;
      document.getElementById("discovery-window-copy").textContent = chartGrain + " actions, " + period;
      document.getElementById("versions-window-copy").textContent = "Active devices, " + period;
      document.getElementById("events-window-copy").textContent = periodTitle;
      const summary = payload.summary;
      const previousPlacesPerContributor = summary.previousAnonymousVibers30d > 0
        ? summary.previousVibes30d / summary.previousAnonymousVibers30d
        : 0;
      document.getElementById("summary").innerHTML = [
        metricCard(
          "Active devices",
          number(summary.active30d),
          "Used the app " + period,
          changeLabel(summary.active30d, summary.previousActive30d, selectedDays),
          "audience"
        ),
        metricCard(
          "New devices",
          number(summary.newDevices30d),
          "First seen " + period,
          changeLabel(summary.newDevices30d, summary.previousNewDevices30d, selectedDays),
          "growth"
        ),
        metricCard(
          "Repeat-use rate",
          selectedDays === 1 ? "n/a" : percent(summary.repeatDeviceRate30d),
          selectedDays === 1
            ? "Choose 7 or 30 days to measure return visits"
            : number(summary.repeatDevices30d) + " devices active on 2+ days",
          selectedDays === 1
            ? "A return visit requires more than one day"
            : summary.activeDaysPerDevice30d.toFixed(1) + " active days per device",
          selectedDays === 1 ? "audience" : summary.repeatDeviceRate30d >= 30 ? "good" : "watch"
        ),
        metricCard(
          "Places per contributor",
          summary.vibesPerDevice30d.toFixed(1),
          "Distinct place ratings per person who vibed",
          previousPlacesPerContributor > 0
            ? changeLabel(summary.vibesPerDevice30d, previousPlacesPerContributor, selectedDays)
            : "No prior baseline",
          "contribution"
        ),
        metricCard(
          "New place ratings",
          number(summary.vibeSubmissions30d),
          number(summary.anonymousVibers30d) + " contributing users",
          changeLabel(summary.vibeSubmissions30d, summary.previousVibes30d, selectedDays),
          "content"
        ),
        metricCard(
          "Place discovery",
          number(summary.placeSelections30d),
          number(summary.searches30d) + " searches · " + number(summary.appOpens30d) + " app opens",
          changeLabel(summary.placeSelections30d, summary.previousPlaceSelections30d, selectedDays),
          "discovery"
        )
      ].join("");

      const insights = [];
      if (summary.active30d < 10) {
        insights.push(insightCard(
          "Early signal",
          "Only " + number(summary.active30d) + " public devices are in the " + period + ", so percentages can swing quickly.",
          "neutral"
        ));
      }
      if (selectedDays === 1) {
        insights.push(insightCard(
          "Last 24 hours",
          number(summary.active30d) + " public devices used the app in the last 24 hours. Use 7 or 30 days to evaluate repeat use.",
          "neutral"
        ));
      } else if (summary.repeatDeviceRate30d >= 40) {
        insights.push(insightCard(
          "People are returning",
          percent(summary.repeatDeviceRate30d) + " of active devices used the app on at least two different days.",
          "positive"
        ));
      } else {
        insights.push(insightCard(
          "Watch repeat use",
          number(summary.oneDayDevices30d) + " of " + number(summary.active30d) + " active devices appeared on only one day.",
          "warning"
        ));
      }
      const onePlaceShare = summary.anonymousVibers30d > 0
        ? (summary.onePlaceContributors30d / summary.anonymousVibers30d) * 100
        : 0;
      if (onePlaceShare >= 60) {
        insights.push(insightCard(
          "Many contributors stop after one place",
          percent(onePlaceShare) + " of people who vibed a place added only one place rating in this window.",
          "warning"
        ));
      } else {
        insights.push(insightCard(
          "Contributors explore",
          number(summary.twoToThreePlaceContributors30d + summary.fourPlusPlaceContributors30d)
            + " people vibed at least two places.",
          "positive"
        ));
      }
      insights.push(insightCard(
        "Discovery activity",
        number(summary.searches30d) + " searches and " + number(summary.placeSelections30d)
          + " place taps were tracked. These are separate activity totals, not a conversion funnel.",
        "neutral"
      ));
      document.getElementById("insights").innerHTML = insights.join("");

      const audienceRows = payload.daily.map((row) => ({
        ...row,
        returningDevices: Math.max(0, Number(row.activeDevices || 0) - Number(row.newDevices || 0))
      }));
      const audienceSeries = [
        { key: "returningDevices", label: "Returning", className: "series-navy" },
        { key: "newDevices", label: "New", className: "series-yellow" }
      ];
      document.getElementById("audience-trend").innerHTML = trendLineChart(
        audienceRows,
        audienceSeries,
        "Devices",
        { hourly: selectedDays === 1 }
      );

      const vibeSeries = [
        { key: "vibeSubmissions", label: "Place ratings", className: "series-navy" },
        { key: "uniqueVibers", label: "Contributors", className: "series-yellow" }
      ];
      document.getElementById("vibe-trend").innerHTML = trendLineChart(
        payload.vibeHistoryDaily,
        vibeSeries,
        "Count",
        { hourly: selectedDays === 1 }
      );

      document.getElementById("contribution-depth").innerHTML = [
        distributionRow(
          "One place",
          summary.onePlaceContributors30d,
          summary.anonymousVibers30d,
          "Likely one-and-done contributors",
          "series-muted"
        ),
        distributionRow(
          "Two to three places",
          summary.twoToThreePlaceContributors30d,
          summary.anonymousVibers30d,
          "Showing meaningful exploration",
          "series-yellow"
        ),
        distributionRow(
          "Four or more places",
          summary.fourPlusPlaceContributors30d,
          summary.anonymousVibers30d,
          "Your most engaged contributors",
          "series-teal"
        )
      ].join("");

      const discoverySeries = [
        { key: "searchCount", label: "Searches", className: "series-navy" },
        { key: "placeSelectCount", label: "Place taps", className: "series-yellow" }
      ];
      document.getElementById("discovery-trend").innerHTML = trendLineChart(
        payload.daily,
        discoverySeries,
        "Actions",
        { hourly: selectedDays === 1 }
      );

      const maxEvents = Math.max(...payload.topEvents.map((row) => row.count), 1);
      document.getElementById("events").innerHTML = payload.topEvents.map((row) => listRow(
        row.name.replaceAll("_", " "),
        row.count,
        maxEvents
      )).join("") || '<p class="empty">No events yet.</p>';

      const maxVersions = Math.max(...payload.appVersions.map((row) => row.count), 1);
      document.getElementById("versions").innerHTML = payload.appVersions.map((row) => listRow(row.name || "Unknown", row.count, maxVersions)).join("") || '<p class="empty">No app versions yet.</p>';

      document.getElementById("device-labels").innerHTML = payload.deviceLabels.map(labelDeviceRow).join("") || '<p class="empty">No labeled devices yet.</p>';
      document.getElementById("recent-devices").innerHTML = payload.recentDevices.map(recentDeviceRow).join("") || '<p class="empty">No recent unlabeled devices.</p>';
    }

    function loadAnalytics() {
      document.getElementById("status").textContent = "Loading analytics...";
      document.querySelectorAll("[data-days]").forEach((button) => {
        button.disabled = true;
      });
      return fetch(analyticsPath(), { headers: { "Accept": "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error("Analytics request failed.");
        return response.json();
      })
      .then(render)
      .catch((error) => {
        document.getElementById("status").textContent = error.message;
        document.querySelectorAll("[data-days]").forEach((button) => {
          button.disabled = false;
        });
      });
    }

    document.getElementById("exclude-internal").addEventListener("change", loadAnalytics);
    document.querySelector(".window-picker").addEventListener("click", (event) => {
      const button = event.target.closest("button[data-days]");
      if (!button || button.disabled) return;
      selectedDays = Number(button.dataset.days);
      const dashboardURL = new URL(location.href);
      dashboardURL.searchParams.set("days", String(selectedDays));
      history.replaceState(null, "", dashboardURL);
      document.querySelectorAll("[data-days]").forEach((item) => {
        item.setAttribute("aria-pressed", String(item === button));
      });
      loadAnalytics();
    });
    document.getElementById("recent-devices").addEventListener("click", (event) => {
      const button = event.target.closest("button[data-recent-index]");
      if (!button || !currentPayload) return;
      const row = currentPayload.recentDevices[Number(button.dataset.recentIndex)];
      if (!row) return;
      document.getElementById("label-identity-type").value = row.identityType;
      document.getElementById("label-identity-id").value = row.identityId;
      document.getElementById("label-name").focus();
    });
    document.getElementById("device-label-form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const status = document.getElementById("label-status");
      status.textContent = "Saving label...";
      const payload = {
        identity_type: document.getElementById("label-identity-type").value,
        identity_id: document.getElementById("label-identity-id").value,
        label: document.getElementById("label-name").value,
        category: document.getElementById("label-category").value,
        excluded_from_core_metrics: document.getElementById("label-excluded").checked
      };
      try {
        const response = await fetch(labelPath, {
          method: "POST",
          headers: { "Accept": "application/json", "Content-Type": "application/json" },
          body: JSON.stringify(payload)
        });
        const result = await response.json().catch(() => ({}));
        if (!response.ok) {
          throw new Error(result.error || "Device label could not be saved.");
        }
        status.textContent = "Saved.";
        document.getElementById("device-label-form").reset();
        document.getElementById("label-excluded").checked = true;
        await loadAnalytics();
      } catch (error) {
        status.textContent = error.message;
      }
    });
    loadAnalytics();
  </script>
</body>
</html>`, { headers: adminHTMLHeaders() });
}

function adminCSS(): string {
  return `
    :root {
      --navy: #102c6b;
      --yellow: #dfd771;
      --ink: #071321;
      --muted: #657184;
      --line: rgba(16, 44, 107, 0.14);
      --surface: rgba(255, 255, 255, 0.82);
      color-scheme: light;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      background: #f7f5ef;
      color: var(--ink);
    }
    .admin-shell {
      width: min(100%, 72rem);
      margin: 0 auto;
      padding: clamp(1.5rem, 4vw, 3rem);
    }
    .admin-shell.narrow { width: min(100%, 42rem); }
    .admin-header {
      display: flex;
      align-items: flex-end;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: 1.2rem;
    }
    .eyebrow {
      color: var(--navy);
      font-size: 0.82rem;
      font-weight: 850;
      letter-spacing: 0.08em;
      margin: 0 0 0.35rem;
      text-transform: uppercase;
    }
    h1, h2 { margin: 0; letter-spacing: 0; }
    h1 { font-size: clamp(2.5rem, 7vw, 5rem); line-height: 0.92; }
    h2 { font-size: 1.2rem; }
    .session, .status, .panel-heading span, .health-card small, .health-card dt, .metric small, .list-row span, .empty {
      color: var(--muted);
      font-weight: 650;
    }
    .session { text-align: right; margin: 0 0 0.45rem; }
    .status {
      border: 1px solid var(--line);
      border-radius: 0.5rem;
      background: var(--surface);
      padding: 0.8rem 1rem;
      margin-bottom: 1rem;
    }
    .controls {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }
    .control-actions {
      display: flex;
      align-items: flex-end;
      justify-content: flex-end;
      gap: 0.75rem;
      flex-wrap: wrap;
    }
    .window-picker {
      display: grid;
      gap: 0.3rem;
      min-width: 16rem;
      margin: 0;
      padding: 0;
      border: 0;
    }
    .window-picker legend {
      color: var(--muted);
      font-size: 0.7rem;
      font-weight: 850;
      line-height: 1;
      padding: 0;
      text-transform: uppercase;
    }
    .window-picker div {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      overflow: hidden;
      border: 1px solid rgba(16, 44, 107, 0.22);
      border-radius: 0.45rem;
      background: rgba(255, 255, 255, 0.74);
    }
    .window-picker button {
      min-height: 2.35rem;
      border: 0;
      border-right: 1px solid rgba(16, 44, 107, 0.16);
      background: transparent;
      color: var(--navy);
      cursor: pointer;
      font: inherit;
      font-size: 0.78rem;
      font-weight: 850;
      padding: 0.45rem 0.65rem;
    }
    .window-picker button:last-child { border-right: 0; }
    .window-picker button[aria-pressed="true"] {
      background: var(--navy);
      color: white;
    }
    .window-picker button:focus-visible {
      position: relative;
      z-index: 1;
      outline: 0.16rem solid #198b82;
      outline-offset: -0.16rem;
    }
    .window-picker button:disabled {
      cursor: wait;
      opacity: 0.72;
    }
    .toggle-row, .compact-toggle {
      display: flex;
      align-items: center;
      gap: 0.65rem;
      color: var(--ink);
      font-weight: 800;
    }
    .toggle-row small {
      display: block;
      color: var(--muted);
      font-size: 0.82rem;
      font-weight: 650;
      margin-top: 0.15rem;
    }
    .toggle-row input, .compact-toggle input {
      width: 1.1rem;
      height: 1.1rem;
      accent-color: var(--navy);
      flex: 0 0 auto;
    }
    .pill {
      border: 1px solid var(--line);
      border-radius: 999px;
      background: rgba(223, 215, 113, 0.28);
      color: var(--navy);
      font-size: 0.82rem;
      font-weight: 850;
      padding: 0.4rem 0.7rem;
      white-space: nowrap;
    }
    .health-grid, .metric-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 0.85rem;
      margin-bottom: 0.85rem;
    }
    .metric-card {
      display: grid;
      grid-template-rows: auto auto auto 1fr;
      gap: 0.35rem;
      min-height: 10.5rem;
      padding: 1rem;
      border: 1px solid var(--line);
      border-top: 0.3rem solid var(--navy);
      border-radius: 0.5rem;
      background: var(--surface);
      box-shadow: 0 1rem 2.2rem rgba(16, 44, 107, 0.07);
    }
    .metric-card.growth,
    .metric-card.content { border-top-color: #b6ad2e; }
    .metric-card.good,
    .metric-card.contribution { border-top-color: #198b82; }
    .metric-card.watch { border-top-color: #b65f45; }
    .metric-card > span {
      color: var(--navy);
      font-size: 0.9rem;
      font-weight: 850;
    }
    .metric-card > strong {
      font-size: clamp(2rem, 4vw, 2.8rem);
      line-height: 1;
    }
    .metric-card > small {
      color: var(--muted);
      font-size: 0.86rem;
      font-weight: 650;
      line-height: 1.35;
    }
    .metric-card > em {
      align-self: end;
      color: var(--ink);
      font-size: 0.78rem;
      font-style: normal;
      font-weight: 800;
      padding-top: 0.65rem;
      border-top: 1px solid var(--line);
    }
    .section-kicker {
      margin: 0 0 0.2rem;
      color: var(--navy);
      font-size: 0.7rem;
      font-weight: 850;
      letter-spacing: 0.07em;
      text-transform: uppercase;
    }
    .health-card, .metric, .panel {
      border: 1px solid var(--line);
      border-radius: 0.5rem;
      background: var(--surface);
      box-shadow: 0 1rem 2.2rem rgba(16, 44, 107, 0.07);
    }
    .health-card, .metric {
      display: grid;
      gap: 0.85rem;
      padding: 1rem;
    }
    .health-main {
      display: grid;
      gap: 0.25rem;
    }
    .health-card span, .metric span {
      color: var(--navy);
      font-weight: 850;
      font-size: 0.9rem;
    }
    .health-card strong, .metric strong {
      font-size: 2rem;
      line-height: 1;
    }
    .health-card dl {
      display: grid;
      gap: 0.45rem;
      margin: 0;
      padding-top: 0.75rem;
      border-top: 1px solid var(--line);
    }
    .health-card dl div {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 0.75rem;
    }
    .health-card dt,
    .health-card dd {
      margin: 0;
      font-size: 0.84rem;
    }
    .health-card dt {
      white-space: nowrap;
    }
    .health-card dd {
      color: var(--ink);
      font-weight: 850;
      text-align: right;
    }
    .panel {
      padding: 1rem;
      margin-bottom: 0.85rem;
    }
    .panel-heading {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: 0.9rem;
    }
    .trend {
      display: grid;
      gap: 0.55rem;
    }
    .chart-legend {
      display: flex;
      flex-wrap: wrap;
      gap: 0.9rem;
      margin-bottom: 0.55rem;
      color: var(--muted);
      font-size: 0.78rem;
      font-weight: 800;
    }
    .chart-legend span {
      display: inline-flex;
      align-items: center;
      gap: 0.35rem;
    }
    .chart-legend i {
      width: 0.65rem;
      height: 0.65rem;
      border-radius: 0.15rem;
    }
    .series-navy { background: var(--navy) !important; }
    .series-yellow { background: #c1b62e !important; }
    .series-teal { background: #198b82 !important; }
    .series-muted { background: #8993a2 !important; }
    .chart-shell {
      display: grid;
      grid-template-columns: 2.75rem minmax(0, 1fr);
      gap: 0.45rem;
      align-items: stretch;
    }
    .y-axis {
      display: grid;
      grid-template-rows: 1rem 1fr;
      gap: 0.3rem;
      min-height: 13rem;
      padding-bottom: 2rem;
    }
    .y-axis strong {
      align-self: start;
      color: var(--muted);
      font-size: 0.62rem;
      font-weight: 850;
      line-height: 1;
      text-transform: uppercase;
    }
    .y-axis div {
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      min-height: 0;
    }
    .y-axis span {
      color: var(--muted);
      font-size: 0.66rem;
      font-weight: 800;
      line-height: 1;
      text-align: right;
    }
    .chart-plot {
      position: relative;
      min-width: max(100%, calc(var(--chart-columns) * 1.9rem));
      min-height: 13rem;
    }
    .chart-grid {
      position: absolute;
      inset: 1.3rem 0 1.45rem;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      pointer-events: none;
    }
    .chart-grid i {
      display: block;
      width: 100%;
      height: 1px;
      background: rgba(16, 44, 107, 0.14);
    }
    .grouped-chart {
      position: relative;
      display: grid;
      grid-template-columns: repeat(var(--chart-columns), minmax(0, 1fr));
      gap: 0.18rem;
      width: 100%;
      min-height: 13rem;
      padding: 1.3rem 0 0;
    }
    .grouped-day {
      position: relative;
      display: grid;
      grid-template-rows: minmax(0, 1fr) 1.45rem;
      align-items: end;
      justify-items: center;
      min-width: 0;
      gap: 0;
      outline: none;
    }
    .bar-pair {
      display: flex;
      align-items: flex-end;
      justify-content: center;
      gap: 0.08rem;
      width: 100%;
      height: 100%;
    }
    .bar-column {
      position: relative;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      align-items: center;
      width: min(44%, 0.8rem);
      height: 100%;
    }
    .bar-column b {
      position: absolute;
      bottom: calc(var(--bar-height, 0%) + 0.12rem);
      color: var(--ink);
      font-size: 0.58rem;
      font-weight: 900;
      line-height: 1;
      pointer-events: none;
    }
    .bar-column i {
      display: block;
      width: 100%;
      min-height: 0;
      border-radius: 0.25rem 0.25rem 0 0;
    }
    .grouped-day em {
      color: var(--muted);
      font-size: 0.56rem;
      font-style: normal;
      font-weight: 800;
      line-height: 1;
      padding-top: 0.5rem;
      white-space: nowrap;
    }
    .axis-label-hidden {
      visibility: hidden;
    }
    .line-chart-shell {
      min-width: 0;
    }
    .line-y-axis {
      min-height: 0;
      height: 12.3rem;
      padding-bottom: 0;
    }
    .line-chart-region {
      min-width: 0;
    }
    .line-chart-frame {
      position: relative;
      height: 11rem;
      margin-top: 1.3rem;
    }
    .line-chart-grid {
      inset: 0;
    }
    .line-chart {
      position: absolute;
      inset: 0;
      display: block;
      width: 100%;
      height: 100%;
      overflow: visible;
    }
    .line-series {
      fill: none;
      stroke-linecap: round;
      stroke-linejoin: round;
      stroke-width: 4;
      vector-effect: non-scaling-stroke;
    }
    .line-series.series-navy { stroke: var(--navy); }
    .line-series.series-yellow { stroke: #c1b62e; }
    .line-series.series-teal { stroke: #198b82; }
    .line-point {
      --series-color: var(--navy);
      position: absolute;
      z-index: 2;
      width: 1.8rem;
      height: 1.8rem;
      margin: 0;
      padding: 0;
      transform: translate(-50%, 50%);
      border: 0;
      border-radius: 50%;
      background: transparent !important;
      cursor: pointer;
    }
    .line-point.series-yellow { --series-color: #c1b62e; }
    .line-point.series-teal { --series-color: #198b82; }
    .line-point::before {
      content: "";
      position: absolute;
      inset: 50% auto auto 50%;
      width: 0.62rem;
      height: 0.62rem;
      transform: translate(-50%, -50%);
      border: 0.16rem solid white;
      border-radius: 50%;
      background: var(--series-color);
      box-shadow: 0 0 0 1px var(--series-color);
    }
    .line-point > span {
      position: absolute;
      left: 50%;
      top: calc(100% + 0.05rem);
      z-index: 6;
      display: none;
      width: max-content;
      max-width: min(13rem, 70vw);
      transform: translateX(-50%);
      border-radius: 0.35rem;
      background: var(--ink);
      color: white;
      font-size: 0.68rem;
      font-weight: 750;
      line-height: 1.3;
      padding: 0.42rem 0.55rem;
      box-shadow: 0 0.4rem 1rem rgba(0, 0, 0, 0.18);
      pointer-events: none;
    }
    .line-point:hover > span,
    .line-point:focus-visible > span,
    .line-point:focus > span {
      display: block;
    }
    .line-point.edge-start > span {
      left: 0;
      transform: none;
    }
    .line-point.edge-end > span {
      left: auto;
      right: 0;
      transform: none;
    }
    .line-point:focus-visible {
      outline: 2px solid var(--navy);
      outline-offset: 1px;
    }
    .line-x-axis {
      position: relative;
      height: 1.45rem;
      border-top: 1px solid rgba(16, 44, 107, 0.14);
    }
    .line-x-axis span {
      position: absolute;
      top: 0.45rem;
      color: var(--muted);
      font-size: 0.6rem;
      font-weight: 800;
      line-height: 1;
      white-space: nowrap;
    }
    .line-x-axis span.start { transform: none; }
    .line-x-axis span.middle { transform: translateX(-50%); }
    .line-x-axis span.end { transform: translateX(-100%); }
    .grouped-day:hover::after,
    .grouped-day:focus-visible::after {
      content: attr(data-tooltip);
      position: absolute;
      left: 50%;
      bottom: calc(100% - 1rem);
      z-index: 5;
      width: max-content;
      max-width: 14rem;
      transform: translateX(-50%);
      border-radius: 0.35rem;
      background: var(--ink);
      color: white;
      font-size: 0.68rem;
      font-style: normal;
      font-weight: 750;
      line-height: 1.3;
      padding: 0.42rem 0.55rem;
      box-shadow: 0 0.4rem 1rem rgba(0, 0, 0, 0.18);
      pointer-events: none;
    }
    .x-axis-title {
      color: var(--muted);
      font-size: 0.62rem;
      font-weight: 850;
      line-height: 1;
      margin-top: 0.25rem;
      text-align: center;
      text-transform: uppercase;
    }
    .insight-panel { border-top: 0.3rem solid var(--yellow); }
    .insight-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 0.7rem;
    }
    .insight {
      padding: 0.8rem;
      border-left: 0.25rem solid var(--navy);
      background: rgba(16, 44, 107, 0.05);
    }
    .insight.positive {
      border-left-color: #198b82;
      background: rgba(25, 139, 130, 0.08);
    }
    .insight.warning {
      border-left-color: #b65f45;
      background: rgba(182, 95, 69, 0.08);
    }
    .insight strong {
      color: var(--ink);
      font-size: 0.92rem;
    }
    .insight p {
      margin: 0.25rem 0 0;
      color: var(--muted);
      font-size: 0.83rem;
      font-weight: 650;
      line-height: 1.4;
    }
    .distribution {
      display: grid;
      gap: 0.9rem;
    }
    .distribution-row {
      display: grid;
      gap: 0.3rem;
    }
    .distribution-row > div {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 0.8rem;
    }
    .distribution-row > div span,
    .distribution-row small {
      color: var(--muted);
      font-size: 0.78rem;
      font-weight: 700;
    }
    .distribution-row > i {
      display: block;
      height: 0.75rem;
      overflow: hidden;
      border-radius: 999px;
      background: rgba(16, 44, 107, 0.08);
    }
    .distribution-row > i b {
      display: block;
      min-width: 0;
      height: 100%;
      border-radius: inherit;
    }
    .admin-tools {
      margin-top: 1rem;
      border: 1px solid var(--line);
      border-radius: 0.5rem;
      background: rgba(255, 255, 255, 0.55);
    }
    .admin-tools > summary {
      cursor: pointer;
      color: var(--navy);
      font-weight: 850;
      padding: 1rem;
    }
    .admin-tools-body {
      padding: 0 1rem 0.2rem;
    }
    .chart-viewport {
      overflow-x: auto;
      overflow-y: visible;
      padding: 0 0.1rem 0.15rem;
      margin: 0 -0.1rem;
      scrollbar-width: thin;
      scrollbar-color: rgba(16, 44, 107, 0.35) transparent;
      -webkit-overflow-scrolling: touch;
    }
    .chart-viewport::-webkit-scrollbar {
      height: 0.35rem;
    }
    .chart-viewport::-webkit-scrollbar-thumb {
      background: rgba(16, 44, 107, 0.25);
      border-radius: 999px;
    }
    .column-chart {
      position: relative;
      display: grid;
      grid-template-columns: repeat(var(--chart-columns), minmax(0, 1fr));
      align-items: stretch;
      gap: 0.35rem;
      min-width: max(100%, calc(var(--chart-columns) * 0.95rem));
      min-height: 11rem;
      padding: 0.25rem 0.15rem 0;
    }
    .column-chart::before {
      content: "";
      position: absolute;
      inset: 1.15rem 0.15rem 1.35rem;
      background: linear-gradient(to top, rgba(16, 44, 107, 0.08) 1px, transparent 1px);
      background-size: 100% 25%;
      pointer-events: none;
    }
    .column-bar {
      position: relative;
      display: grid;
      grid-template-rows: 1rem minmax(0, 1fr) 1.05rem;
      justify-items: center;
      align-items: end;
      min-width: 0;
      gap: 0.18rem;
      z-index: 1;
    }
    .column-bar span {
      color: var(--ink);
      font-size: 0.68rem;
      font-weight: 850;
      line-height: 1;
      min-height: 1rem;
      max-width: 2.4rem;
      overflow: hidden;
      text-align: center;
      text-overflow: ellipsis;
    }
    .column-bar i {
      align-self: end;
      display: block;
      width: clamp(0.45rem, 65%, 1.1rem);
      min-height: 0;
      border-radius: 0.35rem 0.35rem 0.12rem 0.12rem;
      background: var(--navy);
    }
    .column-bar em {
      color: var(--muted);
      font-style: normal;
      font-size: 0.66rem;
      font-weight: 750;
      line-height: 1;
      min-height: 1rem;
      max-width: 2.7rem;
      overflow: hidden;
      text-align: center;
      text-overflow: clip;
      white-space: nowrap;
    }
    .list-row i {
      display: block;
      height: 0.95rem;
      border-radius: 999px;
      background: rgba(16, 44, 107, 0.09);
      overflow: hidden;
    }
    .list-row i::before {
      display: block;
      height: 100%;
      border-radius: inherit;
      background: var(--navy);
      content: "";
    }
    .two-column {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 0.85rem;
    }
    .list {
      display: grid;
      gap: 0.65rem;
    }
    .list-row {
      display: grid;
      gap: 0.35rem;
    }
    .list-row div {
      display: flex;
      justify-content: space-between;
      gap: 1rem;
    }
    .list-row i {
      max-width: 100%;
    }
    .device-label-form {
      display: grid;
      grid-template-columns: 11rem minmax(12rem, 1.1fr) minmax(10rem, 0.9fr) 9rem auto auto;
      gap: 0.65rem;
      align-items: center;
    }
    .device-label-form input,
    .device-label-form select,
    .device-label-form button {
      width: 100%;
      border: 1px solid var(--line);
      border-radius: 0.5rem;
      background: rgba(255, 255, 255, 0.9);
      color: var(--ink);
      font: inherit;
      font-weight: 750;
      min-height: 2.7rem;
      padding: 0.65rem 0.75rem;
    }
    .device-label-form button {
      background: var(--navy);
      color: white;
      cursor: pointer;
    }
    .compact-toggle {
      justify-content: center;
      color: var(--muted);
      font-size: 0.9rem;
    }
    .form-status {
      color: var(--muted);
      font-weight: 700;
      min-height: 1.2rem;
      margin-top: 0.65rem;
    }
    .device-list {
      display: grid;
      gap: 0.7rem;
    }
    .device-row {
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 0.35rem 0.8rem;
      align-items: center;
      border-bottom: 1px solid var(--line);
      padding-bottom: 0.7rem;
    }
    .device-row:last-child {
      border-bottom: 0;
      padding-bottom: 0;
    }
    .device-row strong,
    .device-row span,
    .device-row small {
      display: block;
    }
    .device-row span,
    .device-row small {
      color: var(--muted);
      font-size: 0.84rem;
      font-weight: 650;
    }
    .device-row code {
      color: var(--navy);
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 0.76rem;
      font-weight: 800;
      max-width: 16rem;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .device-row small {
      grid-column: 1 / -1;
    }
    .device-row button {
      border: 1px solid var(--line);
      border-radius: 0.5rem;
      background: var(--navy);
      color: white;
      cursor: pointer;
      font: inherit;
      font-size: 0.84rem;
      font-weight: 850;
      padding: 0.45rem 0.7rem;
    }
    @media (max-width: 760px) {
      .admin-shell {
        padding:
          max(0.8rem, env(safe-area-inset-top))
          max(0.75rem, env(safe-area-inset-right))
          max(1.2rem, env(safe-area-inset-bottom))
          max(0.75rem, env(safe-area-inset-left));
      }
      .admin-header, .two-column { display: block; }
      .admin-header { margin-bottom: 0.8rem; }
      h1 {
        font-size: clamp(2.35rem, 14vw, 3.5rem);
        line-height: 0.96;
      }
      .session {
        overflow-wrap: anywhere;
        text-align: left;
        margin-top: 0.75rem;
      }
      .status {
        padding: 0.75rem;
        margin-bottom: 0.75rem;
      }
      .controls {
        display: grid;
        gap: 0.75rem;
      }
      .control-actions {
        display: grid;
        grid-template-columns: 1fr;
        justify-items: stretch;
        order: -1;
        margin: 0;
      }
      .window-picker { min-width: 0; width: 100%; }
      .window-picker legend {
        font-size: 0.75rem;
        margin-bottom: 0.15rem;
      }
      .window-picker button {
        min-height: 2.75rem;
        font-size: 0.9rem;
        padding: 0.55rem 0.4rem;
      }
      .toggle-row {
        min-height: 2.75rem;
        align-items: flex-start;
      }
      .toggle-row input, .compact-toggle input {
        width: 1.25rem;
        height: 1.25rem;
        margin-top: 0.1rem;
      }
      .pill {
        justify-self: start;
        white-space: normal;
      }
      .health-grid, .metric-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 0.65rem;
        margin-bottom: 0.65rem;
      }
      .metric-card {
        min-height: 0;
        padding: 0.8rem;
      }
      .metric-card > strong { font-size: clamp(1.8rem, 10vw, 2.35rem); }
      .metric-card > small { font-size: 0.8rem; }
      .panel {
        padding: 0.8rem;
        margin-bottom: 0.65rem;
      }
      .insight-grid { grid-template-columns: 1fr; }
      .panel-heading {
        align-items: flex-start;
        flex-direction: column;
        gap: 0.25rem;
      }
      .panel-heading span { font-size: 0.9rem; }
      .chart-viewport {
        margin-inline: -0.25rem;
        padding-inline: 0.25rem;
      }
      .line-chart-shell {
        grid-template-columns: 2.15rem minmax(0, 1fr);
        gap: 0.35rem;
      }
      .line-chart-frame {
        height: 10rem;
      }
      .line-y-axis {
        height: 11.3rem;
      }
      .line-series {
        stroke-width: 3;
      }
      .line-x-axis.sparse-axis span:nth-child(even) {
        display: none;
      }
      .column-chart {
        gap: 0.18rem;
        min-width: max(100%, calc(var(--chart-columns) * 0.78rem));
        min-height: 9.5rem;
      }
      .column-bar {
        grid-template-rows: 0.9rem minmax(0, 1fr) 0.95rem;
        gap: 0.12rem;
      }
      .column-bar span { font-size: 0.56rem; }
      .column-bar i {
        width: clamp(0.34rem, 62%, 0.66rem);
        border-radius: 0.25rem 0.25rem 0.1rem 0.1rem;
      }
      .column-bar em { font-size: 0.55rem; }
      .grouped-chart {
        gap: 0.1rem;
        min-height: 11rem;
      }
      .chart-shell { grid-template-columns: 2.35rem minmax(0, 1fr); gap: 0.3rem; }
      .chart-plot {
        min-width: max(100%, calc(var(--chart-columns) * 2.5rem));
        min-height: 11rem;
      }
      .y-axis { min-height: 11rem; }
      .bar-pair { gap: 0.06rem; }
      .bar-column { width: min(45%, 0.58rem); }
      .bar-column b { font-size: 0.52rem; }
      .grouped-day em { font-size: 0.54rem; }
      .device-label-form { grid-template-columns: 1fr; }
      .compact-toggle { justify-content: flex-start; }
      .device-row {
        grid-template-columns: minmax(0, 1fr);
      }
      .device-row small { grid-column: 1; }
      .device-row button {
        min-height: 2.75rem;
        width: 100%;
      }
    }
    @media (max-width: 390px) {
      .health-grid, .metric-grid { grid-template-columns: 1fr; }
      .metric-card {
        grid-template-columns: minmax(0, 1fr) auto;
        grid-template-rows: auto auto;
        align-items: center;
        gap: 0.25rem 0.65rem;
      }
      .metric-card > strong {
        grid-column: 2;
        grid-row: 1 / span 2;
      }
      .metric-card > small { grid-column: 1; }
      .metric-card > em {
        grid-column: 1 / -1;
        grid-row: 3;
      }
    }
  `;
}

function adminHTMLHeaders(): Headers {
  const headers = new Headers();
  headers.set("Cache-Control", "no-store");
  headers.set("Content-Security-Policy", "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'");
  headers.set("Referrer-Policy", "no-referrer");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("X-Robots-Tag", "noindex, nofollow");
  return headers;
}

function adminJSONHeaders(): Headers {
  const headers = adminHTMLHeaders();
  headers.set("Content-Type", "application/json; charset=utf-8");
  return headers;
}

function adminAnalyticsOptions(url: URL): AdminAnalyticsOptions {
  const requestedDays = Number.parseInt(url.searchParams.get("days") ?? "", 10);
  return {
    includeInternal: ["1", "true", "yes"].includes((url.searchParams.get("include_internal") ?? "").toLowerCase()),
    days: requestedDays === 1 || requestedDays === 7 || requestedDays === 30 ? requestedDays : 30,
  };
}

function adminAnalyticsDeviceAllowedSQL(alias: string, options: AdminAnalyticsOptions): string {
  if (options.includeInternal) {
    return "1 = 1";
  }

  return `NOT EXISTS (
    SELECT 1
    FROM admin_device_labels dl
    WHERE dl.identity_type = 'analytics_device'
      AND dl.identity_id = ${alias}.analytics_device_id
      AND dl.excluded_from_core_metrics = 1
  )
  AND NOT EXISTS (
    SELECT 1
    FROM device_identity_links dil
    JOIN admin_device_labels linked_dl
      ON linked_dl.identity_type = 'anonymous_user'
     AND linked_dl.identity_id = dil.anonymous_user_id
     AND linked_dl.excluded_from_core_metrics = 1
    WHERE dil.analytics_device_id = ${alias}.analytics_device_id
  )`;
}

function adminAnonymousUserAllowedSQL(alias: string, options: AdminAnalyticsOptions): string {
  if (options.includeInternal) {
    return "1 = 1";
  }

  return `NOT EXISTS (
    SELECT 1
    FROM admin_device_labels dl
    WHERE dl.identity_type = 'anonymous_user'
      AND dl.identity_id = ${alias}.anonymous_user_id
      AND dl.excluded_from_core_metrics = 1
  )
  AND NOT EXISTS (
    SELECT 1
    FROM device_identity_links dil
    JOIN admin_device_labels linked_dl
      ON linked_dl.identity_type = 'analytics_device'
     AND linked_dl.identity_id = dil.analytics_device_id
     AND linked_dl.excluded_from_core_metrics = 1
    WHERE dil.anonymous_user_id = ${alias}.anonymous_user_id
  )`;
}

function activeEventWhere(alias?: string): string {
  if (!alias) {
    return ACTIVE_EVENT_WHERE;
  }

  return `${alias}.moderation_status = 'active' AND ${alias}.is_deleted = 0`;
}

async function buildRolling24HourMetrics(env: Env, options: AdminAnalyticsOptions, now: Date) {
  const through = now.toISOString();
  const since = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const previousSince = new Date(now.getTime() - 48 * 60 * 60 * 1000).toISOString();
  const analyticsEventFilter = adminAnalyticsDeviceAllowedSQL("ae", options);
  const analyticsDeviceFilter = adminAnalyticsDeviceAllowedSQL("ad", options);
  const anonymousUserFilter = adminAnonymousUserAllowedSQL("ve", options);
  const [
    analytics,
    previousAnalytics,
    newDevices,
    content,
    previousContent,
    viberDepth,
    excluded,
    topEvents,
    appVersions,
    hourlyAnalytics,
    hourlyNewDevices,
    hourlyContent,
  ] = await Promise.all([
    env.DB.prepare(
      `SELECT
         COUNT(DISTINCT ae.analytics_device_id) AS active_devices,
         COUNT(*) AS event_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'app_open' THEN 1 ELSE 0 END), 0) AS app_open_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'search_performed' THEN 1 ELSE 0 END), 0) AS search_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'place_selected' THEN 1 ELSE 0 END), 0) AS place_select_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'vibe_submitted' THEN 1 ELSE 0 END), 0) AS vibe_submit_count,
         COALESCE(SUM(CASE WHEN ae.event_name LIKE 'account_%' THEN 1 ELSE 0 END), 0) AS account_event_count
       FROM analytics_events ae
       WHERE ae.created_at >= ?
         AND ae.created_at < ?
         AND ${analyticsEventFilter}`
    )
      .bind(since, through)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         COUNT(DISTINCT ae.analytics_device_id) AS active_devices,
         COALESCE(SUM(CASE WHEN ae.event_name = 'app_open' THEN 1 ELSE 0 END), 0) AS app_open_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'search_performed' THEN 1 ELSE 0 END), 0) AS search_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'place_selected' THEN 1 ELSE 0 END), 0) AS place_select_count
       FROM analytics_events ae
       WHERE ae.created_at >= ?
         AND ae.created_at < ?
         AND ${analyticsEventFilter}`
    )
      .bind(previousSince, since)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         COALESCE(SUM(CASE WHEN ad.first_seen_at >= ? AND ad.first_seen_at < ? THEN 1 ELSE 0 END), 0) AS current_devices,
         COALESCE(SUM(CASE WHEN ad.first_seen_at >= ? AND ad.first_seen_at < ? THEN 1 ELSE 0 END), 0) AS previous_devices
       FROM analytics_devices ad
       WHERE ad.first_seen_at >= ?
         AND ad.first_seen_at < ?
         AND ${analyticsDeviceFilter}`
    )
      .bind(since, through, previousSince, since, previousSince, through)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         COUNT(*) AS vibe_submissions,
         COUNT(DISTINCT ve.anonymous_user_id) AS unique_vibers,
         COUNT(DISTINCT ve.place_id) AS vibed_places
       FROM vibe_events ve
       WHERE ${activeEventWhere("ve")}
         AND ve.created_at >= ?
         AND ve.created_at < ?
         AND ${anonymousUserFilter}`
    )
      .bind(since, through)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         COUNT(*) AS vibe_submissions,
         COUNT(DISTINCT ve.anonymous_user_id) AS unique_vibers,
         COUNT(DISTINCT ve.place_id) AS vibed_places
       FROM vibe_events ve
       WHERE ${activeEventWhere("ve")}
         AND ve.created_at >= ?
         AND ve.created_at < ?
         AND ${anonymousUserFilter}`
    )
      .bind(previousSince, since)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         COUNT(*) AS contributors,
         COALESCE(SUM(CASE WHEN place_count = 1 THEN 1 ELSE 0 END), 0) AS one_place_contributors,
         COALESCE(SUM(CASE WHEN place_count BETWEEN 2 AND 3 THEN 1 ELSE 0 END), 0) AS two_to_three_place_contributors,
         COALESCE(SUM(CASE WHEN place_count >= 4 THEN 1 ELSE 0 END), 0) AS four_plus_place_contributors
       FROM (
         SELECT ve.anonymous_user_id, COUNT(DISTINCT ve.place_id) AS place_count
         FROM vibe_events ve
         WHERE ${activeEventWhere("ve")}
           AND ve.created_at >= ?
           AND ve.created_at < ?
           AND ${anonymousUserFilter}
         GROUP BY ve.anonymous_user_id
       )`
    )
      .bind(since, through)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT
         (SELECT COUNT(DISTINCT ae.analytics_device_id)
          FROM analytics_events ae
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'analytics_device'
           AND dl.identity_id = ae.analytics_device_id
           AND dl.excluded_from_core_metrics = 1
          WHERE ae.created_at >= ? AND ae.created_at < ?) AS excluded_analytics_devices,
         (SELECT COUNT(DISTINCT ve.anonymous_user_id)
          FROM vibe_events ve
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'anonymous_user'
           AND dl.identity_id = ve.anonymous_user_id
           AND dl.excluded_from_core_metrics = 1
          WHERE ${activeEventWhere("ve")}
            AND ve.created_at >= ? AND ve.created_at < ?) AS excluded_historical_vibers,
         (SELECT COUNT(*)
          FROM vibe_events ve
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'anonymous_user'
           AND dl.identity_id = ve.anonymous_user_id
           AND dl.excluded_from_core_metrics = 1
          WHERE ${activeEventWhere("ve")}
            AND ve.created_at >= ? AND ve.created_at < ?) AS excluded_historical_vibes`
    )
      .bind(since, through, since, through, since, through)
      .first<Record<string, number | null>>(),
    env.DB.prepare(
      `SELECT ae.event_name AS name, COUNT(*) AS count
       FROM analytics_events ae
       WHERE ae.created_at >= ?
         AND ae.created_at < ?
         AND ${analyticsEventFilter}
       GROUP BY ae.event_name
       ORDER BY count DESC, ae.event_name ASC
       LIMIT 12`
    )
      .bind(since, through)
      .all<AnalyticsNameCountRow>(),
    env.DB.prepare(
      `SELECT COALESCE(ae.app_version, 'Unknown') AS name, COUNT(DISTINCT ae.analytics_device_id) AS count
       FROM analytics_events ae
       WHERE ae.created_at >= ?
         AND ae.created_at < ?
         AND ${analyticsEventFilter}
       GROUP BY COALESCE(ae.app_version, 'Unknown')
       ORDER BY count DESC, name ASC
       LIMIT 12`
    )
      .bind(since, through)
      .all<AnalyticsNameCountRow>(),
    env.DB.prepare(
      `SELECT
         CAST((julianday(ae.created_at) - julianday(?)) * 24 AS INTEGER) AS bucket_index,
         COUNT(DISTINCT ae.analytics_device_id) AS active_devices,
         COUNT(*) AS event_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'app_open' THEN 1 ELSE 0 END), 0) AS app_open_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'search_performed' THEN 1 ELSE 0 END), 0) AS search_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'place_selected' THEN 1 ELSE 0 END), 0) AS place_select_count,
         COALESCE(SUM(CASE WHEN ae.event_name = 'vibe_submitted' THEN 1 ELSE 0 END), 0) AS vibe_submit_count,
         COALESCE(SUM(CASE WHEN ae.event_name LIKE 'account_%' THEN 1 ELSE 0 END), 0) AS account_event_count
       FROM analytics_events ae
       WHERE ae.created_at >= ?
         AND ae.created_at < ?
         AND ${analyticsEventFilter}
       GROUP BY bucket_index
       HAVING bucket_index BETWEEN 0 AND 23
       ORDER BY bucket_index ASC`
    )
      .bind(since, since, through)
      .all<AnalyticsHourlyRow>(),
    env.DB.prepare(
      `SELECT
         CAST((julianday(ad.first_seen_at) - julianday(?)) * 24 AS INTEGER) AS bucket_index,
         COUNT(*) AS new_devices
       FROM analytics_devices ad
       WHERE ad.first_seen_at >= ?
         AND ad.first_seen_at < ?
         AND ${analyticsDeviceFilter}
       GROUP BY bucket_index
       HAVING bucket_index BETWEEN 0 AND 23
       ORDER BY bucket_index ASC`
    )
      .bind(since, since, through)
      .all<AnalyticsHourlyNewDevicesRow>(),
    env.DB.prepare(
      `SELECT
         CAST((julianday(ve.created_at) - julianday(?)) * 24 AS INTEGER) AS bucket_index,
         COUNT(*) AS vibe_submissions,
         COUNT(DISTINCT ve.anonymous_user_id) AS unique_vibers,
         COUNT(DISTINCT ve.place_id) AS vibed_places
       FROM vibe_events ve
       WHERE ${activeEventWhere("ve")}
         AND ve.created_at >= ?
         AND ve.created_at < ?
         AND ${anonymousUserFilter}
       GROUP BY bucket_index
       HAVING bucket_index BETWEEN 0 AND 23
       ORDER BY bucket_index ASC`
    )
      .bind(since, since, through)
      .all<VibeHistoryHourlyRow>(),
  ]);

  const analyticsByHour = new Map(
    (hourlyAnalytics.results ?? []).map((row) => [rowNumber(row.bucket_index), row])
  );
  const newDevicesByHour = new Map(
    (hourlyNewDevices.results ?? []).map((row) => [rowNumber(row.bucket_index), row])
  );
  const contentByHour = new Map(
    (hourlyContent.results ?? []).map((row) => [rowNumber(row.bucket_index), row])
  );
  const sinceTime = new Date(since).getTime();
  const hourly = Array.from({ length: 24 }, (_, bucketIndex) => {
    const analyticsRow = analyticsByHour.get(bucketIndex);
    const newDeviceRow = newDevicesByHour.get(bucketIndex);
    const contentRow = contentByHour.get(bucketIndex);
    return {
      bucketStart: new Date(sinceTime + bucketIndex * 60 * 60 * 1000).toISOString(),
      bucketEnd: new Date(sinceTime + (bucketIndex + 1) * 60 * 60 * 1000).toISOString(),
      activeDevices: rowNumber(analyticsRow?.active_devices),
      newDevices: rowNumber(newDeviceRow?.new_devices),
      events: rowNumber(analyticsRow?.event_count),
      appOpens: rowNumber(analyticsRow?.app_open_count),
      searches: rowNumber(analyticsRow?.search_count),
      placeSelections: rowNumber(analyticsRow?.place_select_count),
      trackedVibeSubmissions: rowNumber(analyticsRow?.vibe_submit_count),
      accountEvents: rowNumber(analyticsRow?.account_event_count),
      vibeSubmissions: rowNumber(contentRow?.vibe_submissions),
      uniqueVibers: rowNumber(contentRow?.unique_vibers),
      vibedPlaces: rowNumber(contentRow?.vibed_places),
    };
  });

  return {
    since,
    through,
    activeDevices: rowNumber(analytics?.active_devices),
    previousActiveDevices: rowNumber(previousAnalytics?.active_devices),
    newDevices: rowNumber(newDevices?.current_devices),
    previousNewDevices: rowNumber(newDevices?.previous_devices),
    events: rowNumber(analytics?.event_count),
    appOpens: rowNumber(analytics?.app_open_count),
    previousAppOpens: rowNumber(previousAnalytics?.app_open_count),
    searches: rowNumber(analytics?.search_count),
    previousSearches: rowNumber(previousAnalytics?.search_count),
    placeSelections: rowNumber(analytics?.place_select_count),
    previousPlaceSelections: rowNumber(previousAnalytics?.place_select_count),
    trackedVibeSubmissions: rowNumber(analytics?.vibe_submit_count),
    accountEvents: rowNumber(analytics?.account_event_count),
    vibeSubmissions: rowNumber(content?.vibe_submissions),
    previousVibeSubmissions: rowNumber(previousContent?.vibe_submissions),
    uniqueVibers: rowNumber(content?.unique_vibers),
    previousUniqueVibers: rowNumber(previousContent?.unique_vibers),
    vibedPlaces: rowNumber(content?.vibed_places),
    previousVibedPlaces: rowNumber(previousContent?.vibed_places),
    onePlaceContributors: rowNumber(viberDepth?.one_place_contributors),
    twoToThreePlaceContributors: rowNumber(viberDepth?.two_to_three_place_contributors),
    fourPlusPlaceContributors: rowNumber(viberDepth?.four_plus_place_contributors),
    excludedAnalyticsDevices: rowNumber(excluded?.excluded_analytics_devices),
    excludedHistoricalVibers: rowNumber(excluded?.excluded_historical_vibers),
    excludedHistoricalVibes: rowNumber(excluded?.excluded_historical_vibes),
    topEvents: topEvents.results ?? [],
    appVersions: appVersions.results ?? [],
    hourly,
  };
}

export async function buildAdminAnalyticsPayload(env: Env, options: AdminAnalyticsOptions = { includeInternal: false }) {
  const windowDays: AdminAnalyticsWindowDays = options.days === 1 || options.days === 7 || options.days === 30
    ? options.days
    : 30;
  const now = new Date();
  const rolling24Hours = windowDays === 1 ? await buildRolling24HourMetrics(env, options, now) : null;
  const today = dayString(now);
  const since7 = addDays(today, -6);
  const sinceWindow = addDays(today, -(windowDays - 1));
  const summarySince = sinceWindow < since7 ? sinceWindow : since7;
  const sincePreviousWindow = addDays(today, -(windowDays * 2 - 1));
  const throughPreviousWindow = addDays(today, -windowDays);
  const day1Retention = await fetchRetentionMetric(env, 1, sinceWindow, addDays(today, -1), options);
  const day7Retention = await fetchRetentionMetric(env, 7, sinceWindow, addDays(today, -7), options);
  const analyticsDeviceFilter = adminAnalyticsDeviceAllowedSQL("dd", options);
  const analyticsDevicesFilter = adminAnalyticsDeviceAllowedSQL("ad", options);
  const analyticsEventsFilter = adminAnalyticsDeviceAllowedSQL("ae", options);
  const anonymousUserFilter = adminAnonymousUserAllowedSQL("ve", options);
  const [summary, newDevices, previousPeriod, usageDepth, contentTotals, viberDepth, excludedSummary, dailyResult, vibeHistoryResult, eventsResult, versionsResult, labelsResult, recentAnalyticsDevices, recentAnonymousUsers] = await Promise.all([
    env.DB.prepare(
      `SELECT
         COUNT(DISTINCT CASE WHEN dd.day = ? THEN dd.analytics_device_id END) AS active_today,
         COUNT(DISTINCT CASE WHEN dd.day >= ? THEN dd.analytics_device_id END) AS active_7d,
         COUNT(DISTINCT CASE WHEN dd.day >= ? THEN dd.analytics_device_id END) AS active_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.event_count ELSE 0 END), 0) AS events_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.app_open_count ELSE 0 END), 0) AS app_opens_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.search_count ELSE 0 END), 0) AS searches_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.place_select_count ELSE 0 END), 0) AS place_selects_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.vibe_submit_count ELSE 0 END), 0) AS vibes_30d,
         COALESCE(SUM(CASE WHEN dd.day >= ? THEN dd.account_event_count ELSE 0 END), 0) AS account_events_30d
       FROM analytics_device_days dd
       WHERE dd.day >= ?
         AND ${analyticsDeviceFilter}`
    )
      .bind(today, since7, sinceWindow, sinceWindow, sinceWindow, sinceWindow, sinceWindow, sinceWindow, sinceWindow, summarySince)
      .first<AnalyticsSummaryRow>(),
    env.DB.prepare(`SELECT COUNT(*) AS new_devices_30d FROM analytics_devices ad WHERE ad.first_seen_day >= ? AND ${analyticsDevicesFilter}`)
      .bind(sinceWindow)
      .first<AnalyticsNewDevicesRow>(),
    env.DB.prepare(
      `SELECT
         COUNT(DISTINCT dd.analytics_device_id) AS active_devices,
         (SELECT COUNT(*)
          FROM analytics_devices ad
          WHERE ad.first_seen_day BETWEEN ? AND ?
            AND ${analyticsDevicesFilter}) AS new_devices,
         COALESCE(SUM(dd.app_open_count), 0) AS app_opens,
         COALESCE(SUM(dd.search_count), 0) AS searches,
         COALESCE(SUM(dd.place_select_count), 0) AS place_selects
       FROM analytics_device_days dd
       WHERE dd.day BETWEEN ? AND ?
         AND ${analyticsDeviceFilter}`
    )
      .bind(sincePreviousWindow, throughPreviousWindow, sincePreviousWindow, throughPreviousWindow)
      .first<AnalyticsPreviousPeriodRow>(),
    env.DB.prepare(
      `SELECT
         COUNT(*) AS active_devices,
         COALESCE(SUM(CASE WHEN active_days = 1 THEN 1 ELSE 0 END), 0) AS one_day_devices,
         COALESCE(SUM(CASE WHEN active_days >= 2 THEN 1 ELSE 0 END), 0) AS repeat_devices,
         COALESCE(SUM(CASE WHEN active_days >= 4 THEN 1 ELSE 0 END), 0) AS loyal_devices,
         COALESCE(SUM(active_days), 0) AS active_device_days
       FROM (
         SELECT dd.analytics_device_id, COUNT(DISTINCT dd.day) AS active_days
         FROM analytics_device_days dd
         WHERE dd.day >= ?
           AND ${analyticsDeviceFilter}
         GROUP BY dd.analytics_device_id
       )`
    )
      .bind(sinceWindow)
      .first<AnalyticsUsageDepthRow>(),
    env.DB.prepare(
      `SELECT COUNT(*) AS total_vibes,
              COUNT(DISTINCT place_id) AS total_vibed_places,
              COUNT(DISTINCT anonymous_user_id) AS total_anonymous_vibers,
              COUNT(CASE WHEN substr(created_at, 1, 10) >= ? THEN 1 END) AS vibes_30d,
              COUNT(CASE WHEN substr(created_at, 1, 10) BETWEEN ? AND ? THEN 1 END) AS vibes_previous_30d,
              COUNT(DISTINCT CASE WHEN substr(created_at, 1, 10) >= ? THEN anonymous_user_id END) AS anonymous_vibers_30d,
              COUNT(DISTINCT CASE WHEN substr(created_at, 1, 10) BETWEEN ? AND ? THEN anonymous_user_id END) AS anonymous_vibers_previous_30d,
              COUNT(DISTINCT CASE WHEN substr(created_at, 1, 10) >= ? THEN place_id END) AS vibed_places_30d,
              COUNT(DISTINCT CASE WHEN substr(created_at, 1, 10) BETWEEN ? AND ? THEN place_id END) AS vibed_places_previous_30d,
              MIN(created_at) AS first_vibe_at,
              MAX(created_at) AS last_vibe_at
       FROM vibe_events ve
       WHERE ${activeEventWhere("ve")}
         AND ${anonymousUserFilter}`
    )
      .bind(
        sinceWindow,
        sincePreviousWindow,
        throughPreviousWindow,
        sinceWindow,
        sincePreviousWindow,
        throughPreviousWindow,
        sinceWindow,
        sincePreviousWindow,
        throughPreviousWindow
      )
      .first<AnalyticsContentTotalsRow>(),
    env.DB.prepare(
      `SELECT
         COUNT(*) AS contributors,
         COALESCE(SUM(CASE WHEN place_count = 1 THEN 1 ELSE 0 END), 0) AS one_place_contributors,
         COALESCE(SUM(CASE WHEN place_count BETWEEN 2 AND 3 THEN 1 ELSE 0 END), 0) AS two_to_three_place_contributors,
         COALESCE(SUM(CASE WHEN place_count >= 4 THEN 1 ELSE 0 END), 0) AS four_plus_place_contributors
       FROM (
         SELECT ve.anonymous_user_id, COUNT(*) AS place_count
         FROM vibe_events ve
         WHERE ${activeEventWhere("ve")}
           AND ${anonymousUserFilter}
           AND substr(ve.created_at, 1, 10) >= ?
         GROUP BY ve.anonymous_user_id
       )`
    )
      .bind(sinceWindow)
      .first<ViberDepthRow>(),
    env.DB.prepare(
      `SELECT
         (SELECT COUNT(DISTINCT dd.analytics_device_id)
          FROM analytics_device_days dd
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'analytics_device'
           AND dl.identity_id = dd.analytics_device_id
           AND dl.excluded_from_core_metrics = 1
          WHERE dd.day >= ?) AS excluded_analytics_devices_30d,
         (SELECT COUNT(DISTINCT ve.anonymous_user_id)
          FROM vibe_events ve
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'anonymous_user'
           AND dl.identity_id = ve.anonymous_user_id
           AND dl.excluded_from_core_metrics = 1
          WHERE ${activeEventWhere("ve")}
            AND substr(ve.created_at, 1, 10) >= ?) AS excluded_historical_vibers_30d,
         (SELECT COUNT(*)
          FROM vibe_events ve
          INNER JOIN admin_device_labels dl
            ON dl.identity_type = 'anonymous_user'
           AND dl.identity_id = ve.anonymous_user_id
           AND dl.excluded_from_core_metrics = 1
          WHERE ${activeEventWhere("ve")}
            AND substr(ve.created_at, 1, 10) >= ?) AS excluded_historical_vibes_30d`
    )
      .bind(sinceWindow, sinceWindow, sinceWindow)
      .first<AdminExcludedSummaryRow>(),
    env.DB.prepare(
      `SELECT
         dd.day,
         COUNT(*) AS active_devices,
         (SELECT COUNT(*) FROM analytics_devices ad WHERE ad.first_seen_day = dd.day AND ${analyticsDevicesFilter}) AS new_devices,
         COALESCE(SUM(dd.event_count), 0) AS event_count,
         COALESCE(SUM(dd.app_open_count), 0) AS app_open_count,
         COALESCE(SUM(dd.search_count), 0) AS search_count,
         COALESCE(SUM(dd.place_select_count), 0) AS place_select_count,
         COALESCE(SUM(dd.vibe_submit_count), 0) AS vibe_submit_count,
         COALESCE(SUM(dd.account_event_count), 0) AS account_event_count
       FROM analytics_device_days dd
       WHERE dd.day >= ?
         AND ${analyticsDeviceFilter}
       GROUP BY dd.day
       ORDER BY dd.day ASC`
    )
      .bind(sinceWindow)
      .all<AnalyticsDailyRow>(),
    env.DB.prepare(
      `SELECT
         substr(created_at, 1, 10) AS day,
         COUNT(*) AS vibe_submissions,
         COUNT(DISTINCT anonymous_user_id) AS unique_vibers,
         COUNT(DISTINCT place_id) AS vibed_places
       FROM vibe_events ve
       WHERE ${activeEventWhere("ve")}
         AND ${anonymousUserFilter}
         AND substr(ve.created_at, 1, 10) >= ?
       GROUP BY substr(created_at, 1, 10)
       ORDER BY day ASC`
    )
      .bind(sinceWindow)
      .all<VibeHistoryDailyRow>(),
    env.DB.prepare(
      `SELECT ae.event_name AS name, COUNT(*) AS count
       FROM analytics_events ae
       WHERE ae.day >= ?
         AND ${analyticsEventsFilter}
       GROUP BY ae.event_name
       ORDER BY count DESC, event_name ASC
       LIMIT 12`
    )
      .bind(sinceWindow)
      .all<AnalyticsNameCountRow>(),
    env.DB.prepare(
      `SELECT COALESCE(dd.app_version, 'Unknown') AS name, COUNT(DISTINCT dd.analytics_device_id) AS count
       FROM analytics_device_days dd
       WHERE dd.day >= ?
         AND ${analyticsDeviceFilter}
       GROUP BY COALESCE(dd.app_version, 'Unknown')
       ORDER BY count DESC, name ASC
       LIMIT 12`
    )
      .bind(sinceWindow)
      .all<AnalyticsNameCountRow>(),
    env.DB.prepare(
      `SELECT
         dl.id,
         dl.identity_type,
         dl.identity_id,
         dl.label,
         dl.category,
         dl.excluded_from_core_metrics,
         dl.notes,
         dl.created_at,
         dl.updated_at,
         ad.event_count AS analytics_event_count,
         ad.vibe_submit_count AS analytics_vibe_submit_count,
         CASE WHEN dl.identity_type = 'anonymous_user' THEN (
           SELECT COUNT(*)
           FROM vibe_events ve
           WHERE ve.anonymous_user_id = dl.identity_id
             AND ${activeEventWhere("ve")}
         ) ELSE 0 END AS historical_vibe_count,
         CASE
           WHEN dl.identity_type = 'analytics_device' THEN ad.last_seen_at
           WHEN dl.identity_type = 'anonymous_user' THEN (
             SELECT MAX(ve.updated_at)
             FROM vibe_events ve
             WHERE ve.anonymous_user_id = dl.identity_id
               AND ${activeEventWhere("ve")}
           )
           ELSE NULL
         END AS last_seen_at
       FROM admin_device_labels dl
       LEFT JOIN analytics_devices ad
         ON dl.identity_type = 'analytics_device'
        AND ad.analytics_device_id = dl.identity_id
       ORDER BY dl.excluded_from_core_metrics DESC, dl.category ASC, dl.label ASC
       LIMIT 80`
    ).all<AdminDeviceLabelRow>(),
    env.DB.prepare(
      `SELECT
         'analytics_device' AS identity_type,
         ad.analytics_device_id AS identity_id,
         dl.label,
         dl.category,
         dl.excluded_from_core_metrics,
         ad.event_count,
         ad.vibe_submit_count,
         0 AS historical_vibe_count,
         ad.first_seen_at,
         ad.last_seen_at,
         ad.app_version
       FROM analytics_devices ad
       LEFT JOIN admin_device_labels dl
         ON dl.identity_type = 'analytics_device'
        AND dl.identity_id = ad.analytics_device_id
       WHERE dl.identity_id IS NULL
         AND NOT EXISTS (
           SELECT 1
           FROM device_identity_links dil
           JOIN admin_device_labels linked_dl
             ON linked_dl.identity_type = 'anonymous_user'
            AND linked_dl.identity_id = dil.anonymous_user_id
            AND linked_dl.excluded_from_core_metrics = 1
           WHERE dil.analytics_device_id = ad.analytics_device_id
         )
       ORDER BY ad.last_seen_at DESC
       LIMIT 10`
    ).all<AdminRecentDeviceRow>(),
    env.DB.prepare(
      `SELECT
         'anonymous_user' AS identity_type,
         ve.anonymous_user_id AS identity_id,
         dl.label,
         dl.category,
         dl.excluded_from_core_metrics,
         0 AS event_count,
         0 AS vibe_submit_count,
         COUNT(*) AS historical_vibe_count,
         MIN(ve.created_at) AS first_seen_at,
         MAX(ve.updated_at) AS last_seen_at,
         COALESCE(MAX(ve.app_version), 'Unknown') AS app_version
       FROM vibe_events ve
       LEFT JOIN admin_device_labels dl
         ON dl.identity_type = 'anonymous_user'
        AND dl.identity_id = ve.anonymous_user_id
       WHERE ${activeEventWhere("ve")}
         AND dl.identity_id IS NULL
         AND NOT EXISTS (
           SELECT 1
           FROM device_identity_links dil
           JOIN admin_device_labels linked_dl
             ON linked_dl.identity_type = 'analytics_device'
            AND linked_dl.identity_id = dil.analytics_device_id
            AND linked_dl.excluded_from_core_metrics = 1
           WHERE dil.anonymous_user_id = ve.anonymous_user_id
         )
         AND NOT EXISTS (
           SELECT 1
           FROM device_identity_links dil
           WHERE dil.anonymous_user_id = ve.anonymous_user_id
         )
       GROUP BY ve.anonymous_user_id
       ORDER BY MAX(ve.updated_at) DESC
       LIMIT 10`
    ).all<AdminRecentDeviceRow>(),
  ]);

  const active30d = rolling24Hours?.activeDevices ?? rowNumber(summary?.active_30d);
  const historicalVibes30d = rolling24Hours?.vibeSubmissions ?? rowNumber(contentTotals?.vibes_30d);
  const historicalVibers30d = rolling24Hours?.uniqueVibers ?? rowNumber(contentTotals?.anonymous_vibers_30d);
  const repeatDevices30d = rowNumber(usageDepth?.repeat_devices);
  const measuredActiveDevices30d = rolling24Hours?.activeDevices ?? rowNumber(usageDepth?.active_devices);

  return {
    generatedAt: new Date().toISOString(),
    filters: {
      includeInternal: options.includeInternal,
      excludedLabelsActive: !options.includeInternal,
      days: windowDays,
      since: rolling24Hours?.since ?? sinceWindow,
      through: rolling24Hours?.through ?? today,
      timeZone: "America/Chicago",
    },
    summary: {
      activeToday: rolling24Hours?.activeDevices ?? rowNumber(summary?.active_today),
      active7d: rowNumber(summary?.active_7d),
      active30d,
      newDevices30d: rolling24Hours?.newDevices ?? rowNumber(newDevices?.new_devices_30d),
      previousActive30d: rolling24Hours?.previousActiveDevices ?? rowNumber(previousPeriod?.active_devices),
      previousNewDevices30d: rolling24Hours?.previousNewDevices ?? rowNumber(previousPeriod?.new_devices),
      previousAppOpens30d: rolling24Hours?.previousAppOpens ?? rowNumber(previousPeriod?.app_opens),
      previousSearches30d: rolling24Hours?.previousSearches ?? rowNumber(previousPeriod?.searches),
      previousPlaceSelections30d: rolling24Hours?.previousPlaceSelections ?? rowNumber(previousPeriod?.place_selects),
      excludedAnalyticsDevices30d: rolling24Hours?.excludedAnalyticsDevices
        ?? rowNumber(excludedSummary?.excluded_analytics_devices_30d),
      excludedHistoricalVibers30d: rolling24Hours?.excludedHistoricalVibers
        ?? rowNumber(excludedSummary?.excluded_historical_vibers_30d),
      excludedHistoricalVibes30d: rolling24Hours?.excludedHistoricalVibes
        ?? rowNumber(excludedSummary?.excluded_historical_vibes_30d),
      events30d: rolling24Hours?.events ?? rowNumber(summary?.events_30d),
      appOpens30d: rolling24Hours?.appOpens ?? rowNumber(summary?.app_opens_30d),
      searches30d: rolling24Hours?.searches ?? rowNumber(summary?.searches_30d),
      placeSelections30d: rolling24Hours?.placeSelections ?? rowNumber(summary?.place_selects_30d),
      vibeSubmissions30d: historicalVibes30d,
      trackedVibeSubmissions30d: rolling24Hours?.trackedVibeSubmissions ?? rowNumber(summary?.vibes_30d),
      accountEvents30d: rolling24Hours?.accountEvents ?? rowNumber(summary?.account_events_30d),
      oneDayDevices30d: rowNumber(usageDepth?.one_day_devices),
      repeatDevices30d,
      loyalDevices30d: rowNumber(usageDepth?.loyal_devices),
      repeatDeviceRate30d: measuredActiveDevices30d > 0 ? Math.round((repeatDevices30d / measuredActiveDevices30d) * 1000) / 10 : 0,
      activeDaysPerDevice30d: measuredActiveDevices30d > 0
        ? Math.round((rowNumber(usageDepth?.active_device_days) / measuredActiveDevices30d) * 100) / 100
        : 0,
      vibesPerDevice30d: historicalVibers30d > 0 ? Math.round((historicalVibes30d / historicalVibers30d) * 100) / 100 : 0,
      vibesPerActiveDevice30d: active30d > 0 ? Math.round((historicalVibes30d / active30d) * 100) / 100 : 0,
      previousVibes30d: rolling24Hours?.previousVibeSubmissions ?? rowNumber(contentTotals?.vibes_previous_30d),
      previousAnonymousVibers30d: rolling24Hours?.previousUniqueVibers
        ?? rowNumber(contentTotals?.anonymous_vibers_previous_30d),
      previousVibedPlaces30d: rolling24Hours?.previousVibedPlaces
        ?? rowNumber(contentTotals?.vibed_places_previous_30d),
      totalVibes: rowNumber(contentTotals?.total_vibes),
      totalVibedPlaces: rowNumber(contentTotals?.total_vibed_places),
      totalAnonymousVibers: rowNumber(contentTotals?.total_anonymous_vibers),
      vibedPlaces30d: rolling24Hours?.vibedPlaces ?? rowNumber(contentTotals?.vibed_places_30d),
      anonymousVibers30d: historicalVibers30d,
      onePlaceContributors30d: rolling24Hours?.onePlaceContributors ?? rowNumber(viberDepth?.one_place_contributors),
      twoToThreePlaceContributors30d: rolling24Hours?.twoToThreePlaceContributors
        ?? rowNumber(viberDepth?.two_to_three_place_contributors),
      fourPlusPlaceContributors30d: rolling24Hours?.fourPlusPlaceContributors
        ?? rowNumber(viberDepth?.four_plus_place_contributors),
      firstVibeAt: contentTotals?.first_vibe_at ?? null,
      lastVibeAt: contentTotals?.last_vibe_at ?? null,
      retention: {
        day1CohortDevices: day1Retention.cohortDevices,
        day1RetainedDevices: day1Retention.retainedDevices,
        day1Rate: day1Retention.rate,
        day7CohortDevices: day7Retention.cohortDevices,
        day7RetainedDevices: day7Retention.retainedDevices,
        day7Rate: day7Retention.rate,
      },
    },
    daily: rolling24Hours
      ? rolling24Hours.hourly.map((row) => ({
          day: row.bucketStart,
          bucketStart: row.bucketStart,
          bucketEnd: row.bucketEnd,
          activeDevices: row.activeDevices,
          newDevices: row.newDevices,
          events: row.events,
          appOpens: row.appOpens,
          searches: row.searches,
          placeSelections: row.placeSelections,
          vibeSubmissions: row.trackedVibeSubmissions,
          accountEvents: row.accountEvents,
        }))
      : fillDailyRows(today, windowDays, dailyResult.results ?? []),
    vibeHistoryDaily: rolling24Hours
      ? rolling24Hours.hourly.map((row) => ({
          day: row.bucketStart,
          bucketStart: row.bucketStart,
          bucketEnd: row.bucketEnd,
          vibeSubmissions: row.vibeSubmissions,
          uniqueVibers: row.uniqueVibers,
          vibedPlaces: row.vibedPlaces,
        }))
      : fillVibeHistoryRows(today, windowDays, vibeHistoryResult.results ?? []),
    topEvents: (rolling24Hours?.topEvents ?? eventsResult.results ?? [])
      .map((row) => ({ name: row.name ?? "unknown", count: rowNumber(row.count) })),
    appVersions: (rolling24Hours?.appVersions ?? versionsResult.results ?? [])
      .map((row) => ({ name: row.name ?? "Unknown", count: rowNumber(row.count) })),
    deviceLabels: (labelsResult.results ?? []).map(serializeAdminDeviceLabel),
    recentDevices: [...(recentAnalyticsDevices.results ?? []), ...(recentAnonymousUsers.results ?? [])].map(serializeAdminRecentDevice),
  };
}

async function fetchRetentionMetric(env: Env, days: number, since: string, through: string, options: AdminAnalyticsOptions) {
  if (through < since) {
    return { cohortDevices: 0, retainedDevices: 0, rate: null as number | null };
  }

  const analyticsDevicesFilter = adminAnalyticsDeviceAllowedSQL("d", options);
  const result = await env.DB.prepare(
    `SELECT
       COUNT(*) AS cohort_devices,
       COALESCE(SUM(CASE WHEN dd.analytics_device_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS retained_devices
     FROM analytics_devices d
     LEFT JOIN analytics_device_days dd
       ON dd.analytics_device_id = d.analytics_device_id
      AND dd.day = date(d.first_seen_day, ?)
     WHERE d.first_seen_day BETWEEN ? AND ?
       AND ${analyticsDevicesFilter}`
  )
    .bind(`+${days} day`, since, through)
    .first<AnalyticsRetentionRow>();

  const cohortDevices = rowNumber(result?.cohort_devices);
  const retainedDevices = rowNumber(result?.retained_devices);
  return {
    cohortDevices,
    retainedDevices,
    rate: cohortDevices > 0 ? Math.round((retainedDevices / cohortDevices) * 1000) / 10 : null,
  };
}

function serializeAdminDeviceLabel(row: AdminDeviceLabelRow) {
  return {
    id: row.id,
    identityType: row.identity_type,
    identityId: row.identity_id,
    label: row.label,
    category: row.category,
    excludedFromCoreMetrics: row.excluded_from_core_metrics === 1,
    notes: row.notes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    eventCount: rowNumber(row.analytics_event_count),
    vibeSubmitCount: rowNumber(row.analytics_vibe_submit_count),
    historicalVibeCount: rowNumber(row.historical_vibe_count),
    lastSeenAt: row.last_seen_at,
  };
}

function serializeAdminRecentDevice(row: AdminRecentDeviceRow) {
  return {
    identityType: row.identity_type,
    identityId: row.identity_id,
    label: row.label,
    category: row.category,
    excludedFromCoreMetrics: row.excluded_from_core_metrics === 1,
    eventCount: rowNumber(row.event_count),
    vibeSubmitCount: rowNumber(row.vibe_submit_count),
    historicalVibeCount: rowNumber(row.historical_vibe_count),
    firstSeenAt: row.first_seen_at,
    lastSeenAt: row.last_seen_at,
    appVersion: row.app_version,
  };
}

async function upsertAdminDeviceLabel(request: Request, env: Env): Promise<Response> {
  const body = await readJson<AdminDeviceLabelInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400, headers: adminJSONHeaders() });
  }

  const identityType = normalizeAdminDeviceLabelIdentityType(body.value.identity_type ?? body.value.identityType);
  if (!identityType) {
    return json({ error: "identity_type must be analytics_device or anonymous_user." }, { status: 400, headers: adminJSONHeaders() });
  }

  const identityID = cleanString(body.value.identity_id ?? body.value.identityId);
  if (!identityID || !isValidAdminDeviceIdentityID(identityType, identityID)) {
    return json({ error: "identity_id is not valid for that identity_type." }, { status: 400, headers: adminJSONHeaders() });
  }

  const label = cleanString(body.value.label);
  if (!label || label.length > 80) {
    return json({ error: "label is required and must be 80 characters or fewer." }, { status: 400, headers: adminJSONHeaders() });
  }

  const category = normalizeAdminDeviceLabelCategory(body.value.category) ?? "internal";
  const excluded = booleanFromUnknown(body.value.excluded_from_core_metrics ?? body.value.excludedFromCoreMetrics, true) ? 1 : 0;
  const notes = cleanString(body.value.notes)?.slice(0, 240) ?? null;
  const now = new Date().toISOString();
  const id = `label_${(await sha256Hex(`admin-device-label:${identityType}:${identityID}`)).slice(0, 32)}`;

  await env.DB.prepare(
    `INSERT INTO admin_device_labels (
       id,
       identity_type,
       identity_id,
       label,
       category,
       excluded_from_core_metrics,
       notes,
       created_at,
       updated_at
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(identity_type, identity_id) DO UPDATE SET
       label = excluded.label,
       category = excluded.category,
       excluded_from_core_metrics = excluded.excluded_from_core_metrics,
       notes = excluded.notes,
       updated_at = excluded.updated_at`
  )
    .bind(id, identityType, identityID, label, category, excluded, notes, now, now)
    .run();

  return json(
    {
      label: {
        id,
        identityType,
        identityId: identityID,
        label,
        category,
        excludedFromCoreMetrics: excluded === 1,
        notes,
        updatedAt: now,
      },
    },
    { headers: adminJSONHeaders() }
  );
}

function normalizeAdminDeviceLabelIdentityType(value: unknown): AdminDeviceLabelIdentityType | null {
  const normalized = cleanString(value)?.toLowerCase();
  return (ADMIN_DEVICE_LABEL_IDENTITY_TYPES as readonly string[]).includes(normalized ?? "")
    ? (normalized as AdminDeviceLabelIdentityType)
    : null;
}

function normalizeAdminDeviceLabelCategory(value: unknown): AdminDeviceLabelCategory | null {
  const normalized = cleanString(value)?.toLowerCase();
  return (ADMIN_DEVICE_LABEL_CATEGORIES as readonly string[]).includes(normalized ?? "")
    ? (normalized as AdminDeviceLabelCategory)
    : null;
}

function isValidAdminDeviceIdentityID(type: AdminDeviceLabelIdentityType, value: string): boolean {
  if (value.length > 128 || /[\s"'<>]/.test(value)) {
    return false;
  }

  if (type === "analytics_device") {
    return /^analytics_[a-f0-9]{20,64}$/.test(value);
  }

  return /^anon_[a-f0-9]{20,64}$/.test(value);
}

function booleanFromUnknown(value: unknown, fallback: boolean): boolean {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return value !== 0;
  }

  const normalized = cleanString(value)?.toLowerCase();
  if (!normalized) {
    return fallback;
  }

  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }
  return fallback;
}

function fillDailyRows(today: string, count: number, rows: AnalyticsDailyRow[]) {
  const byDay = new Map(rows.map((row) => [row.day, row]));
  return Array.from({ length: count }, (_, index) => {
    const day = addDays(today, index - count + 1);
    const row = byDay.get(day);
    return {
      day,
      activeDevices: rowNumber(row?.active_devices),
      newDevices: rowNumber(row?.new_devices),
      events: rowNumber(row?.event_count),
      appOpens: rowNumber(row?.app_open_count),
      searches: rowNumber(row?.search_count),
      placeSelections: rowNumber(row?.place_select_count),
      vibeSubmissions: rowNumber(row?.vibe_submit_count),
      accountEvents: rowNumber(row?.account_event_count),
    };
  });
}

function fillVibeHistoryRows(today: string, count: number, rows: VibeHistoryDailyRow[]) {
  const byDay = new Map(rows.map((row) => [row.day, row]));
  return Array.from({ length: count }, (_, index) => {
    const day = addDays(today, index - count + 1);
    const row = byDay.get(day);
    return {
      day,
      vibeSubmissions: rowNumber(row?.vibe_submissions),
      uniqueVibers: rowNumber(row?.unique_vibers),
      vibedPlaces: rowNumber(row?.vibed_places),
    };
  });
}

function rowNumber(value: number | null | undefined): number {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function dayString(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addDays(day: string, offset: number): string {
  const date = new Date(`${day}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + offset);
  return dayString(date);
}

function requestSupportsCurrentTaxonomy(request: Request): boolean {
  const headerVersion = cleanString(request.headers.get(TAXONOMY_VERSION_HEADER));
  const queryVersion = cleanString(new URL(request.url).searchParams.get("taxonomy_version"));
  return headerVersion === CURRENT_TAXONOMY_VERSION_ID || queryVersion === CURRENT_TAXONOMY_VERSION_ID;
}

function isCurrentOnlyTag(tagID: VibeTagID): boolean {
  return tagID === "bougie" || tagID === "low_key";
}

function clientCompatibleTagID(tagID: VibeTagID, supportsCurrentTaxonomy: boolean): VibeTagID {
  if (supportsCurrentTaxonomy) {
    return tagID;
  }
  if (tagID === "bougie") {
    return "iconic";
  }
  if (tagID === "low_key") {
    return "worth_the_drive";
  }
  return tagID;
}

async function getVibeTags(env: Env, supportsCurrentTaxonomy: boolean): Promise<Response> {
  const tags = await fetchActiveVibeTags(env);
  return json(
    { tags: supportsCurrentTaxonomy ? tags : tags.filter((tag) => !isCurrentOnlyTag(tag.id)) },
    { headers: publicCacheHeaders(CACHE_TTL_SECONDS.vibeTaxonomy) }
  );
}

async function collectAnalyticsEvent(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const body = await readJson<AnalyticsEventInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const eventName = normalizeAnalyticsEventName(body.value.event_name ?? body.value.eventName);
  if (!eventName) {
    return json({ error: "event_name is not supported." }, { status: 400 });
  }

  const deviceIDHash = (await deviceHashFromRequest(request)) ?? (await deviceHashFromBody(body.value));
  if (!deviceIDHash) {
    return json({ status: "ignored", reason: "missing_device_id" }, { status: 202 });
  }

  const appVersion =
    cleanString(body.value.app_version ?? body.value.appVersion) ?? cleanString(request.headers.get("X-Vibe-App-Version"));
  const platform = cleanString(body.value.platform) ?? sourceFromRequest(request);
  const properties = sanitizeAnalyticsProperties(body.value.properties);

  ctx.waitUntil(
    recordAnalyticsEvent(env, {
      eventName,
      deviceIDHash,
      platform,
      appVersion,
      properties,
    })
  );

  return json({ status: "queued" }, { status: 202 });
}

async function recordAnalyticsEvent(env: Env, record: AnalyticsRecord): Promise<boolean> {
  const analyticsDeviceID = await analyticsDeviceIDForDeviceHash(env, record.deviceIDHash);
  if (!analyticsDeviceID) {
    return false;
  }

  const createdAt = record.createdAt ?? new Date().toISOString();
  const day = createdAt.slice(0, 10);
  const counters = analyticsCounters(record.eventName);
  const safePlatform = cleanString(record.platform) ?? "ios";
  const safeAppVersion = cleanString(record.appVersion);
  const propertiesJSON = JSON.stringify(record.properties);

  try {
    await env.DB.batch([
      env.DB.prepare(
        `INSERT INTO analytics_devices (
           analytics_device_id,
           first_seen_at,
           first_seen_day,
           last_seen_at,
           last_seen_day,
           platform,
           app_version,
           event_count,
           app_open_count,
           search_count,
           place_select_count,
           vibe_submit_count,
           account_event_count
         )
         VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?)
         ON CONFLICT(analytics_device_id) DO UPDATE SET
           last_seen_at = excluded.last_seen_at,
           last_seen_day = excluded.last_seen_day,
           platform = excluded.platform,
           app_version = COALESCE(excluded.app_version, analytics_devices.app_version),
           event_count = analytics_devices.event_count + 1,
           app_open_count = analytics_devices.app_open_count + excluded.app_open_count,
           search_count = analytics_devices.search_count + excluded.search_count,
           place_select_count = analytics_devices.place_select_count + excluded.place_select_count,
           vibe_submit_count = analytics_devices.vibe_submit_count + excluded.vibe_submit_count,
           account_event_count = analytics_devices.account_event_count + excluded.account_event_count`
      ).bind(
        analyticsDeviceID,
        createdAt,
        day,
        createdAt,
        day,
        safePlatform,
        safeAppVersion,
        counters.appOpen,
        counters.search,
        counters.placeSelect,
        counters.vibeSubmit,
        counters.accountEvent
      ),
      env.DB.prepare(
        `INSERT INTO analytics_device_days (
           day,
           analytics_device_id,
           first_seen_at,
           last_seen_at,
           platform,
           app_version,
           event_count,
           app_open_count,
           search_count,
           place_select_count,
           vibe_submit_count,
           account_event_count
         )
         VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?)
         ON CONFLICT(day, analytics_device_id) DO UPDATE SET
           last_seen_at = excluded.last_seen_at,
           platform = excluded.platform,
           app_version = COALESCE(excluded.app_version, analytics_device_days.app_version),
           event_count = analytics_device_days.event_count + 1,
           app_open_count = analytics_device_days.app_open_count + excluded.app_open_count,
           search_count = analytics_device_days.search_count + excluded.search_count,
           place_select_count = analytics_device_days.place_select_count + excluded.place_select_count,
           vibe_submit_count = analytics_device_days.vibe_submit_count + excluded.vibe_submit_count,
           account_event_count = analytics_device_days.account_event_count + excluded.account_event_count`
      ).bind(
        day,
        analyticsDeviceID,
        createdAt,
        createdAt,
        safePlatform,
        safeAppVersion,
        counters.appOpen,
        counters.search,
        counters.placeSelect,
        counters.vibeSubmit,
        counters.accountEvent
      ),
      env.DB.prepare(
        `INSERT INTO analytics_events (
           id,
           created_at,
           day,
           analytics_device_id,
           event_name,
           platform,
           app_version,
           properties_json
         )
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(crypto.randomUUID(), createdAt, day, analyticsDeviceID, record.eventName, safePlatform, safeAppVersion, propertiesJSON),
    ]);
    return true;
  } catch (error) {
    console.log(JSON.stringify({ message: "Analytics event write failed.", event: record.eventName, error: String(error) }));
    return false;
  }
}

async function analyticsDeviceIDForDeviceHash(env: Env, deviceIDHash: string): Promise<string | null> {
  const secret = cleanString((env as RuntimeEnv).ANALYTICS_SECRET);
  if (!secret) {
    return null;
  }

  return `analytics_${(await sha256Hex(`vibes-yall-analytics:${secret}:${deviceIDHash}`)).slice(0, 40)}`;
}

async function linkAnalyticsDeviceToAnonymousUser(
  env: Env,
  deviceIDHash: string,
  anonymousUserID: string,
  seenAt: string,
  linkSource: "vibe_submission" | "analytics_backfill" | "manual"
): Promise<void> {
  const analyticsDeviceID = await analyticsDeviceIDForDeviceHash(env, deviceIDHash);
  if (!analyticsDeviceID) {
    return;
  }

  try {
    await env.DB.prepare(
      `INSERT INTO device_identity_links (
         analytics_device_id,
         anonymous_user_id,
         link_source,
         confidence,
         event_count,
         first_seen_at,
         last_seen_at
       ) VALUES (?, ?, ?, 1.0, 1, ?, ?)
       ON CONFLICT(analytics_device_id, anonymous_user_id) DO UPDATE SET
         link_source = excluded.link_source,
         confidence = MAX(device_identity_links.confidence, excluded.confidence),
         event_count = device_identity_links.event_count + 1,
         first_seen_at = MIN(device_identity_links.first_seen_at, excluded.first_seen_at),
         last_seen_at = MAX(device_identity_links.last_seen_at, excluded.last_seen_at)`
    )
      .bind(analyticsDeviceID, anonymousUserID, linkSource, seenAt, seenAt)
      .run();
  } catch (error) {
    console.log(JSON.stringify({ message: "Device identity link write failed.", error: String(error) }));
  }
}

function analyticsCounters(eventName: AnalyticsEventName): AnalyticsCounters {
  return {
    appOpen: eventName === "app_open" ? 1 : 0,
    search: eventName === "search_performed" ? 1 : 0,
    placeSelect: eventName === "place_selected" ? 1 : 0,
    vibeSubmit: eventName === "vibe_submitted" ? 1 : 0,
    accountEvent: eventName.startsWith("account_") ? 1 : 0,
  };
}

function normalizeAnalyticsEventName(value: unknown): AnalyticsEventName | null {
  const normalized = cleanString(value)
    ?.toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");

  if (!normalized) {
    return null;
  }

  return (ANALYTICS_EVENT_NAMES as readonly string[]).includes(normalized) ? (normalized as AnalyticsEventName) : null;
}

function sanitizeAnalyticsProperties(value: unknown, extras: Record<string, string | number | boolean | null | undefined> = {}): Record<string, string> {
  const output: Record<string, string> = {};
  const append = (rawKey: string, rawValue: unknown) => {
    if (Object.keys(output).length >= MAX_ANALYTICS_PROPERTIES) {
      return;
    }

    const key = rawKey
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_]+/g, "_")
      .replace(/^_+|_+$/g, "")
      .slice(0, MAX_ANALYTICS_PROPERTY_KEY_LENGTH);

    if (!key) {
      return;
    }

    let stringValue: string | null = null;
    if (typeof rawValue === "string") {
      stringValue = rawValue;
    } else if (typeof rawValue === "number" && Number.isFinite(rawValue)) {
      stringValue = String(rawValue);
    } else if (typeof rawValue === "boolean") {
      stringValue = rawValue ? "true" : "false";
    }

    const cleanedValue = cleanString(stringValue);
    if (!cleanedValue) {
      return;
    }

    output[key] = cleanedValue.slice(0, MAX_ANALYTICS_PROPERTY_VALUE_LENGTH);
  };

  if (value && typeof value === "object" && !Array.isArray(value)) {
    for (const [key, rawValue] of Object.entries(value as Record<string, unknown>)) {
      append(key, rawValue);
    }
  }

  for (const [key, rawValue] of Object.entries(extras)) {
    append(key, rawValue);
  }

  return output;
}

async function getAccountEligibility(request: Request, env: Env): Promise<Response> {
  const deviceIDHash = await deviceHashFromRequest(request);
  if (!deviceIDHash) {
    return json({ error: "X-Vibe-Device-ID-Hash is required." }, { status: 400 });
  }

  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  const sessionProfile = await fetchProfileForSession(request, env);
  return json({
    account: await buildAccountEligibility(env, deviceIDHash, anonymousUserID, sessionProfile),
  });
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
  const redirectURL = cleanString(body.value.redirect_url ?? body.value.redirectUrl);
  const token = await createAccountEmailToken(env, profile.id, "email_confirmation", redirectURL, now);
  const confirmationURL = confirmationURLForToken(request, env, token.rawToken);
  const emailSent = await sendAccountEmail(env, email, confirmationURL, "email_confirmation");
  let responseProfile = profile;
  let sessionToken: string | null = null;
  let appURL: string | null = null;
  let autoConfirmed = false;

  if (!emailSent && shouldAutoConfirmWhenEmailUnavailable(env)) {
    sessionToken = await createProfileSession(env, profile.id, now);
    await env.DB.batch([
      env.DB.prepare("UPDATE email_confirmation_tokens SET consumed_at = ? WHERE id = ?").bind(now, token.id),
      env.DB.prepare(
        `UPDATE profiles
         SET email_verified_at = COALESCE(email_verified_at, ?),
             updated_at = ?,
             last_seen_at = ?
         WHERE id = ?`
      ).bind(now, now, now, profile.id),
    ]);

    responseProfile =
      (await env.DB.prepare("SELECT * FROM profiles WHERE id = ?").bind(profile.id).first<ProfileRow>()) ?? profile;
    appURL = deepLinkURLForAccount(env, sessionToken, redirectURL);
    autoConfirmed = true;
  }

  return json(
    {
      status: autoConfirmed ? "confirmed" : "confirmation_sent",
      email_sent: emailSent || autoConfirmed,
      app_url: appURL,
      session_token: sessionToken,
      account: {
        ...eligibility,
        profile: serializeProfile(responseProfile),
      },
      message: autoConfirmed
        ? "Your VIBES Y'ALL account is saved on this device."
        : emailSent
          ? "Check your email to confirm your VIBES Y'ALL account."
          : "We could not send that email right now. Try again in a minute.",
    },
    { status: autoConfirmed ? 200 : emailSent ? 202 : 503 }
  );
}

async function requestAccountRecovery(request: Request, env: Env): Promise<Response> {
  const body = await readJson<AccountRecoveryInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const email = normalizeEmail(body.value.email);
  if (!email) {
    return json({ error: "A valid email address is required." }, { status: 400 });
  }

  const genericResponse = {
    status: "recovery_sent",
    email_sent: true,
    message: "If that email has a VIBES Y'ALL account, a sign-in link is on the way.",
  };

  const profile = await env.DB.prepare("SELECT * FROM profiles WHERE email_normalized = ? LIMIT 1")
    .bind(email)
    .first<ProfileRow>();

  if (!profile) {
    return json(genericResponse, { status: 202 });
  }

  const now = new Date().toISOString();
  const redirectURL = cleanString(body.value.redirect_url ?? body.value.redirectUrl);
  const token = await createAccountEmailToken(env, profile.id, "login", redirectURL, now);
  const loginURL = confirmationURLForToken(request, env, token.rawToken);
  const emailSent = await sendAccountEmail(env, email, loginURL, "login");

  if (!emailSent) {
    return json(
      {
        status: "email_delivery_failed",
        email_sent: false,
        message: "We could not send that email right now. Try again in a minute.",
      },
      { status: 503 }
    );
  }

  return json(genericResponse, { status: 202 });
}

async function requestAccountLogout(request: Request, env: Env): Promise<Response> {
  const tokenHash = await profileSessionTokenHashFromRequest(request);
  if (!tokenHash) {
    return json({
      status: "logged_out",
      revoked: false,
      message: "You are logged out on this device.",
    });
  }

  const now = new Date().toISOString();
  const result = await env.DB.prepare(
    `UPDATE profile_sessions
     SET revoked_at = COALESCE(revoked_at, ?),
         last_seen_at = ?
     WHERE token_hash = ?
       AND revoked_at IS NULL`
  )
    .bind(now, now, tokenHash)
    .run();

  return json({
    status: "logged_out",
    revoked: Number(result.meta.changes ?? 0) > 0,
    message: "You are logged out on this device.",
  });
}

async function requestAccountDeletion(request: Request, env: Env): Promise<Response> {
  const body = await readJson<AccountDeletionInput>(request);
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

  const profile = await env.DB.prepare(
    `SELECT p.*
     FROM profiles p
     JOIN profile_devices pd ON pd.profile_id = p.id
     WHERE p.email_normalized = ? AND pd.device_id_hash = ?
     LIMIT 1`
  )
    .bind(email, deviceIDHash)
    .first<ProfileRow>();

  if (profile) {
    await env.DB.batch([
      env.DB.prepare("DELETE FROM profile_sessions WHERE profile_id = ?").bind(profile.id),
      env.DB.prepare("DELETE FROM email_confirmation_tokens WHERE profile_id = ?").bind(profile.id),
      env.DB.prepare("DELETE FROM profile_devices WHERE profile_id = ?").bind(profile.id),
      env.DB.prepare("DELETE FROM profiles WHERE id = ?").bind(profile.id),
    ]);
  }

  return json({
    status: "deleted",
    deleted: Boolean(profile),
    message: "If an account matched this email and device, it has been deleted.",
  });
}

async function createAccountEmailToken(
  env: Env,
  profileID: string,
  purpose: AccountEmailPurpose,
  redirectURL: string | null | undefined,
  now: string
): Promise<{ id: string; rawToken: string }> {
  const rawToken = await randomToken();
  const tokenHash = await sha256Hex(`vibes-yall-email-token:${rawToken}`);
  const id = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + EMAIL_CONFIRMATION_TTL_MS).toISOString();

  await env.DB.prepare(
    `INSERT INTO email_confirmation_tokens (id, profile_id, token_hash, purpose, redirect_url, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(id, profileID, tokenHash, purpose, redirectURL ?? null, expiresAt, now)
    .run();

  return { id, rawToken };
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
       ect.purpose,
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
  const rawSessionToken = await createProfileSession(env, row.profile_id, now);

  await env.DB.batch([
    env.DB.prepare("UPDATE email_confirmation_tokens SET consumed_at = ? WHERE id = ?").bind(now, row.id),
    env.DB.prepare(
      `UPDATE profiles
       SET email_verified_at = COALESCE(email_verified_at, ?),
           updated_at = ?,
           last_seen_at = ?
       WHERE id = ?`
    ).bind(now, now, now, row.profile_id),
  ]);

  const appURL = deepLinkURLForAccount(env, rawSessionToken, row.redirect_url);
  const message = row.purpose === "login" ? "You are signed in." : "Your account is confirmed.";
  return accountResultPage(message, true, env, appURL);
}

async function appReviewLogin(request: Request, env: Env): Promise<Response> {
  const configuredEmail = normalizeEmail((env as RuntimeEnv).APP_REVIEW_EMAIL);
  const configuredPassword = cleanString((env as RuntimeEnv).APP_REVIEW_PASSWORD);
  if (!configuredEmail || !configuredPassword) {
    return json({ error: "App Review login is not configured." }, { status: 404 });
  }

  const form = await request.formData();
  const email = normalizeEmail(form.get("email"));
  const password = cleanString(form.get("password"));
  if (!timingSafeStringEqual(email, configuredEmail) || !timingSafeStringEqual(password, configuredPassword)) {
    return appReviewLoginPage(env, "The App Review username or password was not accepted.", 401);
  }

  const now = new Date().toISOString();
  const deviceIDHash = await sha256Hex(`vibes-yall-device:app-review:${configuredEmail}`);
  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  await upsertAnonymousUser(env, anonymousUserID, deviceIDHash, now);

  const profile = await upsertProfileForEmailAndDevice(env, configuredEmail, deviceIDHash, anonymousUserID, now);
  await env.DB.prepare(
    `UPDATE profiles
     SET email_verified_at = COALESCE(email_verified_at, ?),
         updated_at = ?,
         last_seen_at = ?
     WHERE id = ?`
  )
    .bind(now, now, now, profile.id)
    .run();

  const rawSessionToken = await createProfileSession(env, profile.id, now);
  const appURL = deepLinkURLForAccount(env, rawSessionToken, null);
  return accountResultPage("App Review account ready.", true, env, appURL);
}

async function buildAccountEligibility(
  env: Env,
  deviceIDHash: string,
  anonymousUserID: string,
  sessionProfile?: ProfileRow | null
) {
  const threshold = accountSignupThreshold(env);
  const anonymousUserIDs = await anonymousUserIDsForPrimary(env, anonymousUserID);
  const vibedPlaceCount = await countVibedPlacesForAnonymousUsers(env, anonymousUserIDs);
  const profile = sessionProfile ?? (await fetchProfileForDeviceHash(env, deviceIDHash));

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
    session_token: null,
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

async function fetchProfileForSession(request: Request, env: Env): Promise<ProfileRow | null> {
  const tokenHash = await profileSessionTokenHashFromRequest(request);
  if (!tokenHash) {
    return null;
  }

  const now = new Date().toISOString();
  const profile = await env.DB.prepare(
    `SELECT
       p.*,
       ps.id AS session_id
     FROM profile_sessions ps
     JOIN profiles p ON p.id = ps.profile_id
     WHERE ps.token_hash = ?
       AND ps.revoked_at IS NULL
       AND ps.expires_at > ?
     LIMIT 1`
  )
    .bind(tokenHash, now)
    .first<ProfileSessionRow>();

  if (!profile) {
    return null;
  }

  await env.DB.batch([
    env.DB.prepare("UPDATE profile_sessions SET last_seen_at = ? WHERE id = ?").bind(now, profile.session_id),
    env.DB.prepare("UPDATE profiles SET last_seen_at = ?, updated_at = ? WHERE id = ?").bind(now, now, profile.id),
  ]);

  return profile;
}

async function profileSessionTokenHashFromRequest(request: Request): Promise<string | null> {
  const authorization = cleanString(request.headers.get("Authorization"));
  if (!authorization?.toLowerCase().startsWith("bearer ")) {
    return null;
  }

  const sessionToken = cleanString(authorization.slice("bearer ".length));
  if (!sessionToken) {
    return null;
  }

  return sha256Hex(`vibes-yall-profile-session:${sessionToken}`);
}

async function createProfileSession(env: Env, profileID: string, now: string): Promise<string> {
  const rawSessionToken = await randomToken();
  const sessionHash = await sha256Hex(`vibes-yall-profile-session:${rawSessionToken}`);
  const sessionID = crypto.randomUUID();
  const sessionExpiresAt = new Date(Date.now() + PROFILE_SESSION_TTL_MS).toISOString();

  await env.DB.prepare(
    `INSERT INTO profile_sessions (id, profile_id, token_hash, created_at, expires_at, last_seen_at)
     VALUES (?, ?, ?, ?, ?, ?)`
  )
    .bind(sessionID, profileID, sessionHash, now, sessionExpiresAt, now)
    .run();

  return rawSessionToken;
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

function shouldAutoConfirmWhenEmailUnavailable(env: Env): boolean {
  return cleanString((env as RuntimeEnv).ACCOUNT_AUTO_CONFIRM_IF_EMAIL_UNAVAILABLE)?.toLowerCase() === "true";
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

async function sendAccountEmail(env: Env, email: string, actionURL: string, purpose: AccountEmailPurpose): Promise<boolean> {
  const runtimeEnv = env as RuntimeEnv;
  const sender = runtimeEnv.SIGNUP_EMAIL;
  const configuredFrom = cleanString(runtimeEnv.ACCOUNT_EMAIL_FROM);
  const from =
    configuredFrom && configuredFrom.toLowerCase().endsWith("@vibesyall.com")
      ? configuredFrom
      : ACCOUNT_CONFIRMATION_FROM_EMAIL;

  if (!sender) {
    console.log(JSON.stringify({ message: "Account email sender is not configured." }));
    return false;
  }

  const isLogin = purpose === "login";
  const subject = isLogin ? "Sign in to VIBES Y'ALL" : "Confirm your VIBES Y'ALL account";
  const intro = isLogin ? "Use this link to sign in to VIBES Y'ALL:" : "Confirm your VIBES Y'ALL account:";
  const cta = isLogin ? "Sign in" : "Confirm account";
  const detail = isLogin
    ? "This link lets you get back to your saved vibes and edit your past picks."
    : "This keeps your past and future vibes tied to you when you switch devices.";

  try {
    await sender.send({
      from: { email: from, name: "VIBES Y'ALL" },
      replyTo: SUPPORT_EMAIL,
      to: email,
      subject,
      text: [
        intro,
        actionURL,
        "",
        detail,
      ].join("\n"),
      html: `
        <p>${escapeHTML(intro)}</p>
        <p><a href="${escapeHTML(actionURL)}">${escapeHTML(cta)}</a></p>
        <p>${escapeHTML(detail)}</p>
      `,
    });
    return true;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.log(JSON.stringify({ message: "Account email send failed.", purpose, error: message }));
    return false;
  }
}

async function randomToken(): Promise<string> {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function faviconLinks(): string {
  return `<link rel="icon" type="image/png" sizes="32x32" href="${escapeHTML(LANDING_ASSETS.favicon32)}">
  <link rel="apple-touch-icon" href="${escapeHTML(LANDING_ASSETS.appleTouchIcon)}">`;
}

function landingPage(request: Request, env: Env): Response {
  const appStoreURL = cleanString((env as RuntimeEnv).APP_STORE_URL) ?? LIVE_APP_STORE_URL;
  const privacyURL = new URL("/privacy", request.url).toString();
  const termsURL = new URL("/terms", request.url).toString();
  const supportURL = new URL("/support", request.url).toString();
  const screenshots = LANDING_ASSETS.screenshots
    .filter((screenshot) => {
      const alt = screenshot.alt.toLowerCase();
      return alt.includes("selected vibes") || alt.includes("vibe picker") || alt.includes("clustered vibe map");
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
  ${faviconLinks()}
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
        <a class="app-store-badge" href="${escapeHTML(appStoreURL)}" aria-label="Download on the App Store">
          <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store">
        </a>
      </div>
    </section>
    ${screenshotsSection}
  </main>
  <section class="features">
    <article><strong>Easier to understand than 4.1 stars</strong><span>Clean human labels instead of messy written reviews.</span></article>
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
      "We collect first-party anonymous product analytics, such as app opens, search result counts, place selections, and vibe submission counts. We do not store raw search text, use advertising identifiers, sell analytics data, or track you across other apps or websites.",
      "Public app responses show aggregate place vibe data. Raw vibe events, anonymous user ids, device hashes, and email addresses are not public.",
      "Optional accounts can be deleted from the in-app menu, or by contacting support if you need help.",
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
  ${faviconLinks()}
  <style>${landingCSS()}</style>
</head>
<body>
  <main class="document support">
    <a class="back" href="/">VIBES Y'ALL</a>
    <h1>Support</h1>
    <p class="updated">Need help with VIBES Y'ALL?</p>
    <p>Email us for app support, account help, account deletion, place corrections, privacy questions, or TestFlight feedback.</p>
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
  ${faviconLinks()}
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
  const appStoreURL = cleanString((env as RuntimeEnv).APP_STORE_URL) ?? LIVE_APP_STORE_URL;
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${success ? "Account confirmed" : "Account link issue"} | VIBES Y'ALL</title>
  ${faviconLinks()}
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

function appReviewLoginPage(env: Env, error?: string, status = 200): Response {
  const configuredEmail = normalizeEmail((env as RuntimeEnv).APP_REVIEW_EMAIL);
  return html(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>App Review Login | VIBES Y'ALL</title>
  ${faviconLinks()}
  <style>${landingCSS()}
    .review-form {
      display: grid;
      gap: 1rem;
      margin-top: 1.5rem;
      text-align: left;
    }
    .review-form label {
      display: grid;
      gap: 0.45rem;
      color: var(--muted);
      font-size: 0.95rem;
      font-weight: 800;
    }
    .review-form input {
      width: 100%;
      border: 1px solid var(--line);
      border-radius: 1rem;
      background: rgba(255, 255, 255, 0.76);
      color: var(--ink);
      font: inherit;
      font-size: 1rem;
      padding: 0.95rem 1rem;
      outline: none;
    }
    .review-form input:focus {
      border-color: var(--navy);
      box-shadow: 0 0 0 0.2rem rgba(16, 44, 107, 0.12);
    }
    .review-error {
      border-radius: 1rem;
      background: rgba(231, 76, 60, 0.1);
      color: #9f2f27;
      font-weight: 800;
      padding: 0.85rem 1rem;
    }
    .review-note {
      color: var(--muted);
      font-size: 0.98rem;
      line-height: 1.45;
    }
  </style>
</head>
<body>
  <main class="document center">
    <div class="brand small">VIBES<br>Y'ALL</div>
    <h1>App Review Login</h1>
    <p class="review-note">Use the reviewer credentials from App Store Connect to create a verified test account, then open the app from this device.</p>
    ${error ? `<div class="review-error">${escapeHTML(error)}</div>` : ""}
    <form class="review-form" method="post" action="/account/review-login">
      <label>
        Email
        <input name="email" type="email" autocomplete="username" value="${escapeHTML(configuredEmail ?? "")}" required>
      </label>
      <label>
        Password
        <input name="password" type="password" autocomplete="current-password" required>
      </label>
      <button class="button primary" type="submit">Create review session</button>
    </form>
  </main>
</body>
</html>`, { status });
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
    .app-store-badge {
      display: inline-flex;
      align-items: center;
      width: 12.5rem;
      line-height: 0;
    }
    .app-store-badge img {
      display: block;
      width: 100%;
      height: auto;
    }
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
            p.primary_category,
            p.provider_category,
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
  const supportsV2 = requestSupportsCurrentTaxonomy(request);
  const places = entries.map((entry) =>
    serializeNearbyPlace(entry.row, entry.distance, eventByPlaceID.get(entry.row.id) ?? null, supportsV2)
  );

  return json({ places }, deviceIDHash ? undefined : { headers: publicCacheHeaders(CACHE_TTL_SECONDS.nearby) });
}

async function getPlaceMapCells(request: Request, url: URL, env: Env): Promise<Response> {
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
    cellSize,
    requestSupportsCurrentTaxonomy(request)
  )
    .slice(0, MAX_MAP_CELL_RESPONSE_CELLS);

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
  return json({ place: await serializePlace(place, undefined, env, deviceIDHash, requestSupportsCurrentTaxonomy(request)) });
}

const SAVED_PLACE_BROAD_SEARCH_TOKENS = new Set([
  "atm", "asian", "bakery", "bar", "bars", "bbq", "breakfast", "brewery", "burger", "burgers",
  "cafe", "cafes", "cajun", "chinese", "coffee", "dinner", "drink", "drinks", "entertainment",
  "food", "gas", "grocery", "groceries", "gym", "hotel", "hotels", "italian", "lunch", "mexican",
  "movie", "movies", "museum", "museums", "park", "parks", "pharmacy", "pizza", "restaurant",
  "restaurants", "shop", "shopping", "shops", "store", "stores", "taco", "tacos", "theater", "theatre",
]);

function normalizedPlaceNameTokens(value: string): string[] {
  return value
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/gu, "")
    .toLowerCase()
    .replace(/['’]s\b/gu, "")
    .split(/[^a-z0-9]+/u)
    .filter(Boolean);
}

function placeNameMatchTier(query: string, candidateName: string): number | null {
  const queryTokens = normalizedPlaceNameTokens(query);
  const candidateTokens = normalizedPlaceNameTokens(candidateName);
  if (queryTokens.length < 2 || candidateTokens.length < queryTokens.length) return null;
  if (queryTokens.every((token, index) => token === candidateTokens[index]) && queryTokens.length === candidateTokens.length) return 0;
  if (queryTokens.every((token, index) => token === candidateTokens[index])) return 1;
  if (queryTokens.every((token, index) => {
    const candidateToken = candidateTokens[index];
    if (!candidateToken) return false;
    if (token.length <= 2 && (index < queryTokens.length - 1 || queryTokens.length === 2)) {
      return candidateToken === token;
    }
    return candidateToken.startsWith(token);
  })) return 2;
  if (queryTokens.every((token) => token.length >= 3 && candidateTokens.includes(token))) return 3;
  return null;
}

function isSpecificSavedPlaceNameQuery(query: string): boolean {
  const tokens = normalizedPlaceNameTokens(query);
  const isBroad = tokens.length > 0 && tokens.every((token) =>
    SAVED_PLACE_BROAD_SEARCH_TOKENS.has(token) ||
    (token.endsWith("s") && SAVED_PLACE_BROAD_SEARCH_TOKENS.has(token.slice(0, -1)))
  );
  return tokens.length >= 2 && !isBroad && !/\d/u.test(query);
}

async function searchSavedPlaces(request: Request, url: URL, env: Env): Promise<Response> {
  const query = cleanString(url.searchParams.get("q") ?? url.searchParams.get("query"));
  const latitude = numberParam(url, "lat");
  const longitude = numberParam(url, "lng");
  const rawLimit = numberParam(url, "limit") ?? 12;
  const limit = Math.max(1, Math.min(Math.floor(rawLimit), 20));

  if (!query || query.length < 2) {
    return json({ places: [] });
  }
  if ((latitude === null) !== (longitude === null)) {
    return json({ error: "lat and lng must be supplied together." }, { status: 400 });
  }
  if (latitude !== null && longitude !== null && !isValidCoordinate(latitude, longitude)) {
    return json({ error: "lat or lng is out of range." }, { status: 400 });
  }

  const tokens = normalizedPlaceNameTokens(query).slice(0, 6);
  if (tokens.length === 0) {
    return json({ places: [] });
  }

  const isSpecificNameSearch = isSpecificSavedPlaceNameQuery(query);
  const searchableText =
    "LOWER(p.name || ' ' || COALESCE(p.street_address, '') || ' ' || COALESCE(p.city, '') || ' ' || COALESCE(p.region, ''))";
  const matchClause = isSpecificNameSearch
    ? "LOWER(p.name) LIKE ?"
    : tokens.map(() => `${searchableText} LIKE ?`).join(" AND ");
  const candidateLimit = isSpecificNameSearch ? Math.max(limit * 10, 100) : limit;
  const result = await env.DB.prepare(
    `SELECT p.id,
            p.provider,
            p.provider_place_id,
            p.name,
            p.latitude,
            p.longitude,
            p.street_address,
            p.category,
            p.primary_category,
            p.provider_category,
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
     WHERE pvs.total_vibes > 0
       AND ${matchClause}
     ORDER BY pvs.total_vibes DESC,
              p.name ASC
     LIMIT ?`
  )
    .bind(
      ...(isSpecificNameSearch ? [`%${tokens[0]}%`] : tokens.map((token) => `%${token}%`)),
      candidateLimit
    )
    .all<NearbyPlaceRow>();

  const rows = (result.results ?? [])
    .filter((row) => !isSpecificNameSearch || placeNameMatchTier(query, row.name) !== null)
    .sort((left, right) => {
      if (!isSpecificNameSearch) return 0;
      const tierDifference = (placeNameMatchTier(query, left.name) ?? 99) - (placeNameMatchTier(query, right.name) ?? 99);
      if (tierDifference !== 0) return tierDifference;
      if (latitude !== null && longitude !== null) {
        const distanceDifference =
          distanceMeters(latitude, longitude, left.latitude, left.longitude) -
          distanceMeters(latitude, longitude, right.latitude, right.longitude);
        if (Math.abs(distanceDifference) > 25) return distanceDifference;
      }
      if (left.stats_total_vibes !== right.stats_total_vibes) return right.stats_total_vibes - left.stats_total_vibes;
      return left.name.localeCompare(right.name);
    })
    .slice(0, limit);
  const deviceIDHash = await deviceHashFromRequest(request);
  const eventByPlaceID = deviceIDHash
    ? await fetchVibeEventsForDeviceByPlaceIDs(env, rows.map((row) => row.id), deviceIDHash)
    : new Map<string, VibeEventRow>();
  const supportsV2 = requestSupportsCurrentTaxonomy(request);
  const places = rows.map((row) => {
    const distance =
      latitude !== null && longitude !== null
        ? distanceMeters(latitude, longitude, row.latitude, row.longitude)
        : undefined;
    return serializeNearbyPlace(row, distance, eventByPlaceID.get(row.id) ?? null, supportsV2);
  });

  return json({ places });
}

async function searchProviderPlaces(url: URL, env: Env): Promise<Response> {
  const provider = cleanString(url.searchParams.get("provider")) ?? "google";
  const query = cleanString(url.searchParams.get("q") ?? url.searchParams.get("query"));
  const latitude = numberParam(url, "lat");
  const longitude = numberParam(url, "lng");
  const rawLimit = numberParam(url, "limit") ?? MAX_PROVIDER_SEARCH_RESULTS;
  const limit = Math.max(1, Math.min(Math.floor(rawLimit), MAX_PROVIDER_SEARCH_RESULTS));

  if (!query || query.length < 2) {
    return json({ candidates: [], provider: "google_places", enabled: true });
  }

  if (provider !== "google" && provider !== "google_places") {
    return json({ error: "provider must be google." }, { status: 400 });
  }

  if ((latitude === null) !== (longitude === null)) {
    return json({ error: "lat and lng must be supplied together." }, { status: 400 });
  }

  if (latitude !== null && longitude !== null && !isValidCoordinate(latitude, longitude)) {
    return json({ error: "lat or lng is out of range." }, { status: 400 });
  }

  const apiKey = cleanString((env as RuntimeEnv).GOOGLE_PLACES_API_KEY);
  if (!apiKey) {
    return json({ candidates: [], provider: "google_places", enabled: false });
  }

  const body: GooglePlaceTextSearchRequest = {
    textQuery: query,
    maxResultCount: limit,
    languageCode: "en",
    regionCode: "US",
  };

  if (latitude !== null && longitude !== null) {
    body.locationBias = {
      circle: {
        center: {
          latitude,
          longitude,
        },
        radius: 50_000,
      },
    };
  }

  const response = await fetch(GOOGLE_PLACES_TEXT_SEARCH_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask":
        "places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.primaryTypeDisplayName,places.types",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    console.warn(
      JSON.stringify({
        message: "Google provider search failed",
        status: response.status,
        statusText: response.statusText,
      })
    );
    return json({ candidates: [], provider: "google_places", enabled: true, degraded: true });
  }

  const data = (await response.json()) as GooglePlaceTextSearchResponse;
  const candidates = (data.places ?? [])
    .map((place) => googlePlaceCandidate(place, latitude, longitude))
    .filter((candidate): candidate is ProviderPlaceCandidate => candidate !== null)
    .slice(0, limit);

  return json({ candidates, provider: "google_places", enabled: true });
}

function googlePlaceCandidate(place: GooglePlace, latitude: number | null, longitude: number | null): ProviderPlaceCandidate | null {
  const providerPlaceID = cleanString(place.id);
  const name = cleanString(place.displayName?.text);
  const placeLatitude = numberValue(place.location?.latitude);
  const placeLongitude = numberValue(place.location?.longitude);

  if (!providerPlaceID || !name || placeLatitude === null || placeLongitude === null) {
    return null;
  }

  const providerCategory = googleProviderCategory(place);
  const primaryCategory = googlePrimaryCategory(place, providerCategory);

  return {
    provider: "google_places",
    provider_place_id: providerPlaceID,
    name,
    latitude: placeLatitude,
    longitude: placeLongitude,
    street_address: cleanString(place.formattedAddress),
    category: primaryCategory,
    primary_category: primaryCategory,
    provider_category: providerCategory,
    city: null,
    region: null,
    country: null,
    distance_meters:
      latitude !== null && longitude !== null ? distanceMeters(latitude, longitude, placeLatitude, placeLongitude) : null,
  };
}

function googleProviderCategory(place: GooglePlace): string | null {
  const displayName = cleanString(place.primaryTypeDisplayName?.text);
  if (displayName) {
    return displayName;
  }

  const primaryType = cleanString(place.primaryType) ?? cleanString(place.types?.[0]);
  return primaryType ? prettifyProviderType(primaryType) : null;
}

function googlePrimaryCategory(place: GooglePlace, providerCategory: string | null): string | null {
  const types = [place.primaryType, ...(place.types ?? [])]
    .map((value) => cleanString(value)?.toLowerCase())
    .filter((value): value is string => Boolean(value));
  const categoryText = providerCategory?.toLowerCase() ?? "";

  if (types.some((type) => type.includes("restaurant") || FOOD_PROVIDER_TYPES.has(type)) || categoryText.includes("restaurant")) {
    return "Restaurant";
  }
  if (types.some((type) => BAR_PROVIDER_TYPES.has(type)) || categoryText.includes("bar")) {
    return "Bar";
  }
  if (types.some((type) => ENTERTAINMENT_PROVIDER_TYPES.has(type))) {
    return "Entertainment";
  }
  if (types.some((type) => MUSEUM_PROVIDER_TYPES.has(type))) {
    return "Museum";
  }
  if (types.some((type) => PARK_PROVIDER_TYPES.has(type))) {
    return "Park";
  }
  if (types.some((type) => SHOP_PROVIDER_TYPES.has(type))) {
    return "Shop";
  }
  if (types.some((type) => HEALTH_PROVIDER_TYPES.has(type))) {
    return "Health";
  }
  if (types.some((type) => TRANSIT_PROVIDER_TYPES.has(type))) {
    return "Transit";
  }
  if (types.some((type) => GAS_PROVIDER_TYPES.has(type))) {
    return "Gas";
  }
  if (types.some((type) => type === "lodging" || type === "hotel" || type === "motel")) {
    return "Hotel";
  }
  if (types.some((type) => type === "school" || type === "university")) {
    return "School";
  }
  if (types.some((type) => type === "gym" || type === "fitness_center")) {
    return "Fitness";
  }
  if (types.some((type) => type === "stadium")) {
    return "Stadium";
  }
  if (types.some((type) => type === "library")) {
    return "Library";
  }
  if (types.some((type) => type === "bank" || type === "atm")) {
    return "Bank";
  }
  if (types.some((type) => type === "parking")) {
    return "Parking";
  }

  return providerCategory && providerCategory !== "Point Of Interest" ? providerCategory : null;
}

const FOOD_PROVIDER_TYPES = new Set([
  "bakery",
  "barbecue_restaurant",
  "cafe",
  "coffee_shop",
  "dessert_shop",
  "diner",
  "fast_food_restaurant",
  "food",
  "hamburger_restaurant",
  "ice_cream_shop",
  "meal_delivery",
  "meal_takeaway",
  "pizza_restaurant",
]);

const BAR_PROVIDER_TYPES = new Set(["bar", "night_club", "pub", "wine_bar"]);

const ENTERTAINMENT_PROVIDER_TYPES = new Set([
  "amusement_center",
  "amusement_park",
  "bowling_alley",
  "casino",
  "movie_theater",
  "performing_arts_theater",
  "theater",
  "tourist_attraction",
]);

const MUSEUM_PROVIDER_TYPES = new Set(["aquarium", "art_gallery", "museum", "zoo"]);
const PARK_PROVIDER_TYPES = new Set(["beach", "campground", "national_park", "park", "rv_park"]);

const SHOP_PROVIDER_TYPES = new Set([
  "book_store",
  "clothing_store",
  "convenience_store",
  "department_store",
  "electronics_store",
  "furniture_store",
  "grocery_store",
  "hardware_store",
  "home_goods_store",
  "jewelry_store",
  "liquor_store",
  "shopping_mall",
  "store",
]);

const HEALTH_PROVIDER_TYPES = new Set(["dentist", "doctor", "hospital", "pharmacy", "spa", "veterinary_care"]);
const TRANSIT_PROVIDER_TYPES = new Set(["airport", "bus_station", "light_rail_station", "subway_station", "train_station", "transit_station"]);
const GAS_PROVIDER_TYPES = new Set(["electric_vehicle_charging_station", "gas_station"]);

function prettifyProviderType(value: string): string {
  return value
    .replace(/_/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

function normalizePlaceCategories(
  name: string,
  legacyCategory: string | null,
  submittedPrimaryCategory: string | null,
  submittedProviderCategory: string | null
): {
  category: string | null;
  primaryCategory: string | null;
  providerCategory: string | null;
} {
  const providerCategory =
    normalizedProviderCategory(submittedProviderCategory) ?? inferredProviderCategoryFromName(name);
  const providerKey = categoryKey(providerCategory);
  let primaryCategory = submittedPrimaryCategory ?? legacyCategory;

  switch (providerKey) {
    case "movietheater":
    case "theater":
      primaryCategory = "Entertainment";
      break;
    case "musicvenue":
      primaryCategory = "Music Venue";
      break;
  }

  const primaryKey = categoryKey(primaryCategory);
  if (
    (primaryKey === "musicvenue" || primaryKey === "restaurant") &&
    (providerKey === "movietheater" || providerKey === "theater")
  ) {
    primaryCategory = "Entertainment";
  }

  return {
    category: primaryCategory ?? legacyCategory ?? providerCategory,
    primaryCategory,
    providerCategory,
  };
}

function normalizedProviderCategory(category: string | null): string | null {
  const key = categoryKey(category);
  switch (key) {
    case "cinema":
    case "movietheater":
      return "Movie Theater";
    case "theater":
      return "Theater";
    case "musicvenue":
      return "Music Venue";
    default:
      return category;
  }
}

function inferredProviderCategoryFromName(name: string): string | null {
  const normalizedName = ` ${name.toLowerCase()} `;
  if (
    normalizedName.includes(" cinem") ||
    normalizedName.includes(" movie theater ") ||
    normalizedName.includes(" movie theatre ")
  ) {
    return "Movie Theater";
  }

  return null;
}

function categoryKey(category: string | null): string {
  return (category ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
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
  const legacyCategory = cleanString(body.value.category);
  const submittedPrimaryCategory = cleanString(body.value.primary_category ?? body.value.primaryCategory) ?? legacyCategory;
  const submittedProviderCategory = cleanString(body.value.provider_category ?? body.value.providerCategory);
  const normalizedCategories = normalizePlaceCategories(name, legacyCategory, submittedPrimaryCategory, submittedProviderCategory);
  const category = normalizedCategories.category;
  const primaryCategory = normalizedCategories.primaryCategory;
  const providerCategory = normalizedCategories.providerCategory;
  const city = cleanString(body.value.city);
  const region = cleanString(body.value.region);
  const country = cleanString(body.value.country);
  const now = new Date().toISOString();
  const existingPlace = await findExistingPlaceForInput(env, provider, providerPlaceID, name, latitude, longitude);
  const id = existingPlace?.id ?? (await stablePlaceID(provider, providerPlaceID, name, latitude, longitude));

  await env.DB.prepare(
    `INSERT INTO places (
       id, provider, provider_place_id, name, latitude, longitude, street_address, city, region, country, category,
       primary_category, provider_category, created_at, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
       category = COALESCE(excluded.primary_category, excluded.category, places.category),
       primary_category = COALESCE(excluded.primary_category, excluded.category, places.primary_category, places.category),
       provider_category = COALESCE(excluded.provider_category, places.provider_category),
       updated_at = excluded.updated_at`
  )
    .bind(
      id,
      provider,
      providerPlaceID,
      name,
      latitude,
      longitude,
      streetAddress,
      city,
      region,
      country,
      category,
      primaryCategory,
      providerCategory,
      now,
      now
    )
    .run();

  await upsertPlaceExternalID(env, id, provider, providerPlaceID, now, "app_submission", 1.0);

  const place = await fetchPlaceByID(env, id);
  if (!place) {
    return json({ error: "Place could not be saved." }, { status: 500 });
  }

  return json(
    { place: await serializePlace(place, undefined, env, null, requestSupportsCurrentTaxonomy(request)) },
    { status: 201 }
  );
}

async function upsertPlaceExternalID(
  env: Env,
  placeID: string,
  provider: string,
  providerPlaceID: string | null,
  seenAt: string,
  source: string,
  confidence: number
): Promise<void> {
  if (!providerPlaceID) {
    return;
  }

  await env.DB.prepare(
    `INSERT INTO place_external_ids (
       place_id,
       provider,
       provider_place_id,
       source,
       confidence,
       first_seen_at,
       last_seen_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(provider, provider_place_id) DO UPDATE SET
       place_id = excluded.place_id,
       source = COALESCE(place_external_ids.source, excluded.source),
       confidence = MAX(place_external_ids.confidence, excluded.confidence),
       first_seen_at = MIN(place_external_ids.first_seen_at, excluded.first_seen_at),
       last_seen_at = MAX(place_external_ids.last_seen_at, excluded.last_seen_at)`
  )
    .bind(placeID, provider, providerPlaceID, source, confidence, seenAt, seenAt)
    .run();
}

function placeSnapshotForVibe(place: PlaceRow): string {
  return JSON.stringify({
    version: PLACE_SNAPSHOT_VERSION,
    place_id: place.id,
    provider: place.provider,
    provider_place_id: place.provider_place_id,
    name: place.name,
    latitude: place.latitude,
    longitude: place.longitude,
    street_address: place.street_address,
    city: place.city,
    region: place.region,
    country: place.country,
    category: place.primary_category ?? place.category,
    primary_category: place.primary_category ?? place.category,
    provider_category: place.provider_category,
    captured_at: new Date().toISOString(),
  });
}

async function upsertVibe(request: Request, env: Env, ctx?: ExecutionContext): Promise<Response> {
  const body = await readJson<VibeInput>(request);
  if (!body.ok) {
    return json({ error: body.error }, { status: 400 });
  }

  const placeID = cleanString(body.value.place_id ?? body.value.placeId);
  if (!placeID) {
    return json({ error: "place_id is required." }, { status: 400 });
  }

  const placeForSubmission = await fetchPlaceByID(env, placeID);
  if (!placeForSubmission) {
    return json({ error: "Place not found." }, { status: 404 });
  }

  const parsedTags = parseVibeTags(body.value);
  if (!parsedTags.ok) {
    return json({ error: parsedTags.error }, { status: 400 });
  }
  const supportsV2 = requestSupportsCurrentTaxonomy(request);
  if (!supportsV2 && parsedTags.tagIDs.some(isCurrentOnlyTag)) {
    return json({ error: "Update VIBES Y'ALL to use Bougie or Low-key." }, { status: 400 });
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
  const submissionContext = cleanString(body.value.submission_context ?? body.value.submissionContext) ?? source;
  const placeSnapshotJSON = placeSnapshotForVibe(placeForSubmission);

  const submissionStatement = env.DB.prepare(
    `INSERT INTO vibe_events (
       id, place_id, anonymous_user_id, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id, source, app_version,
       taxonomy_version_id, submission_context, place_snapshot_json, created_at, updated_at, is_flagged, is_deleted, moderation_status
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 'active')
     ON CONFLICT(place_id, anonymous_user_id) DO UPDATE SET
       primary_vibe_tag_id = excluded.primary_vibe_tag_id,
       secondary_vibe_tag_id = excluded.secondary_vibe_tag_id,
       third_vibe_tag_id = excluded.third_vibe_tag_id,
       source = excluded.source,
       app_version = excluded.app_version,
       taxonomy_version_id = excluded.taxonomy_version_id,
       submission_context = excluded.submission_context,
       place_snapshot_json = excluded.place_snapshot_json,
       updated_at = excluded.updated_at,
       is_deleted = 0,
       moderation_status = 'active'`
  ).bind(
      eventID,
      placeID,
      eventAnonymousUserID,
      primaryTagID,
      secondaryTagID,
      thirdTagID,
      source,
      appVersion,
      CURRENT_TAXONOMY_VERSION_ID,
      submissionContext,
      placeSnapshotJSON,
      existing?.created_at ?? now,
      now
    );

  const refreshJobStatement = env.DB.prepare(
    `INSERT INTO aggregate_refresh_jobs (
       place_id, requested_at, next_attempt_at, attempts, last_error
     ) VALUES (?, ?, ?, 0, NULL)
     ON CONFLICT(place_id) DO UPDATE SET
       requested_at = excluded.requested_at,
       next_attempt_at = excluded.next_attempt_at,
       attempts = 0,
       last_error = NULL`
  ).bind(placeID, now, now);

  // D1 batch execution is atomic: a durable vibe can never be committed without
  // a durable refresh job that can repair its derived rollups.
  await env.DB.batch([submissionStatement, refreshJobStatement]);

  await refreshImmediatePlaceVibeStats(env, placeID, now);
  await mirrorLegacyRating(env, eventID, placeID, deviceIDHash, primaryTagID, secondaryTagID, thirdTagID, existing?.created_at ?? now, now);

  if (wasFirstVibe) {
    await env.DB.prepare(
      `INSERT OR IGNORE INTO discovery_events (id, place_id, rating_id, event_type, created_at)
       VALUES (?, ?, ?, ?, ?)`
    )
      .bind(crypto.randomUUID(), placeID, eventID, "first_to_vibe", now)
      .run();
  }

  if (deviceIDHash) {
    const analyticsWrite = recordAnalyticsEvent(env, {
      eventName: "vibe_submitted",
      deviceIDHash,
      platform: source,
      appVersion,
      createdAt: now,
      properties: sanitizeAnalyticsProperties(null, {
        place_id: placeID,
        primary_vibe_tag_id: primaryTagID,
        secondary_vibe_tag_id: secondaryTagID,
        third_vibe_tag_id: thirdTagID,
        vibe_tag_count: parsedTags.tagIDs.length,
        update_type: existing ? "updated" : "created",
        was_first_vibe: wasFirstVibe,
      }),
    }).then(async () => {
      await linkAnalyticsDeviceToAnonymousUser(env, deviceIDHash, eventAnonymousUserID, now, "vibe_submission");
    });

    if (ctx) {
      ctx.waitUntil(analyticsWrite);
    } else {
      await analyticsWrite;
    }
  }

  const place = await fetchPlaceByID(env, placeID);
  const event = await fetchVibeEventForUser(env, placeID, eventAnonymousUserID);

  if (!place || !event) {
    return json({ error: "Vibe could not be saved." }, { status: 500 });
  }

  const response = json({
    place: await serializePlace(place, undefined, env, deviceIDHash, supportsV2),
    vibe_event: serializeVibeEvent(event, supportsV2),
    rating: serializeLegacyRating(event, supportsV2),
    discovery: {
      was_first_vibe: wasFirstVibe,
    },
  });

  const derivedRefresh = processAggregateRefreshJob(env, placeID);
  if (ctx) {
    ctx.waitUntil(derivedRefresh);
  } else {
    await derivedRefresh;
  }

  return response;
}

async function deleteVibe(
  request: Request,
  env: Env,
  ctx: ExecutionContext | undefined,
  placeID: string
): Promise<Response> {
  const place = await fetchPlaceByID(env, placeID);
  if (!place) {
    return json({ error: "Place not found." }, { status: 404 });
  }

  const deviceIDHash = await deviceHashFromRequest(request);
  if (!deviceIDHash) {
    return json({ error: "X-Vibe-Device-ID-Hash is required." }, { status: 400 });
  }

  const anonymousUserID = anonymousUserIDForDeviceHash(deviceIDHash);
  const candidateAnonymousUserIDs = await anonymousUserIDsForPrimary(env, anonymousUserID);
  const existing = await fetchVibeEventForUsers(env, placeID, candidateAnonymousUserIDs);
  const supportsCurrentTaxonomy = requestSupportsCurrentTaxonomy(request);

  if (!existing) {
    return json({
      deleted: false,
      place: await serializePlace(place, undefined, env, deviceIDHash, supportsCurrentTaxonomy),
    });
  }

  const now = new Date().toISOString();
  const deleteStatement = env.DB.prepare(
    `UPDATE vibe_events
     SET is_deleted = 1, updated_at = ?
     WHERE id = ? AND place_id = ? AND is_deleted = 0`
  ).bind(now, existing.id, placeID);
  const refreshJobStatement = env.DB.prepare(
    `INSERT INTO aggregate_refresh_jobs (
       place_id, requested_at, next_attempt_at, attempts, last_error
     ) VALUES (?, ?, ?, 0, NULL)
     ON CONFLICT(place_id) DO UPDATE SET
       requested_at = excluded.requested_at,
       next_attempt_at = excluded.next_attempt_at,
       attempts = 0,
       last_error = NULL`
  ).bind(placeID, now, now);
  const legacyDeleteStatement = env.DB.prepare(
    "DELETE FROM ratings WHERE id = ? OR (place_id = ? AND device_id_hash = ?)"
  ).bind(existing.id, placeID, deviceIDHash);

  // Keep the durable delete and its aggregate repair job atomic, matching submissions.
  await env.DB.batch([deleteStatement, refreshJobStatement, legacyDeleteStatement]);
  await refreshImmediatePlaceVibeStats(env, placeID, now);

  const analyticsWrite = recordAnalyticsEvent(env, {
    eventName: "vibe_deleted",
    deviceIDHash,
    platform: sourceFromRequest(request),
    appVersion: cleanString(request.headers.get("X-Vibe-App-Version")),
    createdAt: now,
    properties: sanitizeAnalyticsProperties(null, { place_id: placeID }),
  });
  const derivedRefresh = processAggregateRefreshJob(env, placeID);
  if (ctx) {
    ctx.waitUntil(Promise.all([analyticsWrite, derivedRefresh]).then(() => undefined));
  } else {
    await Promise.all([analyticsWrite, derivedRefresh]);
  }

  return json({
    deleted: true,
    place: await serializePlace(place, undefined, env, deviceIDHash, supportsCurrentTaxonomy),
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
    `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, primary_category, provider_category, city, region, country, created_at, updated_at
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
      `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, primary_category, provider_category, city, region, country, created_at, updated_at
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
    `SELECT id, provider, provider_place_id, name, latitude, longitude, street_address, category, primary_category, provider_category, city, region, country, created_at, updated_at
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
  deviceIDHash?: string | null,
  supportsV2 = false
) {
  const stats = await fetchPlaceVibeStats(env, row.id);
  const topVibes = stats && stats.total_vibes > 0
    ? await fetchTopVibes(env, row.id, stats.total_vibes, 3, stats.top_vibe_tag_id, supportsV2)
    : [];
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
    category: row.primary_category ?? row.category,
    primary_category: row.primary_category ?? row.category,
    provider_category: row.provider_category,
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
            top_vibe_tag: stats.top_vibe_tag_id
              ? legacyDisplayNameForTag(clientCompatibleTagID(stats.top_vibe_tag_id, supportsV2))
              : null,
            top_vibe_tag_id: stats.top_vibe_tag_id ? clientCompatibleTagID(stats.top_vibe_tag_id, supportsV2) : null,
            top_vibe_percent: stats.top_vibe_percent,
            second_vibe_tag_id: stats.second_vibe_tag_id ? clientCompatibleTagID(stats.second_vibe_tag_id, supportsV2) : null,
            second_vibe_percent: stats.second_vibe_percent,
            last_30_day_total_vibes: stats.last_30_day_total_vibes,
            last_30_day_top_vibe_tag_id: stats.last_30_day_top_vibe_tag_id
              ? clientCompatibleTagID(stats.last_30_day_top_vibe_tag_id, supportsV2)
              : null,
            last_30_day_top_vibe_percent: stats.last_30_day_top_vibe_percent,
            last_year_total_vibes: stats.last_year_total_vibes,
            last_year_top_vibe_tag_id: stats.last_year_top_vibe_tag_id
              ? clientCompatibleTagID(stats.last_year_top_vibe_tag_id, supportsV2)
              : null,
            last_year_top_vibe_percent: stats.last_year_top_vibe_percent,
            top_vibes: topVibes,
            recent_vibe_count: stats.last_30_day_total_vibes,
            recent_positive_percentage: recentPositivePercentage,
            updated_at: stats.updated_at,
          },
    my_rating: myEvent ? serializeLegacyRating(myEvent, supportsV2) : null,
    my_vibe_event: myEvent ? serializeVibeEvent(myEvent, supportsV2) : null,
    distance_meters: distanceMetersValue,
  };
}

function serializeNearbyPlace(
  row: NearbyPlaceRow,
  distanceMetersValue: number | undefined,
  myEvent: VibeEventRow | null,
  supportsV2: boolean
) {
  const topVibes = topVibesFromNearbyStats(row, supportsV2);
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
    category: row.primary_category ?? row.category,
    primary_category: row.primary_category ?? row.category,
    provider_category: row.provider_category,
    city: row.city,
    region: row.region,
    country: row.country,
    created_at: row.created_at,
    updated_at: row.updated_at,
    stats: {
      rating_count: row.stats_total_vibes,
      total_vibes: row.stats_total_vibes,
      average_score: averageScoreForStats(topVibes),
      top_vibe_tag: row.stats_top_vibe_tag_id
        ? legacyDisplayNameForTag(clientCompatibleTagID(row.stats_top_vibe_tag_id, supportsV2))
        : null,
      top_vibe_tag_id: row.stats_top_vibe_tag_id ? clientCompatibleTagID(row.stats_top_vibe_tag_id, supportsV2) : null,
      top_vibe_percent: row.stats_top_vibe_percent,
      second_vibe_tag_id: row.stats_second_vibe_tag_id
        ? clientCompatibleTagID(row.stats_second_vibe_tag_id, supportsV2)
        : null,
      second_vibe_percent: row.stats_second_vibe_percent,
      last_30_day_total_vibes: row.stats_last_30_day_total_vibes,
      last_30_day_top_vibe_tag_id: row.stats_last_30_day_top_vibe_tag_id
        ? clientCompatibleTagID(row.stats_last_30_day_top_vibe_tag_id, supportsV2)
        : null,
      last_30_day_top_vibe_percent: row.stats_last_30_day_top_vibe_percent,
      last_year_total_vibes: row.stats_last_year_total_vibes,
      last_year_top_vibe_tag_id: row.stats_last_year_top_vibe_tag_id
        ? clientCompatibleTagID(row.stats_last_year_top_vibe_tag_id, supportsV2)
        : null,
      last_year_top_vibe_percent: row.stats_last_year_top_vibe_percent,
      top_vibes: topVibes,
      recent_vibe_count: row.stats_last_30_day_total_vibes,
      recent_positive_percentage: recentPositivePercentage,
      updated_at: row.stats_updated_at,
    },
    my_rating: myEvent ? serializeLegacyRating(myEvent, supportsV2) : null,
    my_vibe_event: myEvent ? serializeVibeEvent(myEvent, supportsV2) : null,
    distance_meters: distanceMetersValue,
  };
}

function aggregateMapCells(rows: MapCellPlaceRow[], cellSizeMeters: number, supportsV2: boolean) {
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
    addMapCellTagCount(cell.tagCounts, row.stats_top_vibe_tag_id, row.stats_top_vibe_percent, row.stats_total_vibes, supportsV2);
    addMapCellTagCount(cell.tagCounts, row.stats_second_vibe_tag_id, row.stats_second_vibe_percent, row.stats_total_vibes, supportsV2);
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
  totalVibes: number,
  supportsV2: boolean
): void {
  if (!tagID || percentage === null || percentage <= 0 || totalVibes <= 0) {
    return;
  }

  const compatibleTagID = clientCompatibleTagID(tagID, supportsV2);
  counts.set(
    compatibleTagID,
    (counts.get(compatibleTagID) ?? 0) + Math.max(1, Math.round((totalVibes * percentage) / 100))
  );
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
  let cellSize = 220_000;
  if (radiusMeters < 180_000) {
    cellSize = 20_000;
  } else if (radiusMeters < 350_000) {
    cellSize = 35_000;
  } else if (radiusMeters < 700_000) {
    cellSize = 60_000;
  } else if (radiusMeters < 1_200_000) {
    cellSize = 95_000;
  } else if (radiusMeters < 1_800_000) {
    cellSize = 145_000;
  }

  return Math.min(Math.max(cellSize, MIN_MAP_CELL_SIZE_METERS), MAX_MAP_CELL_SIZE_METERS);
}

function topVibesFromNearbyStats(row: NearbyPlaceRow, supportsV2: boolean) {
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

  addNearbyTopVibe(topVibes, row.stats_top_vibe_tag_id, row.stats_top_vibe_percent, row.stats_total_vibes, supportsV2);
  addNearbyTopVibe(topVibes, row.stats_second_vibe_tag_id, row.stats_second_vibe_percent, row.stats_total_vibes, supportsV2);
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
  totalVibes: number,
  supportsV2: boolean
): void {
  if (!tagID || percentage === null || percentage <= 0) {
    return;
  }

  const compatibleTagID = clientCompatibleTagID(tagID, supportsV2);
  const existing = output.find((item) => item.vibe_tag_id === compatibleTagID);
  if (existing) {
    existing.count += Math.max(1, Math.round((totalVibes * percentage) / 100));
    existing.percentage = Math.min(100, existing.percentage + Math.round(percentage));
    return;
  }

  const tag = TAG_BY_ID.get(compatibleTagID);
  output.push({
    vibe_tag: legacyDisplayNameForTag(compatibleTagID),
    vibe_tag_id: compatibleTagID,
    slug: tag?.slug ?? compatibleTagID,
    display_name: tag?.display_name ?? compatibleTagID,
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

async function fetchTopVibes(
  env: Env,
  placeID: string,
  totalVibes: number,
  limit: number,
  preferredTopVibeID?: VibeTagID | null,
  supportsV2 = false
) {
  const rawRows = await fetchTagCounts(env, placeID, undefined, Math.max(limit, VIBE_TAG_DEFINITIONS.length));
  const compatibleRowsByID = new Map<VibeTagID, TagCountRow>();
  for (const row of rawRows) {
    const compatibleTagID = clientCompatibleTagID(row.vibe_tag_id, supportsV2);
    const existing = compatibleRowsByID.get(compatibleTagID);
    if (existing) {
      existing.tag_count += row.tag_count;
      if (!existing.first_seen_at || (row.first_seen_at && row.first_seen_at < existing.first_seen_at)) {
        existing.first_seen_at = row.first_seen_at;
      }
    } else {
      compatibleRowsByID.set(compatibleTagID, { ...row, vibe_tag_id: compatibleTagID });
    }
  }
  const compatibleRows = Array.from(compatibleRowsByID.values()).sort((left, right) => {
    if (left.tag_count === right.tag_count) {
      return (left.first_seen_at ?? "").localeCompare(right.first_seen_at ?? "");
    }
    return right.tag_count - left.tag_count;
  });
  const preferredCompatibleTagID = preferredTopVibeID
    ? clientCompatibleTagID(preferredTopVibeID, supportsV2)
    : null;
  const rows = prioritizePreferredTopVibe(compatibleRows, preferredCompatibleTagID).slice(0, limit);

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

function prioritizePreferredTopVibe(rows: TagCountRow[], preferredTopVibeID?: VibeTagID | null): TagCountRow[] {
  if (!preferredTopVibeID) {
    return rows;
  }

  const preferredRow = rows.find((row) => row.vibe_tag_id === preferredTopVibeID);
  if (!preferredRow) {
    return rows;
  }

  return [preferredRow, ...rows.filter((row) => row.vibe_tag_id !== preferredTopVibeID)];
}

function selectedTagCount(rows: TagCountRow[], tagID: VibeTagID | null | undefined): number | null {
  if (!tagID) {
    return null;
  }

  return rows.find((row) => row.vibe_tag_id === tagID)?.tag_count ?? null;
}

function supportingTopTag(rows: TagCountRow[], primaryDisplayTagID: VibeTagID | null | undefined): TagCountRow | null {
  return rows.find((row) => row.vibe_tag_id !== primaryDisplayTagID) ?? null;
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
         updated_at = excluded.updated_at
       WHERE excluded.updated_at >= place_vibe_stats.updated_at`
    )
      .bind(placeID, updatedAt)
      .run();
    return;
  }

  const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const sinceYear = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString();
  const last30Total = await fetchEventTotal(env, placeID, since30);
  const lastYearTotal = await fetchEventTotal(env, placeID, sinceYear);
  const allTimePrimaryTop = await fetchPrimaryTagCounts(env, placeID, undefined, VIBE_TAG_DEFINITIONS.length);
  const last30PrimaryTop = await fetchPrimaryTagCounts(env, placeID, since30, VIBE_TAG_DEFINITIONS.length);
  const lastYearPrimaryTop = await fetchPrimaryTagCounts(env, placeID, sinceYear, VIBE_TAG_DEFINITIONS.length);
  const allTimeSelectedTop = await fetchTagCounts(env, placeID, undefined, VIBE_TAG_DEFINITIONS.length);
  const last30SelectedTop = await fetchTagCounts(env, placeID, since30, VIBE_TAG_DEFINITIONS.length);
  const lastYearSelectedTop = await fetchTagCounts(env, placeID, sinceYear, VIBE_TAG_DEFINITIONS.length);
  const top = allTimePrimaryTop[0] ?? allTimeSelectedTop[0] ?? null;
  const second = supportingTopTag(allTimeSelectedTop, top?.vibe_tag_id);
  const top30 = last30PrimaryTop[0] ?? last30SelectedTop[0] ?? null;
  const topYear = lastYearPrimaryTop[0] ?? lastYearSelectedTop[0] ?? null;
  const topSelectedCount = selectedTagCount(allTimeSelectedTop, top?.vibe_tag_id) ?? top?.tag_count ?? null;
  const top30SelectedCount = selectedTagCount(last30SelectedTop, top30?.vibe_tag_id) ?? top30?.tag_count ?? null;
  const topYearSelectedCount = selectedTagCount(lastYearSelectedTop, topYear?.vibe_tag_id) ?? topYear?.tag_count ?? null;

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
       updated_at = excluded.updated_at
     WHERE excluded.updated_at >= place_vibe_stats.updated_at`
  )
    .bind(
      placeID,
      allTimeTotal,
      top?.vibe_tag_id ?? null,
      topSelectedCount !== null ? percent(topSelectedCount, allTimeTotal) : null,
      second?.vibe_tag_id ?? null,
      second ? percent(second.tag_count, allTimeTotal) : null,
      last30Total,
      top30?.vibe_tag_id ?? null,
      top30SelectedCount !== null ? percent(top30SelectedCount, last30Total) : null,
      lastYearTotal,
      topYear?.vibe_tag_id ?? null,
      topYearSelectedCount !== null ? percent(topYearSelectedCount, lastYearTotal) : null,
      updatedAt
    )
    .run();
}

async function refreshImmediatePlaceVibeStats(env: Env, placeID: string, updatedAt: string): Promise<void> {
  const [totalResult, primaryResult, selectedResult] = await env.DB.batch([
    env.DB.prepare(
      `SELECT COUNT(*) AS total_vibes
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE}`
    ).bind(placeID),
    env.DB.prepare(
      `SELECT primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE}
       GROUP BY primary_vibe_tag_id
       ORDER BY tag_count DESC, first_seen_at ASC, primary_vibe_tag_id ASC
       LIMIT ?`
    ).bind(placeID, VIBE_TAG_DEFINITIONS.length),
    env.DB.prepare(
      `SELECT vibe_tag_id, SUM(tag_count) AS tag_count, MIN(first_seen_at) AS first_seen_at
       FROM (
         SELECT primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
         FROM vibe_events
         WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE}
         GROUP BY primary_vibe_tag_id
         UNION ALL
         SELECT secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
         FROM vibe_events
         WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND secondary_vibe_tag_id IS NOT NULL
         GROUP BY secondary_vibe_tag_id
         UNION ALL
         SELECT third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
         FROM vibe_events
         WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND third_vibe_tag_id IS NOT NULL
         GROUP BY third_vibe_tag_id
       )
       GROUP BY vibe_tag_id
       ORDER BY tag_count DESC, first_seen_at ASC, vibe_tag_id ASC
       LIMIT ?`
    ).bind(placeID, placeID, placeID, VIBE_TAG_DEFINITIONS.length),
  ]);

  const total = Number((totalResult.results?.[0] as EventTotalRow | undefined)?.total_vibes ?? 0);
  const primaryRows = (primaryResult.results ?? []).filter(
    (row): row is TagCountRow => Boolean(TAG_BY_ID.get((row as TagCountRow).vibe_tag_id))
  );
  const selectedRows = (selectedResult.results ?? []).filter(
    (row): row is TagCountRow => Boolean(TAG_BY_ID.get((row as TagCountRow).vibe_tag_id))
  );
  const top = primaryRows[0] ?? selectedRows[0] ?? null;
  const second = supportingTopTag(selectedRows, top?.vibe_tag_id);
  const topSelectedCount = selectedTagCount(selectedRows, top?.vibe_tag_id) ?? top?.tag_count ?? null;

  await env.DB.prepare(
    `INSERT INTO place_vibe_stats (
       place_id, total_vibes, top_vibe_tag_id, top_vibe_percent,
       second_vibe_tag_id, second_vibe_percent, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(place_id) DO UPDATE SET
       total_vibes = excluded.total_vibes,
       top_vibe_tag_id = excluded.top_vibe_tag_id,
       top_vibe_percent = excluded.top_vibe_percent,
       second_vibe_tag_id = excluded.second_vibe_tag_id,
       second_vibe_percent = excluded.second_vibe_percent,
       updated_at = excluded.updated_at
     WHERE excluded.updated_at >= place_vibe_stats.updated_at`
  )
    .bind(
      placeID,
      total,
      top?.vibe_tag_id ?? null,
      topSelectedCount !== null ? percent(topSelectedCount, total) : null,
      second?.vibe_tag_id ?? null,
      second ? percent(second.tag_count, total) : null,
      updatedAt
    )
    .run();
}

async function refreshPlaceVibeTagStats(env: Env, placeID: string, updatedAt: string): Promise<void> {
  const nowMs = Date.now();
  const windows = [
    { id: "all_time", since: undefined },
    { id: "last_30_days", since: new Date(nowMs - 30 * 24 * 60 * 60 * 1000).toISOString() },
    { id: "last_365_days", since: new Date(nowMs - 365 * 24 * 60 * 60 * 1000).toISOString() },
  ] as const;
  const statements = [
    env.DB.prepare("DELETE FROM place_vibe_tag_stats WHERE place_id = ? AND updated_at <= ?").bind(placeID, updatedAt),
  ];

  for (const statsWindow of windows) {
    const vibeEventCount = await fetchEventTotal(env, placeID, statsWindow.since);
    if (vibeEventCount === 0) {
      continue;
    }

    const tagCounts = await fetchTagCounts(env, placeID, statsWindow.since, 100);
    for (const tagCount of tagCounts) {
      statements.push(
        env.DB.prepare(
          `INSERT INTO place_vibe_tag_stats (
             place_id,
             vibe_tag_id,
             window,
             vibe_event_count,
             tag_count,
             selected_by_vibe_percent,
             updated_at
           ) VALUES (?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(place_id, vibe_tag_id, window) DO UPDATE SET
             vibe_event_count = excluded.vibe_event_count,
             tag_count = excluded.tag_count,
             selected_by_vibe_percent = excluded.selected_by_vibe_percent,
             updated_at = excluded.updated_at
             WHERE excluded.updated_at >= place_vibe_tag_stats.updated_at`
        ).bind(
          placeID,
          tagCount.vibe_tag_id,
          statsWindow.id,
          vibeEventCount,
          tagCount.tag_count,
          percent(tagCount.tag_count, vibeEventCount),
          updatedAt
        )
      );
    }
  }

  await env.DB.batch(statements);
}

type AggregateRefreshJobRow = {
  place_id: string;
  requested_at: string;
  attempts: number;
};

async function processAggregateRefreshJob(env: Env, placeID: string): Promise<void> {
  const job = await env.DB.prepare(
    `SELECT place_id, requested_at, attempts
     FROM aggregate_refresh_jobs
     WHERE place_id = ?`
  )
    .bind(placeID)
    .first<AggregateRefreshJobRow>();
  if (!job) {
    return;
  }

  try {
    await refreshPlaceVibeStats(env, placeID, job.requested_at);
    await refreshPlaceVibeTagStats(env, placeID, job.requested_at);
    await env.DB.prepare(
      "DELETE FROM aggregate_refresh_jobs WHERE place_id = ? AND requested_at = ?"
    )
      .bind(placeID, job.requested_at)
      .run();
  } catch (error) {
    const attempts = job.attempts + 1;
    const retryDelaySeconds = Math.min(60 * 2 ** Math.min(attempts - 1, 5), 3600);
    const nextAttemptAt = new Date(Date.now() + retryDelaySeconds * 1000).toISOString();
    await env.DB.prepare(
      `UPDATE aggregate_refresh_jobs
       SET attempts = ?, next_attempt_at = ?, last_error = ?
       WHERE place_id = ? AND requested_at = ?`
    )
      .bind(attempts, nextAttemptAt, String(error).slice(0, 500), placeID, job.requested_at)
      .run();
    console.error(JSON.stringify({ message: "Aggregate refresh failed", placeID, attempts, error: String(error) }));
  }
}

async function drainAggregateRefreshJobs(env: Env, limit = 25): Promise<void> {
  const now = new Date().toISOString();
  const result = await env.DB.prepare(
    `SELECT place_id, requested_at, attempts
     FROM aggregate_refresh_jobs
     WHERE next_attempt_at <= ?
     ORDER BY requested_at ASC
     LIMIT ?`
  )
    .bind(now, limit)
    .all<AggregateRefreshJobRow>();

  for (const job of result.results ?? []) {
    await processAggregateRefreshJob(env, job.place_id);
  }
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

async function fetchPrimaryTagCounts(env: Env, placeID: string, since: string | undefined, limit: number): Promise<TagCountRow[]> {
  const result = await env.DB.prepare(
    `SELECT primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
     FROM vibe_events
     WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND (? IS NULL OR created_at >= ?)
     GROUP BY primary_vibe_tag_id
     ORDER BY tag_count DESC, first_seen_at ASC, primary_vibe_tag_id ASC
     LIMIT ?`
  )
    .bind(placeID, since ?? null, since ?? null, limit)
    .all<TagCountRow>();

  return (result.results ?? []).filter((row): row is TagCountRow => Boolean(TAG_BY_ID.get(row.vibe_tag_id)));
}

async function fetchTagCounts(env: Env, placeID: string, since: string | undefined, limit: number): Promise<TagCountRow[]> {
  const result = await env.DB.prepare(
    `SELECT vibe_tag_id, SUM(tag_count) AS tag_count, MIN(first_seen_at) AS first_seen_at
     FROM (
       SELECT primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND (? IS NULL OR created_at >= ?)
       GROUP BY primary_vibe_tag_id
       UNION ALL
       SELECT secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND secondary_vibe_tag_id IS NOT NULL AND (? IS NULL OR created_at >= ?)
       GROUP BY secondary_vibe_tag_id
       UNION ALL
       SELECT third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
       FROM vibe_events
       WHERE place_id = ? AND ${ACTIVE_EVENT_WHERE} AND third_vibe_tag_id IS NOT NULL AND (? IS NULL OR created_at >= ?)
       GROUP BY third_vibe_tag_id
     )
     GROUP BY vibe_tag_id
     ORDER BY tag_count DESC, first_seen_at ASC, vibe_tag_id ASC
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

function serializeVibeEvent(row: VibeEventRow, supportsV2 = false) {
  const primaryTagID = clientCompatibleTagID(row.primary_vibe_tag_id, supportsV2);
  const secondaryTagID = row.secondary_vibe_tag_id
    ? clientCompatibleTagID(row.secondary_vibe_tag_id, supportsV2)
    : null;
  const thirdTagID = row.third_vibe_tag_id
    ? clientCompatibleTagID(row.third_vibe_tag_id, supportsV2)
    : null;
  return {
    id: row.id,
    place_id: row.place_id,
    anonymous_user_id: row.anonymous_user_id,
    primary_vibe_tag_id: primaryTagID,
    secondary_vibe_tag_id: secondaryTagID,
    third_vibe_tag_id: thirdTagID,
    vibe_tag_ids: [...new Set([primaryTagID, secondaryTagID, thirdTagID].filter((tag): tag is VibeTagID => Boolean(tag)))],
    source: row.source,
    app_version: row.app_version,
    taxonomy_version_id: row.taxonomy_version_id ?? CURRENT_TAXONOMY_VERSION_ID,
    submission_context: row.submission_context ?? row.source,
    created_at: row.created_at,
    updated_at: row.updated_at,
    moderation_status: row.moderation_status,
  };
}

function serializeLegacyRating(row: VibeEventRow, supportsV2 = false) {
  const primaryTagID = clientCompatibleTagID(row.primary_vibe_tag_id, supportsV2);
  const secondaryTagID = row.secondary_vibe_tag_id
    ? clientCompatibleTagID(row.secondary_vibe_tag_id, supportsV2)
    : null;
  const thirdTagID = row.third_vibe_tag_id
    ? clientCompatibleTagID(row.third_vibe_tag_id, supportsV2)
    : null;
  const primaryName = legacyDisplayNameForTag(primaryTagID);
  const secondaryName = secondaryTagID ? legacyDisplayNameForTag(secondaryTagID) : null;
  const thirdName = thirdTagID ? legacyDisplayNameForTag(thirdTagID) : null;
  const vibeTags = [primaryName, secondaryName, thirdName].filter((tag): tag is string => Boolean(tag));
  const scoreTotal = [
    scoreForTag(primaryTagID),
    secondaryTagID ? scoreForTag(secondaryTagID) : null,
    thirdTagID ? scoreForTag(thirdTagID) : null,
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

async function deviceHashFromBody(input: DeviceIdentityInput): Promise<string | null> {
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
    case "bougie":
      return "bougie";
    case "low_key":
    case "worth_it":
    case "worthit":
      return "low_key";
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
    case "bougie":
      return "Bougie";
    case "low_key":
      return "Low-key";
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
    case "bougie":
      return 5.8;
    case "low_key":
      return 5.6;
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

function isValidCoordinate(latitude: number, longitude: number): boolean {
  return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
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
    path === "/account/review-login" ||
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

type RateLimitDecision = {
  allowed: boolean;
  policy: string;
};

async function applyRateLimit(
  binding: RateLimit | undefined,
  key: string,
  policy: string
): Promise<RateLimitDecision> {
  if (!binding) {
    console.error(JSON.stringify({ message: "Rate limiter binding unavailable", policy }));
    return { allowed: true, policy: `${policy}; unavailable` };
  }

  try {
    const outcome = await binding.limit({ key });
    return { allowed: outcome.success, policy };
  } catch (error) {
    // A binding outage should not turn into an application-wide outage. The
    // missing protection is observable and the configured binding remains the
    // normal production path.
    console.error(JSON.stringify({ message: "Rate limiter failed", policy, error: String(error) }));
    return { allowed: true, policy: `${policy}; fail-open` };
  }
}

async function rateLimitDecision(request: Request, path: string, env: Env): Promise<RateLimitDecision> {
  if (request.method === "OPTIONS" || request.method === "HEAD") {
    return { allowed: true, policy: "none" };
  }

  const runtimeEnv = env as RuntimeEnv;
  const ip = cleanString(request.headers.get("CF-Connecting-IP"))?.slice(0, 128) ?? "local";
  const device = cleanString(request.headers.get("X-Vibe-Device-ID-Hash"))?.slice(0, 128);
  const authPaths = new Set([
    "/account/signup",
    "/account/login",
    "/account/recovery",
    "/account/review-login",
  ]);

  if (request.method === "POST" && authPaths.has(path)) {
    return applyRateLimit(runtimeEnv.AUTH_RATE_LIMITER, `auth:${ip}`, "auth=6;w=60");
  }

  if (request.method === "POST" && path === "/analytics/events") {
    const deviceDecision = await applyRateLimit(
      runtimeEnv.ANALYTICS_DEVICE_RATE_LIMITER,
      `analytics-device:${device ?? ip}`,
      "analytics-device=120;w=60"
    );
    if (!deviceDecision.allowed) {
      return deviceDecision;
    }
    return applyRateLimit(runtimeEnv.ANALYTICS_IP_RATE_LIMITER, `analytics-ip:${ip}`, "analytics-ip=600;w=60");
  }

  if (request.method === "GET" && (path === "/places/provider-search" || path === "/places/search")) {
    return applyRateLimit(
      runtimeEnv.SEARCH_RATE_LIMITER,
      `search:${device ?? ip}`,
      "place-search=60;w=60"
    );
  }

  if (request.method === "POST") {
    const deviceDecision = await applyRateLimit(
      runtimeEnv.WRITE_DEVICE_RATE_LIMITER,
      `write-device:${device ?? ip}`,
      "write-device=30;w=60"
    );
    if (!deviceDecision.allowed) {
      return deviceDecision;
    }
    return applyRateLimit(runtimeEnv.WRITE_IP_RATE_LIMITER, `write-ip:${ip}`, "write-ip=120;w=60");
  }

  return { allowed: true, policy: "none" };
}

function corsHeaders(): Headers {
  const headers = new Headers();
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    `Content-Type, Authorization, X-Vibe-Device-ID-Hash, X-Vibe-App-Version, X-Vibe-Source, ${TAXONOMY_VERSION_HEADER}, ${BETA_ACCESS_HEADER}`
  );
  headers.set("X-RateLimit-Policy", "route-specific Cloudflare binding");
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
