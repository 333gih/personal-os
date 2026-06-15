import { copyFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const profile = process.argv[2] || "local";
const source = profile === "prod" ? ".env.local.prod" : ".env.example";
const sourcePath = join(root, source);
const destPath = join(root, ".env.local");

if (!existsSync(sourcePath)) {
  console.error(`[env] Missing ${source}`);
  process.exit(1);
}

copyFileSync(sourcePath, destPath);
console.log(`[env] ${source} → .env.local (${profile} profile)`);
