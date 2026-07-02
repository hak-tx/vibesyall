import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoDir = resolve(backendDir, "..");
const url = process.argv[2];

if (!url || !/^https:\/\/[^/]+/.test(url)) {
  console.error("Usage: npm run ios:set-backend-url https://your-worker.workers.dev");
  process.exit(1);
}

function update(filePath, replacer) {
  const absolutePath = resolve(repoDir, filePath);
  const before = readFileSync(absolutePath, "utf8");
  const { found, content: after } = replacer(before);
  if (!found) {
    throw new Error(`No backend URL setting found in ${filePath}`);
  }
  writeFileSync(absolutePath, after);
}

update("project.yml", (content) =>
  ({
    found: /VIBE_MAP_BACKEND_BASE_URL: ".*"/.test(content),
    content: content.replace(/VIBE_MAP_BACKEND_BASE_URL: ".*"/, `VIBE_MAP_BACKEND_BASE_URL: "${url}"`)
  })
);

update("VibeMap.xcodeproj/project.pbxproj", (content) =>
  ({
    found: /VIBE_MAP_BACKEND_BASE_URL = ".*";/.test(content),
    content: content.replace(/VIBE_MAP_BACKEND_BASE_URL = ".*";/g, `VIBE_MAP_BACKEND_BASE_URL = "${url}";`)
  })
);

console.log(`iOS backend URL set to ${url}`);
