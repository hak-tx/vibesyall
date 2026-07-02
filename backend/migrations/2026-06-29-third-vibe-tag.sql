ALTER TABLE vibe_events ADD COLUMN third_vibe_tag_id TEXT REFERENCES vibe_tags(id);

CREATE INDEX IF NOT EXISTS idx_vibe_events_third_tag ON vibe_events(third_vibe_tag_id);
