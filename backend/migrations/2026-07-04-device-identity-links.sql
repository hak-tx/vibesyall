PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS device_identity_links (
  analytics_device_id TEXT NOT NULL,
  anonymous_user_id TEXT NOT NULL,
  link_source TEXT NOT NULL CHECK (link_source IN ('vibe_submission', 'analytics_backfill', 'manual')),
  confidence REAL NOT NULL DEFAULT 1.0 CHECK (confidence >= 0 AND confidence <= 1),
  event_count INTEGER NOT NULL DEFAULT 1,
  first_seen_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  PRIMARY KEY(analytics_device_id, anonymous_user_id),
  FOREIGN KEY(analytics_device_id) REFERENCES analytics_devices(analytics_device_id) ON DELETE CASCADE,
  FOREIGN KEY(anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_device_identity_links_anonymous ON device_identity_links(anonymous_user_id, analytics_device_id);

INSERT INTO device_identity_links (
  analytics_device_id,
  anonymous_user_id,
  link_source,
  confidence,
  event_count,
  first_seen_at,
  last_seen_at
)
WITH submitted_events AS (
  SELECT
    analytics_device_id,
    created_at,
    app_version,
    json_extract(properties_json, '$.place_id') AS place_id,
    json_extract(properties_json, '$.primary_vibe_tag_id') AS primary_vibe_tag_id
  FROM analytics_events
  WHERE event_name = 'vibe_submitted'
),
matched_events AS (
  SELECT
    submitted_events.analytics_device_id,
    vibe_events.anonymous_user_id,
    COUNT(*) AS event_count,
    MIN(submitted_events.created_at) AS first_seen_at,
    MAX(submitted_events.created_at) AS last_seen_at
  FROM submitted_events
  JOIN vibe_events
    ON vibe_events.place_id = submitted_events.place_id
   AND vibe_events.moderation_status = 'active'
   AND vibe_events.is_deleted = 0
   AND (
     vibe_events.app_version = submitted_events.app_version
     OR vibe_events.primary_vibe_tag_id = submitted_events.primary_vibe_tag_id
     OR ABS(strftime('%s', vibe_events.created_at) - strftime('%s', submitted_events.created_at)) <= 300
   )
  GROUP BY submitted_events.analytics_device_id, vibe_events.anonymous_user_id
)
SELECT
  analytics_device_id,
  anonymous_user_id,
  'analytics_backfill',
  CASE WHEN event_count > 1 THEN 0.98 ELSE 0.92 END,
  event_count,
  first_seen_at,
  last_seen_at
FROM matched_events
WHERE 1 = 1
ON CONFLICT(analytics_device_id, anonymous_user_id) DO UPDATE SET
  event_count = MAX(device_identity_links.event_count, excluded.event_count),
  confidence = MAX(device_identity_links.confidence, excluded.confidence),
  first_seen_at = MIN(device_identity_links.first_seen_at, excluded.first_seen_at),
  last_seen_at = MAX(device_identity_links.last_seen_at, excluded.last_seen_at);
