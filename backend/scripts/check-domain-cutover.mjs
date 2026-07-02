import { resolve4, resolveCname, resolveNs } from "node:dns/promises";

const domains = ["vibesyall.com", "www.vibesyall.com", "api.vibesyall.com"];
const urls = [
  "https://vibesyall.com/health",
  "https://www.vibesyall.com/",
  "https://api.vibesyall.com/health",
];

async function dnsRecord(domain) {
  const parts = [];
  try {
    const ns = await resolveNs(domain);
    parts.push(`NS=${ns.join(",")}`);
  } catch {}
  try {
    const cname = await resolveCname(domain);
    parts.push(`CNAME=${cname.join(",")}`);
  } catch {}
  try {
    const a = await resolve4(domain);
    parts.push(`A=${a.join(",")}`);
  } catch {}
  return parts.length ? parts.join(" ") : "no public DNS record found";
}

async function checkURL(url) {
  try {
    const response = await fetch(url, { redirect: "manual" });
    return `${response.status} ${response.statusText}`;
  } catch (error) {
    return error instanceof Error ? error.message : String(error);
  }
}

for (const domain of domains) {
  console.log(`${domain}: ${await dnsRecord(domain)}`);
}

for (const url of urls) {
  console.log(`${url}: ${await checkURL(url)}`);
}
