INSERT INTO vibe_tags (id, slug, display_name, emoji, sentiment_group, sort_order, is_active) VALUES
  ('bougie', 'bougie', 'Bougie', '👑', 'identity', 70, 1),
  ('worth_it', 'worth_it', 'Worth It', '✅', 'positive', 80, 1)
ON CONFLICT(id) DO UPDATE SET
  slug = excluded.slug,
  display_name = excluded.display_name,
  emoji = excluded.emoji,
  sentiment_group = excluded.sentiment_group,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

UPDATE vibe_tags SET sort_order = 90 WHERE id = 'mid';
UPDATE vibe_tags SET sort_order = 100 WHERE id = 'chaos';
UPDATE vibe_tags SET sort_order = 110 WHERE id = 'overrated';
UPDATE vibe_tags SET sort_order = 120 WHERE id = 'tourist_trap';
UPDATE vibe_tags SET sort_order = 130 WHERE id = 'needs_prayer';
UPDATE vibe_tags SET sort_order = 140 WHERE id = 'emotionally_damaging';

INSERT INTO taxonomy_versions (id, label, effective_at, notes, created_at) VALUES
  ('vibes_v2', 'VIBES Y''ALL V2 tag set', '2026-07-09T00:00:00.000Z', 'Adds Bougie and Worth It while preserving one-to-three ordered vibe labels.', '2026-07-09T00:00:00.000Z')
ON CONFLICT(id) DO UPDATE SET
  label = excluded.label,
  effective_at = excluded.effective_at,
  notes = excluded.notes;
