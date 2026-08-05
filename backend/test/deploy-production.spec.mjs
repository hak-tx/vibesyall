import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const deployScript = readFileSync(new URL("../scripts/deploy-production.mjs", import.meta.url), "utf8");
const legacyImport = readFileSync(
  new URL("../migrations/2026-06-28-human-labeled-place-sentiment.sql", import.meta.url),
  "utf8"
);

test("routine production deploys do not replay historical vibe backfills", () => {
  for (const migration of [
    "2026-06-26-vibe-taxonomy-v2.sql",
    "2026-06-28-human-labeled-place-sentiment.sql",
    "2026-06-28-vibe-taxonomy-v3.sql",
  ]) {
    assert.equal(deployScript.includes(migration), false, `${migration} must remain one-time only`);
  }
});

test("the legacy ratings import never overwrites an existing vibe event", () => {
  const eventImport = legacyImport.slice(
    legacyImport.indexOf("INSERT INTO vibe_events"),
    legacyImport.indexOf("DELETE FROM place_vibe_stats")
  );

  assert.match(eventImport, /ON CONFLICT\(place_id, anonymous_user_id\) DO NOTHING;/);
  assert.doesNotMatch(eventImport, /ON CONFLICT\(place_id, anonymous_user_id\) DO UPDATE SET/);
});
