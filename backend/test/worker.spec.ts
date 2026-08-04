import {
  applyD1Migrations,
  createExecutionContext,
  createScheduledController,
  env,
  SELF,
  waitOnExecutionContext,
} from "cloudflare:test";
import { beforeAll, describe, expect, it } from "vitest";
import worker, { adminDashboardPage, buildAdminAnalyticsPayload } from "../src/index";

type TestEnv = Env & { TEST_SCHEMA_QUERIES: string };

const apiHeaders = {
  "Content-Type": "application/json",
  "CF-Connecting-IP": "192.0.2.10",
  "X-Vibe-App-Version": "0.1.4-test",
  "X-Vibe-Device-ID-Hash": "device-test-001",
  "X-Vibe-Taxonomy-Version": "vibes_v3",
};

beforeAll(async () => {
  const testEnv = env as TestEnv;
  await applyD1Migrations(testEnv.DB, [
    { name: "0001_test_schema.sql", queries: JSON.parse(testEnv.TEST_SCHEMA_QUERIES) as string[] },
  ]);
  const now = new Date().toISOString();
  await testEnv.DB.prepare(
    `INSERT INTO places (
       id, provider, provider_place_id, name, latitude, longitude,
       street_address, city, region, country, category, primary_category,
       provider_category, created_at, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      "place_launch_test",
      "apple",
      "apple-launch-test",
      "Launch Test Cafe",
      29.7604,
      -95.3698,
      "100 Test Street",
      "Houston",
      "TX",
      "US",
      "Restaurant",
      "Restaurant",
      "Cafe",
      now,
      now
    )
    .run();
});

describe("launch-critical Worker flows", () => {
  it("serves the health endpoint", async () => {
    const response = await SELF.fetch("https://api.vibesyall.test/health");
    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({ ok: true });
  });

  it("persists a vibe, exposes immediate stats, and completes derived rollups", async () => {
    const response = await SELF.fetch("https://api.vibesyall.test/vibes", {
      method: "POST",
      headers: apiHeaders,
      body: JSON.stringify({
        place_id: "place_launch_test",
        device_id_hash: "device-test-001",
        vibe_tags: ["Fire", "Low-key", "Iconic"],
        source: "ios",
      }),
    });

    expect(response.status).toBe(200);
    const payload = await response.json<Record<string, any>>();
    expect(payload.vibe_event).toMatchObject({
      place_id: "place_launch_test",
      primary_vibe_tag_id: "fire",
      secondary_vibe_tag_id: "low_key",
      third_vibe_tag_id: "iconic",
    });
    expect(payload.place.stats).toMatchObject({
      total_vibes: 1,
      top_vibe_tag_id: "fire",
      top_vibe_percent: 100,
    });

    const testEnv = env as TestEnv;
    const event = await testEnv.DB.prepare(
      "SELECT primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id FROM vibe_events WHERE place_id = ?"
    )
      .bind("place_launch_test")
      .first<Record<string, string>>();
    expect(event).toEqual({
      primary_vibe_tag_id: "fire",
      secondary_vibe_tag_id: "low_key",
      third_vibe_tag_id: "iconic",
    });

    const pendingJob = await testEnv.DB.prepare(
      "SELECT place_id FROM aggregate_refresh_jobs WHERE place_id = ?"
    )
      .bind("place_launch_test")
      .first();
    expect(pendingJob).toEqual({ place_id: "place_launch_test" });

    const scheduledContext = createExecutionContext();
    await worker.scheduled?.(createScheduledController(), testEnv, scheduledContext);
    await waitOnExecutionContext(scheduledContext);

    const completedJob = await testEnv.DB.prepare(
      "SELECT place_id FROM aggregate_refresh_jobs WHERE place_id = ?"
    )
      .bind("place_launch_test")
      .first();
    expect(completedJob).toBeNull();

    const detailedStats = await testEnv.DB.prepare(
      `SELECT vibe_tag_id, tag_count, selected_by_vibe_percent
       FROM place_vibe_tag_stats
       WHERE place_id = ? AND window = 'all_time'
       ORDER BY vibe_tag_id`
    )
      .bind("place_launch_test")
      .all<Record<string, string | number>>();
    expect(detailedStats.results).toEqual([
      { vibe_tag_id: "fire", tag_count: 1, selected_by_vibe_percent: 100 },
      { vibe_tag_id: "iconic", tag_count: 1, selected_by_vibe_percent: 100 },
      { vibe_tag_id: "low_key", tag_count: 1, selected_by_vibe_percent: 100 },
    ]);
  });

  it("deletes only the current user's vibe and refreshes place totals immediately", async () => {
    const testEnv = env as TestEnv;
    const now = new Date().toISOString();
    await testEnv.DB.prepare(
      `INSERT INTO places (
         id, provider, provider_place_id, name, latitude, longitude,
         street_address, city, region, country, category, primary_category,
         provider_category, created_at, updated_at
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        "place_delete_test",
        "apple",
        "apple-delete-test",
        "Delete Test Cafe",
        29.7605,
        -95.3699,
        "101 Test Street",
        "Houston",
        "TX",
        "US",
        "Restaurant",
        "Restaurant",
        "Cafe",
        now,
        now
      )
      .run();

    const createResponse = await SELF.fetch("https://api.vibesyall.test/ratings", {
      method: "POST",
      headers: apiHeaders,
      body: JSON.stringify({
        place_id: "place_delete_test",
        device_id_hash: "device-test-001",
        vibe_tags: ["Fire", "Iconic"],
        source: "ios",
      }),
    });
    expect(createResponse.status).toBe(200);

    const otherDeviceResponse = await SELF.fetch(
      "https://api.vibesyall.test/ratings/place_delete_test",
      {
        method: "DELETE",
        headers: { ...apiHeaders, "X-Vibe-Device-ID-Hash": "device-test-other" },
      }
    );
    expect(otherDeviceResponse.status).toBe(200);
    await expect(otherDeviceResponse.json()).resolves.toMatchObject({ deleted: false });

    const deleteResponse = await SELF.fetch(
      "https://api.vibesyall.test/ratings/place_delete_test",
      { method: "DELETE", headers: apiHeaders }
    );
    expect(deleteResponse.status).toBe(200);
    const payload = await deleteResponse.json<Record<string, any>>();
    expect(payload).toMatchObject({
      deleted: true,
      place: {
        my_rating: null,
        my_vibe_event: null,
        stats: { total_vibes: 0, rating_count: 0 },
      },
    });

    const event = await testEnv.DB.prepare(
      "SELECT is_deleted FROM vibe_events WHERE place_id = ?"
    )
      .bind("place_delete_test")
      .first<{ is_deleted: number }>();
    expect(event).toEqual({ is_deleted: 1 });

    const repeatedDeleteResponse = await SELF.fetch(
      "https://api.vibesyall.test/ratings/place_delete_test",
      { method: "DELETE", headers: apiHeaders }
    );
    expect(repeatedDeleteResponse.status).toBe(200);
    await expect(repeatedDeleteResponse.json()).resolves.toMatchObject({ deleted: false });
  });

  it("returns saved vibe history during the initial place search", async () => {
    const response = await SELF.fetch(
      "https://api.vibesyall.test/places/search?q=Launch%20Test&lat=29.7604&lng=-95.3698&limit=10",
      { headers: apiHeaders }
    );

    expect(response.status).toBe(200);
    const payload = await response.json<Record<string, any>>();
    expect(payload.places).toHaveLength(1);
    expect(payload.places[0]).toMatchObject({
      id: "place_launch_test",
      name: "Launch Test Cafe",
      stats: {
        total_vibes: 1,
        top_vibe_tag_id: "fire",
        top_vibe_percent: 100,
      },
      my_vibe_event: {
        primary_vibe_tag_id: "fire",
      },
    });
  });

  it("matches punctuation-tolerant business-name prefixes without unrelated fuzzy results", async () => {
    const testEnv = env as TestEnv;
    const now = new Date().toISOString();
    const fixtures = [
      ["place_joe_t_fort_worth", "Joe T. Garcia’s", 32.7886, -97.3488, "2201 N Commerce St", "Fort Worth"],
      ["place_joe_t_arlington", "Joe T Garcia’s Mexican Restaurant", 32.7357, -97.1081, "2201 Commerce Dr", "Arlington"],
      ["place_trader_joes", "Trader Joe’s", 32.7530, -97.3300, "2701 S Hulen St", "Fort Worth"],
      ["place_joe_tacos_restaurant", "Joe Tacos Restaurant", 32.7528, -97.3299, "2700 S Hulen St", "Fort Worth"],
      ["place_joes_crab", "Joe’s Crab Shack", 32.7500, -97.3500, "100 River Dr", "Fort Worth"],
      ["place_joe_tacos", "Joe Tacos", 32.7580, -97.3440, "150 Main St", "Fort Worth"],
      ["place_taco_joe", "Taco Joe Grill", 32.7600, -97.3400, "200 Main St", "Fort Worth"],
    ] as const;

    await testEnv.DB.batch(fixtures.flatMap(([id, name, latitude, longitude, address, city], index) => [
      testEnv.DB.prepare(
        `INSERT INTO places (
           id, provider, provider_place_id, name, latitude, longitude, street_address,
           city, region, country, category, primary_category, provider_category, created_at, updated_at
         ) VALUES (?, 'apple', ?, ?, ?, ?, ?, ?, 'TX', 'US', 'Restaurant', 'Restaurant', 'Mexican', ?, ?)`
      ).bind(id, `apple-${id}`, name, latitude, longitude, address, city, now, now),
      testEnv.DB.prepare(
        `INSERT INTO place_vibe_stats (place_id, total_vibes, updated_at) VALUES (?, ?, ?)`
      ).bind(id, fixtures.length - index, now),
    ]));

    for (const query of ["Joe T", "Joe T G", "Joe T Garcia", "Joe T. Garcia's"]) {
      const response = await SELF.fetch(
        `https://api.vibesyall.test/places/search?q=${encodeURIComponent(query)}&lat=32.7555&lng=-97.3308&limit=10`,
        { headers: apiHeaders }
      );
      expect(response.status).toBe(200);
      const payload = await response.json<Record<string, any>>();
      const names = payload.places.map((place: Record<string, any>) => place.name);

      expect(names).toContain("Joe T. Garcia’s");
      expect(names).toContain("Joe T Garcia’s Mexican Restaurant");
      expect(names).not.toContain("Trader Joe’s");
      expect(names).not.toContain("Joe Tacos Restaurant");
      expect(names).not.toContain("Joe’s Crab Shack");
      expect(names).not.toContain("Joe Tacos");
      expect(names).not.toContain("Taco Joe Grill");
    }
  });

  it("updates an existing submission without inflating the place total", async () => {
    const response = await SELF.fetch("https://api.vibesyall.test/vibes", {
      method: "POST",
      headers: apiHeaders,
      body: JSON.stringify({
        place_id: "place_launch_test",
        device_id_hash: "device-test-001",
        vibe_tags: ["Iconic", "Bougie"],
        source: "ios",
      }),
    });

    expect(response.status).toBe(200);
    const payload = await response.json<Record<string, any>>();
    expect(payload.place.stats).toMatchObject({
      total_vibes: 1,
      top_vibe_tag_id: "iconic",
      top_vibe_percent: 100,
    });

    const stats = await (env as TestEnv).DB.prepare(
      "SELECT total_vibes, top_vibe_tag_id FROM place_vibe_stats WHERE place_id = ?"
    )
      .bind("place_launch_test")
      .first();
    expect(stats).toEqual({ total_vibes: 1, top_vibe_tag_id: "iconic" });
  });

  it("maps the legacy Worth It label to the canonical Low-key tag", async () => {
    const response = await SELF.fetch("https://api.vibesyall.test/vibes", {
      method: "POST",
      headers: {
        ...apiHeaders,
        "CF-Connecting-IP": "192.0.2.11",
        "X-Vibe-Device-ID-Hash": "device-test-002",
      },
      body: JSON.stringify({
        place_id: "place_launch_test",
        device_id_hash: "device-test-002",
        vibe_tags: ["Worth It"],
        source: "ios",
      }),
    });

    expect(response.status).toBe(200);
    const payload = await response.json<Record<string, any>>();
    expect(payload.vibe_event.primary_vibe_tag_id).toBe("low_key");
    const stored = await (env as TestEnv).DB.prepare(
      `SELECT primary_vibe_tag_id
       FROM vibe_events
       WHERE place_id = ? AND primary_vibe_tag_id = 'low_key'`
    )
      .bind("place_launch_test")
      .first();
    expect(stored).toEqual({ primary_vibe_tag_id: "low_key" });
  });

  it("enforces the configured per-device write limit", async () => {
    const statuses: number[] = [];
    for (let index = 0; index < 31; index += 1) {
      const response = await SELF.fetch("https://api.vibesyall.test/not-a-route", {
        method: "POST",
        headers: {
          "CF-Connecting-IP": "192.0.2.20",
          "X-Vibe-Device-ID-Hash": "rate-limit-device",
        },
      });
      statuses.push(response.status);
    }

    expect(statuses.slice(0, 30).every((status) => status === 404)).toBe(true);
    expect(statuses[30]).toBe(429);
  });

  it("calculates plain-language audience and contribution metrics", async () => {
    const testEnv = env as TestEnv;
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const todayDay = today.toISOString().slice(0, 10);
    const yesterdayDay = yesterday.toISOString().slice(0, 10);
    const todayTimestamp = today.toISOString();
    const yesterdayTimestamp = yesterday.toISOString();

    await testEnv.DB.batch([
      testEnv.DB.prepare(
        `INSERT INTO analytics_devices (
           analytics_device_id, first_seen_at, first_seen_day, last_seen_at, last_seen_day,
           platform, app_version, event_count, app_open_count
         ) VALUES (?, ?, ?, ?, ?, 'ios', 'analytics-test', 2, 2)`
      ).bind("analytics-repeat-test", yesterdayTimestamp, yesterdayDay, todayTimestamp, todayDay),
      testEnv.DB.prepare(
        `INSERT INTO analytics_device_days (
           day, analytics_device_id, first_seen_at, last_seen_at, platform, app_version,
           event_count, app_open_count
         ) VALUES (?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind(yesterdayDay, "analytics-repeat-test", yesterdayTimestamp, yesterdayTimestamp),
      testEnv.DB.prepare(
        `INSERT INTO analytics_device_days (
           day, analytics_device_id, first_seen_at, last_seen_at, platform, app_version,
           event_count, app_open_count
         ) VALUES (?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind(todayDay, "analytics-repeat-test", todayTimestamp, todayTimestamp),
      testEnv.DB.prepare(
        `INSERT INTO analytics_devices (
           analytics_device_id, first_seen_at, first_seen_day, last_seen_at, last_seen_day,
           platform, app_version, event_count, app_open_count
         ) VALUES (?, ?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind("analytics-one-day-test", todayTimestamp, todayDay, todayTimestamp, todayDay),
      testEnv.DB.prepare(
        `INSERT INTO analytics_device_days (
           day, analytics_device_id, first_seen_at, last_seen_at, platform, app_version,
           event_count, app_open_count
         ) VALUES (?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind(todayDay, "analytics-one-day-test", todayTimestamp, todayTimestamp),
    ]);

    const payload = await buildAdminAnalyticsPayload(testEnv, { includeInternal: true });
    expect(payload.summary.active30d).toBeGreaterThanOrEqual(2);
    expect(payload.summary.repeatDevices30d).toBeGreaterThanOrEqual(1);
    expect(payload.summary.oneDayDevices30d).toBeGreaterThanOrEqual(1);
    expect(payload.summary.repeatDeviceRate30d).toBeGreaterThan(0);
    expect(payload.summary.activeDaysPerDevice30d).toBeGreaterThan(1);
    expect(payload.summary.vibesPerDevice30d).toBeGreaterThan(0);
    expect(payload.daily).toHaveLength(30);
    expect(payload.vibeHistoryDaily).toHaveLength(30);

    const rollingBaseline = await buildAdminAnalyticsPayload(testEnv, { includeInternal: true, days: 1 });
    const recentTimestamp = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const expiredTimestamp = new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString();
    await testEnv.DB.batch([
      testEnv.DB.prepare(
        `INSERT INTO analytics_devices (
           analytics_device_id, first_seen_at, first_seen_day, last_seen_at, last_seen_day,
           platform, app_version, event_count, app_open_count
         ) VALUES (?, ?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind("analytics-rolling-recent", recentTimestamp, recentTimestamp.slice(0, 10), recentTimestamp, recentTimestamp.slice(0, 10)),
      testEnv.DB.prepare(
        `INSERT INTO analytics_events (
           id, created_at, day, analytics_device_id, event_name, platform, app_version, properties_json
         ) VALUES (?, ?, ?, ?, 'app_open', 'ios', 'analytics-test', '{}')`
      ).bind("analytics-event-rolling-recent", recentTimestamp, recentTimestamp.slice(0, 10), "analytics-rolling-recent"),
      testEnv.DB.prepare(
        `INSERT INTO analytics_devices (
           analytics_device_id, first_seen_at, first_seen_day, last_seen_at, last_seen_day,
           platform, app_version, event_count, app_open_count
         ) VALUES (?, ?, ?, ?, ?, 'ios', 'analytics-test', 1, 1)`
      ).bind("analytics-rolling-expired", expiredTimestamp, expiredTimestamp.slice(0, 10), expiredTimestamp, expiredTimestamp.slice(0, 10)),
      testEnv.DB.prepare(
        `INSERT INTO analytics_events (
           id, created_at, day, analytics_device_id, event_name, platform, app_version, properties_json
         ) VALUES (?, ?, ?, ?, 'app_open', 'ios', 'analytics-test', '{}')`
      ).bind("analytics-event-rolling-expired", expiredTimestamp, expiredTimestamp.slice(0, 10), "analytics-rolling-expired"),
    ]);

    const oneDayPayload = await buildAdminAnalyticsPayload(testEnv, { includeInternal: true, days: 1 });
    expect(oneDayPayload.filters.days).toBe(1);
    expect(oneDayPayload.filters.timeZone).toBe("America/Chicago");
    expect(oneDayPayload.summary.active30d).toBe(rollingBaseline.summary.active30d + 1);
    expect(oneDayPayload.daily).toHaveLength(24);
    expect(oneDayPayload.vibeHistoryDaily).toHaveLength(24);
    expect(oneDayPayload.daily.every((row) => "bucketStart" in row && "bucketEnd" in row)).toBe(true);
    expect(oneDayPayload.daily.reduce((total, row) => total + row.events, 0)).toBe(oneDayPayload.summary.events30d);
    expect(oneDayPayload.vibeHistoryDaily.reduce((total, row) => total + row.vibeSubmissions, 0))
      .toBe(oneDayPayload.summary.vibeSubmissions30d);

    const sevenDayPayload = await buildAdminAnalyticsPayload(testEnv, { includeInternal: true, days: 7 });
    expect(sevenDayPayload.filters.days).toBe(7);
    expect(sevenDayPayload.daily).toHaveLength(7);
    expect(sevenDayPayload.vibeHistoryDaily).toHaveLength(7);
  });

  it("renders a syntactically valid selectable-window business dashboard", async () => {
    const response = adminDashboardPage("owner@example.com");
    const page = await response.text();
    expect(page).toContain("Places per contributor");
    expect(page).toContain("New and returning devices");
    expect(page).toContain('class="y-axis"');
    expect(page).toContain('class="chart-grid"');
    expect(page).toContain('class="x-axis-title">');
    expect(page).toContain('chartOptions.xAxisLabel || "Date"');
    expect(page).toContain('data-tooltip="');
    expect(page).not.toContain('class="grouped-day" title="');
    expect(page).toContain("function trendLineChart");
    expect(page).toContain('class="line-series ');
    expect(page).toContain('class="line-point ');
    expect(page).toContain("line-x-axis");
    expect(page).toContain("sparse-axis");
    expect(page).toContain("selectedDays === 1");
    expect(page).toContain('{ hourly: selectedDays === 1 }');
    expect(page).toContain("One-and-done or engaged?");
    expect(page).toContain('data-days="1"');
    expect(page).toContain('data-days="1" aria-pressed="false">Last 24 hrs</button>');
    expect(page).toContain('data-days="7"');
    expect(page).toContain('data-days="30"');
    expect(page).toContain('timeZone: "America/Chicago"');
    expect(page).toContain('"previous 24 hours"');
    expect(page).toContain('"Hour (Central Time)"');
    expect(page).toContain("centralHourFormat");
    expect(page).toContain('params.set("days", String(selectedDays))');
    expect(page).toContain("viewport-fit=cover");
    expect(page).toContain("min-height: 2.75rem");
    expect(page).toContain("order: -1");

    const script = page.match(/<script>([\s\S]*?)<\/script>/)?.[1];
    expect(script).toBeTruthy();
    expect(() => new Function(script ?? "")).not.toThrow();
  });
});
