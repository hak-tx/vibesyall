import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const wranglerConfigPath = resolve(backendDir, "wrangler.jsonc");
const env = {
  ...process.env,
  WRANGLER_LOG_PATH: process.env.WRANGLER_LOG_PATH ?? "/tmp/vibemap-wrangler.log",
};

function run(label, command, args) {
  console.log(`\n==> ${label}`);
  const result = spawnSync(command, args, {
    cwd: backendDir,
    env,
    encoding: "utf8",
  });

  if (result.stdout) {
    process.stdout.write(result.stdout);
  }
  if (result.stderr) {
    process.stderr.write(result.stderr);
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }

  return `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
}

function runOptional(label, command, args, ignoredFragments) {
  console.log(`\n==> ${label}`);
  const result = spawnSync(command, args, {
    cwd: backendDir,
    env,
    encoding: "utf8",
  });

  if (result.stdout) {
    process.stdout.write(result.stdout);
  }
  if (result.stderr) {
    process.stderr.write(result.stderr);
  }

  if (result.status !== 0) {
    const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`.toLowerCase();
    if (ignoredFragments.some((fragment) => output.includes(fragment.toLowerCase()))) {
      console.log("Optional migration already applied.");
      return output;
    }
    process.exit(result.status ?? 1);
  }

  return `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
}

function checkCloudflareAuth() {
  console.log("\n==> Checking Cloudflare auth");
  const result = spawnSync("npx", ["wrangler", "whoami", "--json"], {
    cwd: backendDir,
    env,
    encoding: "utf8",
  });

  if (result.stdout) {
    process.stdout.write(result.stdout);
  }
  if (result.stderr) {
    process.stderr.write(result.stderr);
  }
  if (result.status !== 0) {
    const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
    if (output.includes("Unable to resolve Cloudflare")) {
      console.error("\nCloudflare is unreachable from this shell. Run this command from a normal Terminal with working internet access.");
    } else {
      console.error('\nCloudflare is not authenticated. Run "npx wrangler login" once from this backend folder in a normal Terminal, then rerun this command.');
    }
    process.exit(result.status ?? 1);
  }
}

checkCloudflareAuth();

const wranglerConfig = readFileSync(wranglerConfigPath, "utf8");
if (wranglerConfig.includes("00000000-0000-0000-0000-000000000000")) {
  const createOutput = run("Creating production D1 database", "npx", [
    "wrangler",
    "d1",
    "create",
    "vibe-map",
    "--location",
    "wnam",
  ]);
  const databaseID = createOutput.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i)?.[0];
  if (!databaseID) {
    console.error("\nCould not find the created D1 database id in Wrangler output.");
    process.exit(1);
  }
  writeFileSync(
    wranglerConfigPath,
    wranglerConfig.replace("00000000-0000-0000-0000-000000000000", databaseID)
  );
} else {
  console.log("\n==> Production D1 database already configured");
}

run("Typechecking and dry-running Worker deploy", "npm", ["run", "check"]);
runOptional("Applying optional street address migration", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE places ADD COLUMN street_address TEXT",
  "--yes",
], ["duplicate column", "already exists"]);
runOptional("Applying optional category migration", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE places ADD COLUMN category TEXT",
  "--yes",
], ["duplicate column", "already exists"]);
runOptional("Applying optional third vibe migration", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE vibe_events ADD COLUMN third_vibe_tag_id TEXT REFERENCES vibe_tags(id)",
  "--yes",
], ["duplicate column", "already exists", "no such table"]);
runOptional("Applying optional vibe taxonomy version column", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE vibe_events ADD COLUMN taxonomy_version_id TEXT",
  "--yes",
], ["duplicate column", "already exists", "no such table"]);
runOptional("Applying optional vibe submission context column", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE vibe_events ADD COLUMN submission_context TEXT",
  "--yes",
], ["duplicate column", "already exists", "no such table"]);
runOptional("Applying optional vibe place snapshot column", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=ALTER TABLE vibe_events ADD COLUMN place_snapshot_json TEXT",
  "--yes",
], ["duplicate column", "already exists", "no such table"]);
run("Applying production D1 schema", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./schema.sql",
  "--yes",
]);
run("Ensuring third vibe index", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--command=CREATE INDEX IF NOT EXISTS idx_vibe_events_third_tag ON vibe_events(third_vibe_tag_id)",
  "--yes",
]);
run("Migrating vibe taxonomy data", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-06-26-vibe-taxonomy-v2.sql",
  "--yes",
]);
run("Migrating human-labeled sentiment data model", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-06-28-human-labeled-place-sentiment.sql",
  "--yes",
]);
run("Normalizing V3 vibe taxonomy", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-06-28-vibe-taxonomy-v3.sql",
  "--yes",
]);
run("Removing unreviewed place records", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-06-26-remove-unreviewed-places.sql",
  "--yes",
]);
run("Ensuring account profile tables", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-06-30-account-profiles.sql",
  "--yes",
]);
run("Ensuring admin analytics tables", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-07-04-admin-analytics.sql",
  "--yes",
]);
run("Ensuring admin device labels", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-07-04-admin-device-labels.sql",
  "--yes",
]);
run("Ensuring commercial data structure", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-07-04-commercial-data-structure.sql",
  "--yes",
]);
run("Ensuring device identity links", "npx", [
  "wrangler",
  "d1",
  "execute",
  "vibe-map",
  "--remote",
  "--file=./migrations/2026-07-04-device-identity-links.sql",
  "--yes",
]);

const deployOutput = run("Deploying Worker", "npx", ["wrangler", "deploy", "--keep-vars"]);
const workerURL = deployOutput.match(/https:\/\/[^\s]+\.workers\.dev/g)?.at(-1);

if (workerURL) {
  console.log(`\nWorker URL: ${workerURL}`);
  console.log(`Set iOS backend URL: npm run ios:set-backend-url -- ${workerURL}`);
}
