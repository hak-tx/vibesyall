PRAGMA foreign_keys = ON;

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

CREATE INDEX IF NOT EXISTS idx_profiles_email_normalized ON profiles(email_normalized);
CREATE INDEX IF NOT EXISTS idx_profiles_email_hash ON profiles(email_hash);
CREATE INDEX IF NOT EXISTS idx_profile_devices_anonymous_user ON profile_devices(anonymous_user_id);
CREATE INDEX IF NOT EXISTS idx_email_confirmation_tokens_profile ON email_confirmation_tokens(profile_id);
CREATE INDEX IF NOT EXISTS idx_email_confirmation_tokens_expires ON email_confirmation_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_profile_sessions_profile ON profile_sessions(profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_sessions_expires ON profile_sessions(expires_at);
