INSERT INTO vibe_tags (id, slug, display_name, emoji, sentiment_group, sort_order, is_active) VALUES
  ('changed_my_life', 'changed_my_life', 'Changed my Life', '⭐', 'positive', 10, 1),
  ('fire', 'fire', 'Fire', '🔥', 'positive', 20, 1),
  ('worth_the_drive', 'worth_the_drive', 'Worth the Drive', '🚗', 'positive', 30, 1),
  ('iconic', 'iconic', 'Iconic', '🌟', 'identity', 40, 1),
  ('hidden_gem', 'hidden_gem', 'Hidden Gem', '💎', 'positive', 50, 1),
  ('underrated', 'underrated', 'Underrated', '📈', 'positive', 60, 1),
  ('mid', 'mid', 'Mid', '😐', 'neutral', 70, 1),
  ('chaos', 'chaos', 'Chaos', '🌪', 'neutral', 80, 1),
  ('overrated', 'overrated', 'Overrated', '👎', 'negative', 90, 1),
  ('tourist_trap', 'tourist_trap', 'Tourist Trap', '📸', 'negative', 100, 1),
  ('needs_prayer', 'needs_prayer', 'Needs Prayer', '🙏', 'negative', 110, 1),
  ('emotionally_damaging', 'emotionally_damaging', 'Emotionally Damaging', '💀', 'negative', 120, 1)
ON CONFLICT(id) DO UPDATE SET
  slug = excluded.slug,
  display_name = excluded.display_name,
  emoji = excluded.emoji,
  sentiment_group = excluded.sentiment_group,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

UPDATE vibe_events
SET primary_vibe_tag_id = CASE primary_vibe_tag_id
  WHEN 'changed_life' THEN 'changed_my_life'
  WHEN 'elite' THEN 'fire'
  WHEN 'inspiring' THEN 'changed_my_life'
  WHEN 'unreasonably_good' THEN 'fire'
  WHEN 'surprisingly_solid' THEN 'fire'
  WHEN 'certified' THEN 'iconic'
  WHEN 'america' THEN 'iconic'
  WHEN 'never_again' THEN 'emotionally_damaging'
  WHEN 'cringe' THEN 'emotionally_damaging'
  WHEN 'unamerican' THEN 'emotionally_damaging'
  WHEN 'un_american' THEN 'emotionally_damaging'
  ELSE primary_vibe_tag_id
END,
secondary_vibe_tag_id = CASE secondary_vibe_tag_id
  WHEN 'changed_life' THEN 'changed_my_life'
  WHEN 'elite' THEN 'fire'
  WHEN 'inspiring' THEN 'changed_my_life'
  WHEN 'unreasonably_good' THEN 'fire'
  WHEN 'surprisingly_solid' THEN 'fire'
  WHEN 'certified' THEN 'iconic'
  WHEN 'america' THEN 'iconic'
  WHEN 'never_again' THEN 'emotionally_damaging'
  WHEN 'cringe' THEN 'emotionally_damaging'
  WHEN 'unamerican' THEN 'emotionally_damaging'
  WHEN 'un_american' THEN 'emotionally_damaging'
  ELSE secondary_vibe_tag_id
END,
updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE primary_vibe_tag_id IN (
  'changed_life', 'elite', 'inspiring', 'unreasonably_good', 'surprisingly_solid', 'certified', 'america',
  'never_again', 'cringe', 'unamerican', 'un_american'
)
OR secondary_vibe_tag_id IN (
  'changed_life', 'elite', 'inspiring', 'unreasonably_good', 'surprisingly_solid', 'certified', 'america',
  'never_again', 'cringe', 'unamerican', 'un_american'
);

UPDATE vibe_events
SET secondary_vibe_tag_id = NULL
WHERE secondary_vibe_tag_id = primary_vibe_tag_id;

