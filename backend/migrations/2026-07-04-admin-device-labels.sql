CREATE TABLE IF NOT EXISTS admin_device_labels (
  id TEXT PRIMARY KEY,
  identity_type TEXT NOT NULL CHECK (identity_type IN ('analytics_device', 'anonymous_user')),
  identity_id TEXT NOT NULL,
  label TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'internal' CHECK (category IN ('internal', 'reviewer', 'external', 'unknown')),
  excluded_from_core_metrics INTEGER NOT NULL DEFAULT 1,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(identity_type, identity_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_device_labels_identity ON admin_device_labels(identity_type, identity_id);
CREATE INDEX IF NOT EXISTS idx_admin_device_labels_excluded ON admin_device_labels(excluded_from_core_metrics, category);
