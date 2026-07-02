CREATE INDEX IF NOT EXISTS idx_places_lat_lng ON places(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_places_lng_lat ON places(longitude, latitude);
CREATE INDEX IF NOT EXISTS idx_vibe_events_active_tags ON vibe_events(place_id, moderation_status, is_deleted, primary_vibe_tag_id, secondary_vibe_tag_id, third_vibe_tag_id);