UPDATE ratings
SET vibe_tag = CASE vibe_tag
  WHEN 'Changed My Life' THEN 'Changed my Life'
  WHEN 'Changed my life' THEN 'Changed my Life'
  WHEN 'Elite' THEN 'Fire'
  WHEN 'Great' THEN 'Fire'
  WHEN 'Inspiring' THEN 'Changed my Life'
  WHEN 'Unreasonably good' THEN 'Fire'
  WHEN 'Surprisingly solid' THEN 'Fire'
  WHEN 'Certified' THEN 'Iconic'
  WHEN 'America' THEN 'Iconic'
  WHEN 'Never again' THEN 'Emotionally Damaging'
  WHEN 'Cringe' THEN 'Emotionally Damaging'
  WHEN 'UnAmerican' THEN 'Emotionally Damaging'
  WHEN 'Unamerican' THEN 'Emotionally Damaging'
  WHEN 'Un-American' THEN 'Emotionally Damaging'
  WHEN 'Emotionally damaging' THEN 'Emotionally Damaging'
  ELSE vibe_tag
END,
vibe_tag_secondary = CASE vibe_tag_secondary
  WHEN 'Changed My Life' THEN 'Changed my Life'
  WHEN 'Changed my life' THEN 'Changed my Life'
  WHEN 'Elite' THEN 'Fire'
  WHEN 'Great' THEN 'Fire'
  WHEN 'Inspiring' THEN 'Changed my Life'
  WHEN 'Unreasonably good' THEN 'Fire'
  WHEN 'Surprisingly solid' THEN 'Fire'
  WHEN 'Certified' THEN 'Iconic'
  WHEN 'America' THEN 'Iconic'
  WHEN 'Never again' THEN 'Emotionally Damaging'
  WHEN 'Cringe' THEN 'Emotionally Damaging'
  WHEN 'UnAmerican' THEN 'Emotionally Damaging'
  WHEN 'Unamerican' THEN 'Emotionally Damaging'
  WHEN 'Un-American' THEN 'Emotionally Damaging'
  WHEN 'Emotionally damaging' THEN 'Emotionally Damaging'
  ELSE vibe_tag_secondary
END,
updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now');

UPDATE ratings
SET vibe_tag_secondary = NULL
WHERE vibe_tag_secondary = vibe_tag;

UPDATE ratings
SET score = CASE vibe_tag
  WHEN 'Changed my Life' THEN 10.0
  WHEN 'Fire' THEN 9.0
  WHEN 'Worth the Drive' THEN 8.0
  WHEN 'Iconic' THEN 7.0
  WHEN 'Hidden Gem' THEN 6.5
  WHEN 'Underrated' THEN 6.0
  WHEN 'Mid' THEN 5.0
  WHEN 'Chaos' THEN 4.0
  WHEN 'Overrated' THEN 3.0
  WHEN 'Tourist Trap' THEN 2.0
  WHEN 'Needs Prayer' THEN 1.0
  WHEN 'Emotionally Damaging' THEN 0.0
  ELSE score
END
WHERE vibe_tag_secondary IS NULL;

