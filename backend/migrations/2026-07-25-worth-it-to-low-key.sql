INSERT INTO vibe_tags (id, slug, display_name, emoji, sentiment_group, sort_order, is_active) VALUES
  ('low_key', 'low_key', 'Low-key', '🌿', 'identity', 80, 1)
ON CONFLICT(id) DO UPDATE SET
  slug = excluded.slug,
  display_name = excluded.display_name,
  emoji = excluded.emoji,
  sentiment_group = excluded.sentiment_group,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

UPDATE vibe_events SET primary_vibe_tag_id = 'low_key' WHERE primary_vibe_tag_id = 'worth_it';
UPDATE vibe_events SET secondary_vibe_tag_id = 'low_key' WHERE secondary_vibe_tag_id = 'worth_it';
UPDATE vibe_events SET third_vibe_tag_id = 'low_key' WHERE third_vibe_tag_id = 'worth_it';

UPDATE place_vibe_stats SET top_vibe_tag_id = 'low_key' WHERE top_vibe_tag_id = 'worth_it';
UPDATE place_vibe_stats SET second_vibe_tag_id = 'low_key' WHERE second_vibe_tag_id = 'worth_it';
UPDATE place_vibe_stats SET last_30_day_top_vibe_tag_id = 'low_key' WHERE last_30_day_top_vibe_tag_id = 'worth_it';
UPDATE place_vibe_stats SET last_year_top_vibe_tag_id = 'low_key' WHERE last_year_top_vibe_tag_id = 'worth_it';
UPDATE place_vibe_tag_stats SET vibe_tag_id = 'low_key' WHERE vibe_tag_id = 'worth_it';

UPDATE ratings SET vibe_tag = 'Low-key' WHERE vibe_tag IN ('Worth It', 'Worth it', 'worth_it');
UPDATE ratings SET vibe_tag_secondary = 'Low-key' WHERE vibe_tag_secondary IN ('Worth It', 'Worth it', 'worth_it');
UPDATE place_stats SET top_vibe_tag = 'Low-key' WHERE top_vibe_tag IN ('Worth It', 'Worth it', 'worth_it');
UPDATE place_vibe_counts SET vibe_tag = 'Low-key' WHERE vibe_tag IN ('Worth It', 'Worth it', 'worth_it');

UPDATE vibe_tags SET is_active = 0 WHERE id = 'worth_it';

INSERT INTO taxonomy_versions (id, label, effective_at, notes, created_at) VALUES
  ('vibes_v3', 'VIBES Y''ALL V3 tag set', '2026-07-25T00:00:00.000Z', 'Replaces Worth It with the canonical Low-key tag while preserving legacy input compatibility.', '2026-07-25T00:00:00.000Z')
ON CONFLICT(id) DO UPDATE SET
  label = excluded.label,
  effective_at = excluded.effective_at,
  notes = excluded.notes;
