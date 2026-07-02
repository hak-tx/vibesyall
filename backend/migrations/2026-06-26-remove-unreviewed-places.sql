PRAGMA foreign_keys = ON;

DELETE FROM discovery_events
WHERE place_id IN (
  SELECT p.id
  FROM places p
  LEFT JOIN ratings r ON r.place_id = p.id
  GROUP BY p.id
  HAVING COUNT(r.id) = 0
);

DELETE FROM place_vibe_counts
WHERE place_id IN (
  SELECT p.id
  FROM places p
  LEFT JOIN ratings r ON r.place_id = p.id
  GROUP BY p.id
  HAVING COUNT(r.id) = 0
);

DELETE FROM place_stats
WHERE rating_count <= 0
   OR NOT EXISTS (
     SELECT 1
     FROM ratings r
     WHERE r.place_id = place_stats.place_id
   );

DELETE FROM places
WHERE NOT EXISTS (
  SELECT 1
  FROM ratings r
  WHERE r.place_id = places.id
);
