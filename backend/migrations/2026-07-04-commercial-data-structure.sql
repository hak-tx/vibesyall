PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS place_external_ids (
  place_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  provider_place_id TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'app_submission',
  confidence REAL NOT NULL DEFAULT 1.0 CHECK (confidence >= 0 AND confidence <= 1),
  first_seen_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  PRIMARY KEY(provider, provider_place_id),
  UNIQUE(place_id, provider, provider_place_id),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS taxonomy_versions (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS place_vibe_tag_stats (
  place_id TEXT NOT NULL,
  vibe_tag_id TEXT NOT NULL,
  window TEXT NOT NULL CHECK (window IN ('all_time', 'last_30_days', 'last_365_days')),
  vibe_event_count INTEGER NOT NULL DEFAULT 0,
  tag_count INTEGER NOT NULL DEFAULT 0,
  selected_by_vibe_percent REAL NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  PRIMARY KEY(place_id, vibe_tag_id, window),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE,
  FOREIGN KEY(vibe_tag_id) REFERENCES vibe_tags(id)
);

CREATE INDEX IF NOT EXISTS idx_place_external_ids_place ON place_external_ids(place_id);
CREATE INDEX IF NOT EXISTS idx_place_vibe_tag_stats_place_window ON place_vibe_tag_stats(place_id, window, tag_count DESC);
CREATE INDEX IF NOT EXISTS idx_place_vibe_tag_stats_window_tag ON place_vibe_tag_stats(window, vibe_tag_id, tag_count DESC);

INSERT INTO taxonomy_versions (id, label, effective_at, notes, created_at) VALUES
  ('vibes_v1', 'VIBES Y''ALL V1 tag set', '2026-06-28T00:00:00.000Z', 'Initial structured one-to-three vibe label taxonomy.', '2026-06-28T00:00:00.000Z')
ON CONFLICT(id) DO UPDATE SET
  label = excluded.label,
  effective_at = excluded.effective_at,
  notes = excluded.notes;

UPDATE vibe_events
SET taxonomy_version_id = 'vibes_v1'
WHERE taxonomy_version_id IS NULL
  OR taxonomy_version_id = '';

UPDATE vibe_events
SET submission_context = COALESCE(NULLIF(source, ''), 'unknown')
WHERE submission_context IS NULL
  OR submission_context = '';

INSERT INTO place_external_ids (
  place_id,
  provider,
  provider_place_id,
  source,
  confidence,
  first_seen_at,
  last_seen_at
)
SELECT
  id,
  provider,
  provider_place_id,
  'places_backfill',
  1.0,
  created_at,
  updated_at
FROM places
WHERE provider_place_id IS NOT NULL
  AND provider_place_id != ''
ON CONFLICT(provider, provider_place_id) DO UPDATE SET
  place_id = excluded.place_id,
  source = COALESCE(place_external_ids.source, excluded.source),
  confidence = MAX(place_external_ids.confidence, excluded.confidence),
  first_seen_at = MIN(place_external_ids.first_seen_at, excluded.first_seen_at),
  last_seen_at = MAX(place_external_ids.last_seen_at, excluded.last_seen_at);

DELETE FROM place_vibe_tag_stats;

INSERT INTO place_vibe_tag_stats (
  place_id,
  vibe_tag_id,
  window,
  vibe_event_count,
  tag_count,
  selected_by_vibe_percent,
  updated_at
)
WITH active_events AS (
  SELECT *
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0
),
window_events AS (
  SELECT 'all_time' AS window, place_id, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id
  FROM active_events
  UNION ALL
  SELECT 'last_30_days' AS window, place_id, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  UNION ALL
  SELECT 'last_365_days' AS window, place_id, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
),
event_totals AS (
  SELECT place_id, window, COUNT(*) AS vibe_event_count
  FROM window_events
  GROUP BY place_id, window
),
tag_counts AS (
  SELECT place_id, window, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM window_events
  GROUP BY place_id, window, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, window, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM window_events
  WHERE secondary_vibe_tag_id IS NOT NULL
  GROUP BY place_id, window, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, window, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM window_events
  WHERE third_vibe_tag_id IS NOT NULL
  GROUP BY place_id, window, third_vibe_tag_id
),
tag_counts_merged AS (
  SELECT place_id, window, vibe_tag_id, SUM(tag_count) AS tag_count
  FROM tag_counts
  GROUP BY place_id, window, vibe_tag_id
)
SELECT
  tag_counts_merged.place_id,
  tag_counts_merged.vibe_tag_id,
  tag_counts_merged.window,
  event_totals.vibe_event_count,
  tag_counts_merged.tag_count,
  ROUND((tag_counts_merged.tag_count * 100.0) / event_totals.vibe_event_count, 1),
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM tag_counts_merged
JOIN event_totals
  ON event_totals.place_id = tag_counts_merged.place_id
 AND event_totals.window = tag_counts_merged.window;
