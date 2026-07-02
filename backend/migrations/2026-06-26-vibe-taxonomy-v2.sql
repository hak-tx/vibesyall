UPDATE ratings
SET vibe_tag = CASE vibe_tag
  WHEN 'Unreasonably good' THEN 'Certified'
  WHEN 'Worth the drive' THEN 'Worth the Drive'
  WHEN 'Surprisingly solid' THEN 'Certified'
  WHEN 'Needs prayer' THEN 'Needs Prayer'
  WHEN 'Tourist trap' THEN 'Tourist Trap'
  WHEN 'Never again' THEN 'Emotionally Damaging'
  WHEN 'Emotionally damaging' THEN 'Emotionally Damaging'
  ELSE vibe_tag
END;

UPDATE ratings
SET vibe_tag_secondary = CASE vibe_tag_secondary
  WHEN 'Unreasonably good' THEN 'Certified'
  WHEN 'Worth the drive' THEN 'Worth the Drive'
  WHEN 'Surprisingly solid' THEN 'Certified'
  WHEN 'Needs prayer' THEN 'Needs Prayer'
  WHEN 'Tourist trap' THEN 'Tourist Trap'
  WHEN 'Never again' THEN 'Emotionally Damaging'
  WHEN 'Emotionally damaging' THEN 'Emotionally Damaging'
  ELSE vibe_tag_secondary
END
WHERE vibe_tag_secondary IS NOT NULL;

UPDATE ratings
SET vibe_tag_secondary = NULL
WHERE vibe_tag_secondary = vibe_tag;

UPDATE ratings
SET score = (
  CASE vibe_tag
    WHEN 'Changed My Life' THEN 10.0
    WHEN 'Elite' THEN 9.6
    WHEN 'Inspiring' THEN 9.3
    WHEN 'Certified' THEN 9.0
    WHEN 'Worth the Drive' THEN 8.0
    WHEN 'America' THEN 6.0
    WHEN 'Mid' THEN 5.0
    WHEN 'Chaos' THEN 4.0
    WHEN 'Overrated' THEN 3.0
    WHEN 'Tourist Trap' THEN 2.0
    WHEN 'Needs Prayer' THEN 1.5
    WHEN 'Cringe' THEN 1.0
    WHEN 'UnAmerican' THEN 0.5
    WHEN 'Emotionally Damaging' THEN 0.0
    ELSE score
  END
  +
  CASE
    WHEN vibe_tag_secondary IS NULL THEN 0.0
    ELSE CASE vibe_tag_secondary
      WHEN 'Changed My Life' THEN 10.0
      WHEN 'Elite' THEN 9.6
      WHEN 'Inspiring' THEN 9.3
      WHEN 'Certified' THEN 9.0
      WHEN 'Worth the Drive' THEN 8.0
      WHEN 'America' THEN 6.0
      WHEN 'Mid' THEN 5.0
      WHEN 'Chaos' THEN 4.0
      WHEN 'Overrated' THEN 3.0
      WHEN 'Tourist Trap' THEN 2.0
      WHEN 'Needs Prayer' THEN 1.5
      WHEN 'Cringe' THEN 1.0
      WHEN 'UnAmerican' THEN 0.5
      WHEN 'Emotionally Damaging' THEN 0.0
      ELSE 0.0
    END
  END
) / CASE WHEN vibe_tag_secondary IS NULL THEN 1.0 ELSE 2.0 END;

DELETE FROM place_vibe_counts;

INSERT INTO place_vibe_counts (place_id, vibe_tag, rating_count, updated_at)
SELECT place_id, vibe_tag, COUNT(*) AS rating_count, MAX(updated_at) AS updated_at
FROM (
  SELECT place_id, vibe_tag, updated_at FROM ratings
  UNION ALL
  SELECT place_id, vibe_tag_secondary AS vibe_tag, updated_at FROM ratings WHERE vibe_tag_secondary IS NOT NULL
)
GROUP BY place_id, vibe_tag;

DELETE FROM place_stats;

INSERT INTO place_stats (place_id, rating_count, average_score, top_vibe_tag, updated_at)
WITH aggregate_stats AS (
  SELECT place_id, COUNT(*) AS rating_count, AVG(score) AS average_score, MAX(updated_at) AS updated_at
  FROM ratings
  GROUP BY place_id
),
ranked_vibes AS (
  SELECT
    place_id,
    vibe_tag,
    rating_count,
    updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY place_id
      ORDER BY rating_count DESC, updated_at DESC, vibe_tag ASC
    ) AS rank
  FROM place_vibe_counts
)
SELECT
  aggregate_stats.place_id,
  aggregate_stats.rating_count,
  aggregate_stats.average_score,
  ranked_vibes.vibe_tag,
  aggregate_stats.updated_at
FROM aggregate_stats
LEFT JOIN ranked_vibes
  ON ranked_vibes.place_id = aggregate_stats.place_id
  AND ranked_vibes.rank = 1;
