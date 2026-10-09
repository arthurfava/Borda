import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const required = ["index.html", "pt-br/index.html", "es/index.html", "zh-hans/index.html", "ja/index.html", "de/index.html", "fr/index.html", "ko/index.html", "it/index.html", "nl/index.html", "ru/index.html", "privacy/index.html", "support/index.html", "download/index.html", "cafe/index.html", "github/index.html", "sitemap.xml", "robots.txt"];
const missing = required.filter(path => !existsSync(join("dist", path)));
if (missing.length) throw new Error(`Missing generated pages: ${missing.join(", ")}`);
const home = readFileSync(join("dist", "index.html"), "utf8");
for (const marker of ["hreflang", "SoftwareApplication", "/download/", "/cafe/", "class=\"installation\"", "class=\"install-steps\"", "data-motion-demo", "data-motion-replay"]) {
  if (!home.includes(marker)) throw new Error(`Missing marker: ${marker}`);
}
if (home.includes("Mac App Store")) throw new Error("The direct-download landing still mentions the Mac App Store.");
const release = JSON.parse(readFileSync(join("dist", "releases/latest.json"), "utf8"));
if (release.version !== "0.9.0" || typeof release.available !== "boolean" || !["stable", "beta"].includes(release.channel)) {
  throw new Error("Invalid release manifest.");
}
console.log(`Website check passed: ${required.length} required files.`);