UPDATE ratings
SET score = (
  (CASE vibe_tag
    WHEN 'Changed my Life' THEN 10.0
    WHEN 'Fire' THEN 9.0
    WHEN 'Worth the Drive' THEN 8.0
    WHEN 'Iconic' THEN 7.0
    WHEN 'Hidden Gem' THEN 6.5
    WHEN 'Underrated' THEN 6.0
    WHEN 'Mid' THEN 5.0
    WHEN 'Chaos' THEN 4.0
    WHEN 'Overrated' THEN 3.0
    WHEN 'Tourist Trap' THEN 2.0
    WHEN 'Needs Prayer' THEN 1.0
    WHEN 'Emotionally Damaging' THEN 0.0
    ELSE score
  END)
  +
  (CASE vibe_tag_secondary
    WHEN 'Changed my Life' THEN 10.0
    WHEN 'Fire' THEN 9.0
    WHEN 'Worth the Drive' THEN 8.0
    WHEN 'Iconic' THEN 7.0
    WHEN 'Hidden Gem' THEN 6.5
    WHEN 'Underrated' THEN 6.0
    WHEN 'Mid' THEN 5.0
    WHEN 'Chaos' THEN 4.0
    WHEN 'Overrated' THEN 3.0
    WHEN 'Tourist Trap' THEN 2.0
    WHEN 'Needs Prayer' THEN 1.0
    WHEN 'Emotionally Damaging' THEN 0.0
    ELSE score
  END)
) / 2.0
WHERE vibe_tag_secondary IS NOT NULL;

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
tag_counts AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL
  GROUP BY place_id, third_vibe_tag_id
),
tag_counts_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count
  FROM tag_counts
  GROUP BY place_id, vibe_tag_id
),
ranked_all_time AS (
  SELECT
    tag_counts_merged.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, vibe_tag_id ASC) AS rank
  FROM tag_counts_merged
),
tag_counts_30 AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-30 days')
  GROUP BY place_id, third_vibe_tag_id
),
tag_counts_30_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count
  FROM tag_counts_30
  GROUP BY place_id, vibe_tag_id
),
ranked_30 AS (
  SELECT
    tag_counts_30_merged.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, vibe_tag_id ASC) AS rank
  FROM tag_counts_30_merged
),
tag_counts_year AS (
  SELECT place_id, primary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE secondary_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS vibe_tag_id, COUNT(*) AS tag_count
  FROM active_events
  WHERE third_vibe_tag_id IS NOT NULL AND created_at >= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-365 days')
  GROUP BY place_id, third_vibe_tag_id
),
tag_counts_year_merged AS (
  SELECT place_id, vibe_tag_id, SUM(tag_count) AS tag_count
  FROM tag_counts_year
  GROUP BY place_id, vibe_tag_id
),
ranked_year AS (
  SELECT
    tag_counts_year_merged.*,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY tag_count DESC, vibe_tag_id ASC) AS rank
  FROM tag_counts_year_merged
)
SELECT
  event_totals.place_id,
  event_totals.total_vibes,
  top_all_time.vibe_tag_id,
  ROUND((top_all_time.tag_count * 100.0) / event_totals.total_vibes, 1),
  second_all_time.vibe_tag_id,
  ROUND((second_all_time.tag_count * 100.0) / event_totals.total_vibes, 1),
  event_totals.last_30_day_total_vibes,
  top_30.vibe_tag_id,
  CASE
    WHEN event_totals.last_30_day_total_vibes > 0 THEN ROUND((top_30.tag_count * 100.0) / event_totals.last_30_day_total_vibes, 1)
    ELSE NULL
  END,
  event_totals.last_year_total_vibes,
  top_year.vibe_tag_id,
  CASE
    WHEN event_totals.last_year_total_vibes > 0 THEN ROUND((top_year.tag_count * 100.0) / event_totals.last_year_total_vibes, 1)
    ELSE NULL
  END,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM event_totals
LEFT JOIN ranked_all_time top_all_time ON top_all_time.place_id = event_totals.place_id AND top_all_time.rank = 1
LEFT JOIN ranked_all_time second_all_time ON second_all_time.place_id = event_totals.place_id AND second_all_time.rank = 2
LEFT JOIN ranked_30 top_30 ON top_30.place_id = event_totals.place_id AND top_30.rank = 1
LEFT JOIN ranked_year top_year ON top_year.place_id = event_totals.place_id AND top_year.rank = 1;

DELETE FROM place_vibe_counts;

INSERT INTO place_vibe_counts (place_id, vibe_tag, rating_count, updated_at)
WITH active_tag_counts AS (
  SELECT place_id, primary_vibe_tag_id AS tag_id, COUNT(*) AS rating_count
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0
  GROUP BY place_id, primary_vibe_tag_id
  UNION ALL
  SELECT place_id, secondary_vibe_tag_id AS tag_id, COUNT(*) AS rating_count
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0 AND secondary_vibe_tag_id IS NOT NULL
  GROUP BY place_id, secondary_vibe_tag_id
  UNION ALL
  SELECT place_id, third_vibe_tag_id AS tag_id, COUNT(*) AS rating_count
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0 AND third_vibe_tag_id IS NOT NULL
  GROUP BY place_id, third_vibe_tag_id
),
merged AS (
  SELECT place_id, tag_id, SUM(rating_count) AS rating_count
  FROM active_tag_counts
  GROUP BY place_id, tag_id
)
SELECT
  place_id,
  CASE tag_id
    WHEN 'changed_my_life' THEN 'Changed my Life'
    WHEN 'fire' THEN 'Fire'
    WHEN 'worth_the_drive' THEN 'Worth the Drive'
    WHEN 'iconic' THEN 'Iconic'
    WHEN 'hidden_gem' THEN 'Hidden Gem'
    WHEN 'underrated' THEN 'Underrated'
    WHEN 'mid' THEN 'Mid'
    WHEN 'chaos' THEN 'Chaos'
    WHEN 'overrated' THEN 'Overrated'
    WHEN 'tourist_trap' THEN 'Tourist Trap'
    WHEN 'needs_prayer' THEN 'Needs Prayer'
    WHEN 'emotionally_damaging' THEN 'Emotionally Damaging'
    ELSE tag_id
  END,
  rating_count,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM merged;

