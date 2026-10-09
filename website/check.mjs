import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const required = ["index.html", "pt-br/index.html", "es/index.html", "zh-hans/index.html", "ja/index.html", "de/index.html", "fr/index.html", "ko/index.html", "it/index.html", "nl/index.html", "ru/index.html", "privacy/index.html", "support/index.html", "download/index.html", "sitemap.xml", "robots.txt"];
const missing = required.filter(path => !existsSync(join("dist", path)));
if (missing.length) throw new Error(`Missing generated pages: ${missing.join(", ")}`);
const home = readFileSync(join("dist", "index.html"), "utf8");
for (const marker of ["hreflang", "SoftwareApplication", "/download/", "/cafe/"]) {
  if (!home.includes(marker)) throw new Error(`Missing marker: ${marker}`);
}
console.log(`Website check passed: ${required.length} required files.`);
