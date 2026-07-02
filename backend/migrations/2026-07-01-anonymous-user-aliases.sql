PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS anonymous_user_aliases (
  primary_anonymous_user_id TEXT NOT NULL,
  alias_anonymous_user_id TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(primary_anonymous_user_id, alias_anonymous_user_id),
  FOREIGN KEY(primary_anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE,
  FOREIGN KEY(alias_anonymous_user_id) REFERENCES anonymous_users(id) ON DELETE CASCADE,
  CHECK(primary_anonymous_user_id <> alias_anonymous_user_id)
);

CREATE INDEX IF NOT EXISTS idx_anonymous_user_aliases_primary
  ON anonymous_user_aliases(primary_anonymous_user_id);
