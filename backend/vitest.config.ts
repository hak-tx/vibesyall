import { readFileSync } from "node:fs";
import { cloudflareTest } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

const schemaQueries = readFileSync("./schema.sql", "utf8")
  .split(/;\s*(?:\r?\n|$)/)
  .map((query) => query.trim())
  .filter(Boolean);

export default defineConfig({
  plugins: [
    cloudflareTest({
      main: "./src/index.ts",
      wrangler: { configPath: "./wrangler.jsonc" },
      miniflare: {
        bindings: {
          TEST_SCHEMA_QUERIES: JSON.stringify(schemaQueries),
        },
      },
    }),
  ],
  test: {
    include: ["test/**/*.spec.ts"],
  },
});
