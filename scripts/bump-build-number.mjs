import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const projectYmlPath = join(root, "project.yml");
const pbxprojPath = join(root, "VibeMap.xcodeproj", "project.pbxproj");

const projectYml = readFileSync(projectYmlPath, "utf8");
const pbxproj = readFileSync(pbxprojPath, "utf8");

const ymlMatch = projectYml.match(/CURRENT_PROJECT_VERSION:\s*"?(\d+)"?/);
const pbxMatches = [...pbxproj.matchAll(/CURRENT_PROJECT_VERSION = (\d+);/g)];

if (!ymlMatch || pbxMatches.length === 0) {
  throw new Error("Could not find CURRENT_PROJECT_VERSION in project.yml and VibeMap.xcodeproj/project.pbxproj.");
}

const currentVersions = [
  Number(ymlMatch[1]),
  ...pbxMatches.map((match) => Number(match[1])),
];
const currentBuildNumber = Math.max(...currentVersions);
const requestedBuildNumber = process.argv[2] ? Number.parseInt(process.argv[2], 10) : null;

if (process.argv[2] && (!Number.isInteger(requestedBuildNumber) || requestedBuildNumber < 1)) {
  throw new Error("Build number must be a positive integer.");
}

if (requestedBuildNumber && requestedBuildNumber <= currentBuildNumber) {
  throw new Error(`Build number must be greater than current build ${currentBuildNumber}.`);
}

const nextBuildNumber = String(requestedBuildNumber || currentBuildNumber + 1);

const updatedProjectYml = projectYml.replace(
  /CURRENT_PROJECT_VERSION:\s*"?\d+"?/,
  `CURRENT_PROJECT_VERSION: ${nextBuildNumber}`,
);
const updatedPbxproj = pbxproj.replace(
  /CURRENT_PROJECT_VERSION = \d+;/g,
  `CURRENT_PROJECT_VERSION = ${nextBuildNumber};`,
);

writeFileSync(projectYmlPath, updatedProjectYml);
writeFileSync(pbxprojPath, updatedPbxproj);

console.log(nextBuildNumber);
