INSERT OR REPLACE INTO vibe_tags (id, slug, display_name, emoji, sentiment_group, sort_order, is_active) VALUES
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
  ('emotionally_damaging', 'emotionally_damaging', 'Emotionally Damaging', '💀', 'negative', 120, 1);

INSERT OR REPLACE INTO places (
  id, provider, provider_place_id, name, latitude, longitude, street_address, city, region, country, category, created_at, updated_at
) VALUES
  ('seed_taco_window', 'seed', 'seed_taco_window', 'Joe''s Tiny Taco Window', 30.2672, -97.7431, '604 Congress Ave', 'Austin', 'TX', 'US', 'Restaurant', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('seed_mall_fountain', 'seed', 'seed_mall_fountain', 'The Mall Fountain', 30.2711, -97.7548, '100 Mall Fountain Way', 'Austin', 'TX', 'US', 'Landmark', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('seed_highway_diner', 'seed', 'seed_highway_diner', 'Highway 9 Diner', 30.3072, -97.7007, '901 Highway 9', 'Austin', 'TX', 'US', 'Restaurant', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z');

INSERT OR REPLACE INTO anonymous_users (
  id, device_id_hash, first_seen_at, last_seen_at, created_at
) VALUES
  ('anon_11111111111111111111111111111111', '1111111111111111111111111111111111111111111111111111111111111111', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('anon_22222222222222222222222222222222', '2222222222222222222222222222222222222222222222222222222222222222', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('anon_33333333333333333333333333333333', '3333333333333333333333333333333333333333333333333333333333333333', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('anon_44444444444444444444444444444444', '4444444444444444444444444444444444444444444444444444444444444444', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z');

INSERT OR REPLACE INTO vibe_events (
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
) VALUES
  ('seed_event_1', 'seed_taco_window', 'anon_11111111111111111111111111111111', 'changed_my_life', NULL, 'seed', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', 0, 0, 'active'),
  ('seed_event_2', 'seed_taco_window', 'anon_22222222222222222222222222222222', 'fire', 'iconic', 'seed', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', 0, 0, 'active'),
  ('seed_event_3', 'seed_mall_fountain', 'anon_33333333333333333333333333333333', 'emotionally_damaging', NULL, 'seed', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', 0, 0, 'active'),
  ('seed_event_4', 'seed_highway_diner', 'anon_44444444444444444444444444444444', 'worth_the_drive', NULL, 'seed', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z', 0, 0, 'active');

INSERT OR REPLACE INTO ratings (
  id, place_id, device_id_hash, score, vibe_tag, vibe_tag_secondary, created_at, updated_at
) VALUES
  ('seed_event_1', 'seed_taco_window', '1111111111111111111111111111111111111111111111111111111111111111', 10, 'Changed my Life', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('seed_event_2', 'seed_taco_window', '2222222222222222222222222222222222222222222222222222222222222222', 8, 'Fire', 'Iconic', '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('seed_event_3', 'seed_mall_fountain', '3333333333333333333333333333333333333333333333333333333333333333', 0, 'Emotionally Damaging', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z'),
  ('seed_event_4', 'seed_highway_diner', '4444444444444444444444444444444444444444444444444444444444444444', 8, 'Worth the Drive', NULL, '2026-06-23T00:00:00.000Z', '2026-06-23T00:00:00.000Z');

INSERT OR REPLACE INTO place_vibe_stats (
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
) VALUES
  ('seed_taco_window', 2, 'changed_my_life', 50.0, 'fire', 50.0, 0, NULL, NULL, 2, 'changed_my_life', 50.0, '2026-06-23T00:00:00.000Z'),
  ('seed_mall_fountain', 1, 'emotionally_damaging', 100.0, NULL, NULL, 0, NULL, NULL, 1, 'emotionally_damaging', 100.0, '2026-06-23T00:00:00.000Z'),
  ('seed_highway_diner', 1, 'worth_the_drive', 100.0, NULL, NULL, 0, NULL, NULL, 1, 'worth_the_drive', 100.0, '2026-06-23T00:00:00.000Z');

INSERT OR REPLACE INTO place_stats (
  place_id, rating_count, average_score, top_vibe_tag, updated_at
) VALUES
  ('seed_taco_window', 2, 9.0, 'Changed my Life', '2026-06-23T00:00:00.000Z'),
  ('seed_mall_fountain', 1, 0.0, 'Emotionally Damaging', '2026-06-23T00:00:00.000Z'),
  ('seed_highway_diner', 1, 8.0, 'Worth the Drive', '2026-06-23T00:00:00.000Z');

INSERT OR REPLACE INTO place_vibe_counts (
  place_id, vibe_tag, rating_count, updated_at
) VALUES
  ('seed_taco_window', 'Changed my Life', 1, '2026-06-23T00:00:00.000Z'),
  ('seed_taco_window', 'Fire', 1, '2026-06-23T00:00:00.000Z'),
  ('seed_taco_window', 'Iconic', 1, '2026-06-23T00:00:00.000Z'),
  ('seed_mall_fountain', 'Emotionally Damaging', 1, '2026-06-23T00:00:00.000Z'),
  ('seed_highway_diner', 'Worth the Drive', 1, '2026-06-23T00:00:00.000Z');
