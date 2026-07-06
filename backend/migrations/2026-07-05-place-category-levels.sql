UPDATE places
SET primary_category = category
WHERE primary_category IS NULL
  AND category IS NOT NULL
  AND category != '';

CREATE INDEX IF NOT EXISTS idx_places_primary_category ON places(primary_category);
CREATE INDEX IF NOT EXISTS idx_places_provider_category ON places(provider_category);