DELETE FROM place_stats;

INSERT INTO place_stats (place_id, rating_count, average_score, top_vibe_tag, updated_at)
WITH event_scores AS (
  SELECT
    place_id,
    (
      CASE primary_vibe_tag_id
        WHEN 'changed_my_life' THEN 10.0
        WHEN 'fire' THEN 9.0
        WHEN 'worth_the_drive' THEN 8.0
        WHEN 'iconic' THEN 7.0
        WHEN 'hidden_gem' THEN 6.5
        WHEN 'underrated' THEN 6.0
        WHEN 'mid' THEN 5.0
        WHEN 'chaos' THEN 4.0
        WHEN 'overrated' THEN 3.0
        WHEN 'tourist_trap' THEN 2.0
        WHEN 'needs_prayer' THEN 1.0
        WHEN 'emotionally_damaging' THEN 0.0
        ELSE 0.0
      END
      +
      CASE
        WHEN secondary_vibe_tag_id IS NULL THEN
          CASE primary_vibe_tag_id
            WHEN 'changed_my_life' THEN 10.0
            WHEN 'fire' THEN 9.0
            WHEN 'worth_the_drive' THEN 8.0
            WHEN 'iconic' THEN 7.0
            WHEN 'hidden_gem' THEN 6.5
            WHEN 'underrated' THEN 6.0
            WHEN 'mid' THEN 5.0
            WHEN 'chaos' THEN 4.0
            WHEN 'overrated' THEN 3.0
            WHEN 'tourist_trap' THEN 2.0
            WHEN 'needs_prayer' THEN 1.0
            WHEN 'emotionally_damaging' THEN 0.0
            ELSE 0.0
          END
        ELSE
          CASE secondary_vibe_tag_id
            WHEN 'changed_my_life' THEN 10.0
            WHEN 'fire' THEN 9.0
            WHEN 'worth_the_drive' THEN 8.0
            WHEN 'iconic' THEN 7.0
            WHEN 'hidden_gem' THEN 6.5
            WHEN 'underrated' THEN 6.0
            WHEN 'mid' THEN 5.0
            WHEN 'chaos' THEN 4.0
            WHEN 'overrated' THEN 3.0
            WHEN 'tourist_trap' THEN 2.0
            WHEN 'needs_prayer' THEN 1.0
            WHEN 'emotionally_damaging' THEN 0.0
            ELSE 0.0
          END
      END
    ) / 2.0 AS score
  FROM vibe_events
  WHERE moderation_status = 'active' AND is_deleted = 0
),
stats AS (
  SELECT place_id, COUNT(*) AS rating_count, ROUND(AVG(score), 1) AS average_score
  FROM event_scores
  GROUP BY place_id
),
ranked_counts AS (
  SELECT
    place_id,
    vibe_tag,
    rating_count,
    ROW_NUMBER() OVER (PARTITION BY place_id ORDER BY rating_count DESC, vibe_tag ASC) AS rank
  FROM place_vibe_counts
)
SELECT
  stats.place_id,
  stats.rating_count,
  stats.average_score,
  ranked_counts.vibe_tag,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM stats
LEFT JOIN ranked_counts ON ranked_counts.place_id = stats.place_id AND ranked_counts.rank = 1;
