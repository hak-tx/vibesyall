CREATE TABLE IF NOT EXISTS analytics_devices (
  analytics_device_id TEXT PRIMARY KEY,
  first_seen_at TEXT NOT NULL,
  first_seen_day TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  last_seen_day TEXT NOT NULL,
  platform TEXT,
  app_version TEXT,
  event_count INTEGER NOT NULL DEFAULT 0,
  app_open_count INTEGER NOT NULL DEFAULT 0,
  search_count INTEGER NOT NULL DEFAULT 0,
  place_select_count INTEGER NOT NULL DEFAULT 0,
  vibe_submit_count INTEGER NOT NULL DEFAULT 0,
  account_event_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS analytics_device_days (
  day TEXT NOT NULL,
  analytics_device_id TEXT NOT NULL,
  first_seen_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  platform TEXT,
  app_version TEXT,
  event_count INTEGER NOT NULL DEFAULT 0,
  app_open_count INTEGER NOT NULL DEFAULT 0,
  search_count INTEGER NOT NULL DEFAULT 0,
  place_select_count INTEGER NOT NULL DEFAULT 0,
  vibe_submit_count INTEGER NOT NULL DEFAULT 0,
  account_event_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(day, analytics_device_id),
  FOREIGN KEY(analytics_device_id) REFERENCES analytics_devices(analytics_device_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS analytics_events (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  day TEXT NOT NULL,
  analytics_device_id TEXT NOT NULL,
  event_name TEXT NOT NULL,
  platform TEXT,
  app_version TEXT,
  properties_json TEXT NOT NULL DEFAULT '{}',
  FOREIGN KEY(analytics_device_id) REFERENCES analytics_devices(analytics_device_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_analytics_devices_first_seen_day ON analytics_devices(first_seen_day);
CREATE INDEX IF NOT EXISTS idx_analytics_devices_last_seen_day ON analytics_devices(last_seen_day);
CREATE INDEX IF NOT EXISTS idx_analytics_device_days_device ON analytics_device_days(analytics_device_id, day);
CREATE INDEX IF NOT EXISTS idx_analytics_events_day_name ON analytics_events(day, event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_device_day ON analytics_events(analytics_device_id, day);
