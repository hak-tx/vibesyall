CREATE TABLE IF NOT EXISTS aggregate_refresh_jobs (
  place_id TEXT PRIMARY KEY,
  requested_at TEXT NOT NULL,
  next_attempt_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  FOREIGN KEY(place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_aggregate_refresh_jobs_due
  ON aggregate_refresh_jobs(next_attempt_at, requested_at);
