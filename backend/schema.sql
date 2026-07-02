PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS places (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  provider_place_id TEXT,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  street_address TEXT,
  city TEXT,
  region TEXT,
  country TEXT,
  category TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(provider, provider_place_id)
);

CREATE TABLE IF NOT EXISTS vibe_tags (
  id TEXT PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  emoji TEXT,
  sentiment_group TEXT NOT NULL CHECK (sentiment_group IN ('positive', 'neutral', 'negative', 'identity')),
  sort_order INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS anonymous_users (
  id TEXT PRIMARY KEY,
  device_id_hash TEXT UNIQUE NOT NULL,
  first_seen_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS anonymous_user_aliases (
  primary_anonymous_user_id TEXT NOT NULL,
  alias_anonymous_user_id TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(primary_anonymous_user_id, alias_anonymous_user_id),
  FOREIGN KEY(primary_anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE,
  FOREIGN KEY(alias_anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE,
  CHECK(primary_anonymous_user_id <> alias_anonymous_user_id)
);

CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  email_normalized TEXT UNIQUE NOT NULL,
  email_hash TEXT UNIQUE NOT NULL,
  email_verified_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS profile_devices (
  profile_id TEXT NOT NULL,
  anonymous_user_id TEXT NOT NULL,
  device_id_hash TEXT NOT NULL,
  linked_at TEXT NOT NULL,
  PRIMARY KEY(profile_id, anonymous_user_id),
  UNIQUE(device_id_hash),
  FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY(anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS email_confirmation_tokens (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  token_hash TEXT UNIQUE NOT NULL,
  purpose TEXT NOT NULL DEFAULT 'email_confirmation' CHECK (purpose IN ('email_confirmation', 'login')),
  redirect_url TEXT,
  expires_at TEXT NOT NULL,
  consumed_at TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS profile_sessions (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  token_hash TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  revoked_at TEXT,
  FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vibe_events (
  id TEXT PRIMARY KEY,
  place_id TEXT NOT NULL,
  anonymous_user_id TEXT NOT NULL,
  primary_vibe_tag_id TEXT NOT NULL,
  secondary_vibe_tag_id TEXT,
  third_vibe_tag_id TEXT,
  source TEXT NOT NULL,
  app_version TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_flagged INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  moderation_status TEXT NOT NULL DEFAULT 'active' CHECK (moderation_status IN ('active', 'flagged', 'hidden', 'deleted')),
  UNIQUE(place_id, anonymous_user_id),
  CHECK (secondary_vibe_tag_id IS NULL OR secondary_vibe_tag_id != primary_vibe_tag_id),
  CHECK (third_vibe_tag_id IS NULL OR third_vibe_tag_id != primary_vibe_tag_id),
  CHECK (third_vibe_tag_id IS NULL OR secondary_vibe_tag_id IS NULL OR third_vibe_tag_id != secondary_vibe_tag_id),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE,
  FOREIGN KEY(anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE,
  FOREIGN KEY(primary_vibe_tag_id) REFERENCES vibe_tags(id),
  FOREIGN KEY(secondary_vibe_tag_id) REFERENCES vibe_tags(id),
  FOREIGN KEY(third_vibe_tag_id) REFERENCES vibe_tags(id)
);

CREATE TABLE IF NOT EXISTS place_vibe_stats (
  place_id TEXT PRIMARY KEY,
  total_vibes INTEGER NOT NULL DEFAULT 0,
  top_vibe_tag_id TEXT,
  top_vibe_percent REAL,
  second_vibe_tag_id TEXT,
  second_vibe_percent REAL,
  last_30_day_total_vibes INTEGER NOT NULL DEFAULT 0,
  last_30_day_top_vibe_tag_id TEXT,
  last_30_day_top_vibe_percent REAL,
  last_year_total_vibes INTEGER NOT NULL DEFAULT 0,
  last_year_top_vibe_tag_id TEXT,
  last_year_top_vibe_percent REAL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE,
  FOREIGN KEY(top_vibe_tag_id) REFERENCES vibe_tags(id),
  FOREIGN KEY(second_vibe_tag_id) REFERENCES vibe_tags(id),
  FOREIGN KEY(last_30_day_top_vibe_tag_id) REFERENCES vibe_tags(id),
  FOREIGN KEY(last_year_top_vibe_tag_id) REFERENCES vibe_tags(id)
);

CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  place_id TEXT NOT NULL,
  anonymous_user_id TEXT,
  reason TEXT NOT NULL CHECK (reason IN ('wrong_place', 'duplicate_place', 'spam_or_brigading', 'inappropriate', 'other')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'reviewed', 'dismissed', 'action_taken')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE,
  FOREIGN KEY(anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS ratings (
  id TEXT PRIMARY KEY,
  place_id TEXT NOT NULL,
  device_id_hash TEXT NOT NULL,
  score REAL NOT NULL CHECK (score >= 0 AND score <= 10),
  vibe_tag TEXT NOT NULL,
  vibe_tag_secondary TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(place_id, device_id_hash),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS place_stats (
  place_id TEXT PRIMARY KEY,
  rating_count INTEGER NOT NULL,
  average_score REAL NOT NULL,
  top_vibe_tag TEXT,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS place_vibe_counts (
  place_id TEXT NOT NULL,
  vibe_tag TEXT NOT NULL,
  rating_count INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY(place_id, vibe_tag),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS discovery_events (
  id TEXT PRIMARY KEY,
  place_id TEXT NOT NULL,
  rating_id TEXT,
  event_type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(place_id, event_type),
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_places_provider_place_id ON places(provider, provider_place_id);
CREATE INDEX IF NOT EXISTS idx_places_lat_lng ON places(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_places_lng_lat ON places(longitude, latitude);
CREATE INDEX IF NOT EXISTS idx_vibe_tags_active_sort ON vibe_tags(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_anonymous_users_device_hash ON anonymous_users(device_id_hash);
CREATE INDEX IF NOT EXISTS idx_anonymous_user_aliases_primary ON anonymous_user_aliases(primary_anonymous_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email_normalized ON profiles(email_normalized);
CREATE INDEX IF NOT EXISTS idx_profiles_email_hash ON profiles(email_hash);
CREATE INDEX IF NOT EXISTS idx_profile_devices_anonymous_user ON profile_devices(anonymous_user_id);
CREATE INDEX IF NOT EXISTS idx_email_confirmation_tokens_profile ON email_confirmation_tokens(profile_id);
CREATE INDEX IF NOT EXISTS idx_email_confirmation_tokens_expires ON email_confirmation_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_profile_sessions_profile ON profile_sessions(profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_sessions_expires ON profile_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_vibe_events_place_id ON vibe_events(place_id);
CREATE INDEX IF NOT EXISTS idx_vibe_events_user_place ON vibe_events(anonymous_user_id, place_id);
CREATE INDEX IF NOT EXISTS idx_vibe_events_primary_tag ON vibe_events(primary_vibe_tag_id);
CREATE INDEX IF NOT EXISTS idx_vibe_events_secondary_tag ON vibe_events(secondary_vibe_tag_id);
CREATE INDEX IF NOT EXISTS idx_vibe_events_third_tag ON vibe_events(third_vibe_tag_id);
CREATE INDEX IF NOT EXISTS idx_vibe_events_created_at ON vibe_events(created_at);
CREATE INDEX IF NOT EXISTS idx_vibe_events_active_place ON vibe_events(place_id, moderation_status, is_deleted);
CREATE INDEX IF NOT EXISTS idx_vibe_events_active_tags ON vibe_events(place_id, moderation_status, is_deleted, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id);
CREATE INDEX IF NOT EXISTS idx_place_vibe_stats_total ON place_vibe_stats(total_vibes);
CREATE INDEX IF NOT EXISTS idx_reports_place_status ON reports(place_id, status);
CREATE INDEX IF NOT EXISTS idx_ratings_place_id ON ratings(place_id);
CREATE INDEX IF NOT EXISTS idx_ratings_device_place ON ratings(device_id_hash, place_id);
CREATE INDEX IF NOT EXISTS idx_ratings_place_vibe_primary ON ratings(place_id, vibe_tag);
CREATE INDEX IF NOT EXISTS idx_ratings_place_vibe_secondary ON ratings(place_id, vibe_tag_secondary);
CREATE INDEX IF NOT EXISTS idx_place_stats_rating_count ON place_stats(rating_count);
CREATE INDEX IF NOT EXISTS idx_place_vibe_counts_tag_count ON place_vibe_counts(vibe_tag, rating_count DESC, place_id);
CREATE INDEX IF NOT EXISTS idx_discovery_events_place_type ON discovery_events(place_id, event_type);

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

INSERT OR IGNORE INTO anonymous_users (id, device_id_hash, first_seen_at, last_seen_at, created_at)
SELECT
  'anon_' || substr(device_id_hash, 1, 32),
  device_id_hash,
  MIN(created_at),
  MAX(updated_at),
  MIN(created_at)
FROM ratings
GROUP BY device_id_hash;

INSERT INTO vibe_events (
  id,
  place_id,
  anonymous_user_id,
  primary_vibe_tag_id,
  secondary_vibe_tag_id,
  source,
  app_version,
  created_at,
  updated_at,
  is_flagged,
  is_deleted,
  moderation_status
)
WITH mapped_ratings AS (
  SELECT
    ratings.id,
    ratings.place_id,
    anonymous_users.id AS anonymous_user_id,
    CASE ratings.vibe_tag
      WHEN 'Changed My Life' THEN 'changed_my_life'
      WHEN 'Changed my life' THEN 'changed_my_life'
      WHEN 'Changed my Life' THEN 'changed_my_life'
      WHEN 'Fire' THEN 'fire'
      WHEN 'Elite' THEN 'fire'
      WHEN 'Inspiring' THEN 'changed_my_life'
      WHEN 'Unreasonably good' THEN 'fire'
      WHEN 'Surprisingly solid' THEN 'fire'
      WHEN 'Certified' THEN 'iconic'
      WHEN 'Worth the Drive' THEN 'worth_the_drive'
      WHEN 'Worth the drive' THEN 'worth_the_drive'
      WHEN 'America' THEN 'iconic'
      WHEN 'Iconic' THEN 'iconic'
      WHEN 'Hidden Gem' THEN 'hidden_gem'
      WHEN 'Hidden gem' THEN 'hidden_gem'
      WHEN 'Underrated' THEN 'underrated'
      WHEN 'Mid' THEN 'mid'
      WHEN 'Chaos' THEN 'chaos'
      WHEN 'Overrated' THEN 'overrated'
      WHEN 'Tourist Trap' THEN 'tourist_trap'
      WHEN 'Tourist trap' THEN 'tourist_trap'
      WHEN 'Needs Prayer' THEN 'needs_prayer'
      WHEN 'Needs prayer' THEN 'needs_prayer'
      WHEN 'Cringe' THEN 'emotionally_damaging'
      WHEN 'UnAmerican' THEN 'emotionally_damaging'
      WHEN 'Unamerican' THEN 'emotionally_damaging'
      WHEN 'Un-American' THEN 'emotionally_damaging'
      WHEN 'Never again' THEN 'emotionally_damaging'
      WHEN 'Emotionally Damaging' THEN 'emotionally_damaging'
      WHEN 'Emotionally damaging' THEN 'emotionally_damaging'
      ELSE 'mid'
    END AS primary_vibe_tag_id,
    CASE ratings.vibe_tag_secondary
      WHEN 'Changed My Life' THEN 'changed_my_life'
      WHEN 'Changed my life' THEN 'changed_my_life'
      WHEN 'Changed my Life' THEN 'changed_my_life'
      WHEN 'Fire' THEN 'fire'
      WHEN 'Elite' THEN 'fire'
      WHEN 'Inspiring' THEN 'changed_my_life'
      WHEN 'Unreasonably good' THEN 'fire'
      WHEN 'Surprisingly solid' THEN 'fire'
      WHEN 'Certified' THEN 'iconic'
      WHEN 'Worth the Drive' THEN 'worth_the_drive'
      WHEN 'Worth the drive' THEN 'worth_the_drive'
      WHEN 'America' THEN 'iconic'
      WHEN 'Iconic' THEN 'iconic'
      WHEN 'Hidden Gem' THEN 'hidden_gem'
      WHEN 'Hidden gem' THEN 'hidden_gem'
      WHEN 'Underrated' THEN 'underrated'
      WHEN 'Mid' THEN 'mid'
      WHEN 'Chaos' THEN 'chaos'
      WHEN 'Overrated' THEN 'overrated'
      WHEN 'Tourist Trap' THEN 'tourist_trap'
      WHEN 'Tourist trap' THEN 'tourist_trap'
      WHEN 'Needs Prayer' THEN 'needs_prayer'
      WHEN 'Needs prayer' THEN 'needs_prayer'
      WHEN 'Cringe' THEN 'emotionally_damaging'
      WHEN 'UnAmerican' THEN 'emotionally_damaging'
      WHEN 'Unamerican' THEN 'emotionally_damaging'
      WHEN 'Un-American' THEN 'emotionally_damaging'
      WHEN 'Never again' THEN 'emotionally_damaging'
      WHEN 'Emotionally Damaging' THEN 'emotionally_damaging'
      WHEN 'Emotionally damaging' THEN 'emotionally_damaging'
      ELSE NULL
    END AS secondary_vibe_tag_id,
    ratings.created_at,
    ratings.updated_at
  FROM ratings
  JOIN anonymous_users ON anonymous_users.device_id_hash = ratings.device_id_hash
)
SELECT
  id,
  place_id,
  anonymous_user_id,
  primary_vibe_tag_id,
  CASE
    WHEN secondary_vibe_tag_id = primary_vibe_tag_id THEN NULL
    ELSE secondary_vibe_tag_id
  END,
  'ios',
  NULL,
  created_at,
  updated_at,
  0,
  0,
  'active'
FROM mapped_ratings
WHERE 1 = 1
ON CONFLICT(place_id, anonymous_user_id) DO UPDATE SET
  primary_vibe_tag_id = excluded.primary_vibe_tag_id,
  secondary_vibe_tag_id = CASE
    WHEN excluded.secondary_vibe_tag_id = excluded.primary_vibe_tag_id THEN NULL
    ELSE excluded.secondary_vibe_tag_id
  END,
  updated_at = excluded.updated_at,
  is_deleted = 0,
  moderation_status = 'active';

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
