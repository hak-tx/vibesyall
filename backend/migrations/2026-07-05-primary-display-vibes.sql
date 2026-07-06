-- Map pins should use the dominant primary vibe: the first vibe selected in each submission.
-- Secondary and third vibes still feed the richer selected-by breakdown in place_vibe_tag_stats.

DELETE FROM place_vibe_stats;

INSERT INTO place_vibe_stats (
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
)
WITH active_events AS (
  SELECT *
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0
),
event_totals AS (
  SELECT
    place_id,
    COUNT(*) AS total_vibes,
    SUM(CASE WHEN created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days') THEN 1 ELSE 0 END) AS last_30_day_total_vibes,
    SUM(CASE WHEN created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days') THEN 1 ELSE 0 END) AS last_year_total_vibes
  FROM active_events
  GROUP BY place_id
),
selected_tag_counts AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL
  GROUP BY place_id, third_vibe_tag_id
),
selected_tag_counts_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count, MIN(first_seen_at) AS first_seen_at
  FROM selected_tag_counts
  GROUP BY place_id, vibe_tag_id
),
primary_tag_counts AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  GROUP BY place_id, primary_vibe_tag_id
),
ranked_primary_all_time AS (
  SELECT
    primary_tag_counts.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, first_seen_at ASC, vibe_tag_id ASC) AS rank
  FROM primary_tag_counts
),
ranked_secondary_all_time AS (
  SELECT
    selected_tag_counts_merged.*,
    ROW_NUMBER() OVER (
      PARTITION BY selected_tag_counts_merged.place_id
      ORDER BY selected_tag_counts_merged.tag_count DESC, selected_tag_counts_merged.first_seen_at ASC, selected_tag_counts_merged.vibe_tag_id ASC
    ) AS rank
  FROM selected_tag_counts_merged
  JOIN ranked_primary_all_time
    ON ranked_primary_all_time.place_id = selected_tag_counts_merged.place_id
   AND ranked_primary_all_time.rank = 1
   AND ranked_primary_all_time.vibe_tag_id != selected_tag_counts_merged.vibe_tag_id
),
selected_tag_counts_30 AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, third_vibe_tag_id
),
selected_tag_counts_30_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count, MIN(first_seen_at) AS first_seen_at
  FROM selected_tag_counts_30
  GROUP BY place_id, vibe_tag_id
),
primary_tag_counts_30 AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, primary_vibe_tag_id
),
ranked_primary_30 AS (
  SELECT
    primary_tag_counts_30.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, first_seen_at ASC, vibe_tag_id ASC) AS rank
  FROM primary_tag_counts_30
),
selected_tag_counts_year AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, third_vibe_tag_id
),
selected_tag_counts_year_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count, MIN(first_seen_at) AS first_seen_at
  FROM selected_tag_counts_year
  GROUP BY place_id, vibe_tag_id
),
primary_tag_counts_year AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count, MIN(created_at) AS first_seen_at
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, primary_vibe_tag_id
),
ranked_primary_year AS (
  SELECT
    primary_tag_counts_year.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, first_seen_at ASC, vibe_tag_id ASC) AS rank
  FROM primary_tag_counts_year
)
SELECT
  event_totals.place_id,
  event_totals.total_vibes,
  top_all_time.vibe_tag_id,
  ROUND((top_all_time_selected.tag_count * 100.0) / event_totals.total_vibes, 1),
  second_all_time.vibe_tag_id,
  ROUND((second_all_time.tag_count * 100.0) / event_totals.total_vibes, 1),
  event_totals.last_30_day_total_vibes,
  top_30.vibe_tag_id,
  CASE
    WHEN event_totals.last_30_day_total_vibes > 0 THEN ROUND((top_30_selected.tag_count * 100.0) / event_totals.last_30_day_total_vibes, 1)
    ELSE NULL
  END,
  event_totals.last_year_total_vibes,
  top_year.vibe_tag_id,
  CASE
    WHEN event_totals.last_year_total_vibes > 0 THEN ROUND((top_year_selected.tag_count * 100.0) / event_totals.last_year_total_vibes, 1)
    ELSE NULL
  END,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM event_totals
LEFT JOIN ranked_primary_all_time top_all_time
  ON top_all_time.place_id = event_totals.place_id AND top_all_time.rank = 1
LEFT JOIN selected_tag_counts_merged top_all_time_selected
  ON top_all_time_selected.place_id = event_totals.place_id AND top_all_time_selected.vibe_tag_id = top_all_time.vibe_tag_id
LEFT JOIN ranked_secondary_all_time second_all_time
  ON second_all_time.place_id = event_totals.place_id AND second_all_time.rank = 1
LEFT JOIN ranked_primary_30 top_30
  ON top_30.place_id = event_totals.place_id AND top_30.rank = 1
LEFT JOIN selected_tag_counts_30_merged top_30_selected
  ON top_30_selected.place_id = event_totals.place_id AND top_30_selected.vibe_tag_id = top_30.vibe_tag_id
LEFT JOIN ranked_primary_year top_year
  ON top_year.place_id = event_totals.place_id AND top_year.rank = 1
LEFT JOIN selected_tag_counts_year_merged top_year_selected
  ON top_year_selected.place_id = event_totals.place_id AND top_year_selected.vibe_tag_id = top_year.vibe_tag_id;
