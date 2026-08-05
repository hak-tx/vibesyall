-- Repairs vibe_events overwritten by the legacy ratings backfill at
-- 2026-07-30T14:11:47.193Z. The immutable analytics event is preferred when
-- available because it preserves all three ordered selections. Older rows
-- predate complete analytics identity linking, so their first two selections
-- are recovered from the legacy ratings mirror.

WITH latest_submission AS (
  SELECT
    links.anonymous_user_id,
    json_extract(events.properties_json, '$.place_id') AS place_id,
    json_extract(events.properties_json, '$.primary_vibe_tag_id') AS primary_tag,
    json_extract(events.properties_json, '$.secondary_vibe_tag_id') AS secondary_tag,
    json_extract(events.properties_json, '$.third_vibe_tag_id') AS third_tag,
    ROW_NUMBER() OVER (
      PARTITION BY links.anonymous_user_id, json_extract(events.properties_json, '$.place_id')
      ORDER BY events.created_at DESC, events.id DESC
    ) AS rank
  FROM analytics_events AS events
  JOIN device_identity_links AS links
    ON links.analytics_device_id = events.analytics_device_id
  WHERE events.event_name = 'vibe_submitted'
    AND events.created_at < '2026-07-30T14:11:47.193Z'
),
rating_recovery AS (
  SELECT
    ratings.place_id,
    users.id AS anonymous_user_id,
    CASE lower(ratings.vibe_tag)
      WHEN 'changed my life' THEN 'changed_my_life'
      WHEN 'fire' THEN 'fire'
      WHEN 'worth the drive' THEN 'worth_the_drive'
      WHEN 'iconic' THEN 'iconic'
      WHEN 'hidden gem' THEN 'hidden_gem'
      WHEN 'underrated' THEN 'underrated'
      WHEN 'bougie' THEN 'bougie'
      WHEN 'worth it' THEN 'low_key'
      WHEN 'low-key' THEN 'low_key'
      WHEN 'mid' THEN 'mid'
      WHEN 'chaos' THEN 'chaos'
      WHEN 'overrated' THEN 'overrated'
      WHEN 'tourist trap' THEN 'tourist_trap'
      WHEN 'needs prayer' THEN 'needs_prayer'
      WHEN 'emotionally damaging' THEN 'emotionally_damaging'
    END AS primary_tag,
    CASE lower(ratings.vibe_tag_secondary)
      WHEN 'changed my life' THEN 'changed_my_life'
      WHEN 'fire' THEN 'fire'
      WHEN 'worth the drive' THEN 'worth_the_drive'
      WHEN 'iconic' THEN 'iconic'
      WHEN 'hidden gem' THEN 'hidden_gem'
      WHEN 'underrated' THEN 'underrated'
      WHEN 'bougie' THEN 'bougie'
      WHEN 'worth it' THEN 'low_key'
      WHEN 'low-key' THEN 'low_key'
      WHEN 'mid' THEN 'mid'
      WHEN 'chaos' THEN 'chaos'
      WHEN 'overrated' THEN 'overrated'
      WHEN 'tourist trap' THEN 'tourist_trap'
      WHEN 'needs prayer' THEN 'needs_prayer'
      WHEN 'emotionally damaging' THEN 'emotionally_damaging'
    END AS secondary_tag
  FROM ratings
  JOIN anonymous_users AS users
    ON users.device_id_hash = ratings.device_id_hash
),
recovery AS (
  SELECT
    ratings.place_id,
    ratings.anonymous_user_id,
    COALESCE(
      CASE submissions.primary_tag WHEN 'worth_it' THEN 'low_key' ELSE submissions.primary_tag END,
      ratings.primary_tag
    ) AS primary_tag,
    COALESCE(
      CASE submissions.secondary_tag WHEN 'worth_it' THEN 'low_key' ELSE submissions.secondary_tag END,
      ratings.secondary_tag
    ) AS secondary_tag,
    CASE submissions.third_tag WHEN 'worth_it' THEN 'low_key' ELSE submissions.third_tag END AS third_tag
  FROM rating_recovery AS ratings
  LEFT JOIN latest_submission AS submissions
    ON submissions.anonymous_user_id = ratings.anonymous_user_id
   AND submissions.place_id = ratings.place_id
   AND submissions.rank = 1
  WHERE ratings.primary_tag IS NOT NULL
)
UPDATE vibe_events AS events
SET
  primary_vibe_tag_id = (
    SELECT recovery.primary_tag
    FROM recovery
    WHERE recovery.place_id = events.place_id
      AND recovery.anonymous_user_id = events.anonymous_user_id
  ),
  secondary_vibe_tag_id = (
    SELECT CASE
      WHEN recovery.secondary_tag = recovery.primary_tag THEN NULL
      ELSE recovery.secondary_tag
    END
    FROM recovery
    WHERE recovery.place_id = events.place_id
      AND recovery.anonymous_user_id = events.anonymous_user_id
  ),
  third_vibe_tag_id = (
    SELECT CASE
      WHEN recovery.third_tag IN (recovery.primary_tag, recovery.secondary_tag) THEN NULL
      ELSE recovery.third_tag
    END
    FROM recovery
    WHERE recovery.place_id = events.place_id
      AND recovery.anonymous_user_id = events.anonymous_user_id
  )
WHERE events.updated_at = '2026-07-30T14:11:47.193Z'
  AND EXISTS (
    SELECT 1
    FROM recovery
    WHERE recovery.place_id = events.place_id
      AND recovery.anonymous_user_id = events.anonymous_user_id
  );

-- Queue all affected places for the complete asynchronous aggregate rebuild.
INSERT INTO aggregate_refresh_jobs (
  place_id,
  requested_at,
  next_attempt_at,
  attempts,
  last_error
)
SELECT DISTINCT
  place_id,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
  0,
  NULL
FROM vibe_events
WHERE updated_at = '2026-07-30T14:11:47.193Z'
ON CONFLICT(place_id) DO UPDATE SET
  requested_at = excluded.requested_at,
  next_attempt_at = excluded.next_attempt_at,
  attempts = 0,
  last_error = NULL;
