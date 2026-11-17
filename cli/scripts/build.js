import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..");
const REPO_ROOT = path.resolve(ROOT, "..");

const SOURCE = path.join(ROOT, "src", "cli.js");
const OUTPUT_DIR = path.join(ROOT, "bin");
const OUTPUT = path.join(OUTPUT_DIR, "astra2d.js");

const ENGINE_SOURCE = path.join(REPO_ROOT, "engine");
const ASSETS_DIR = path.join(ROOT, "assets");
const ENGINE_ASSET = path.join(ASSETS_DIR, "engine");

const LICENSE_SOURCE = path.join(REPO_ROOT, "LICENSE");
const LICENSE_TARGET = path.join(ROOT, "LICENSE");

if (!fs.existsSync(path.join(ENGINE_SOURCE, "engine.lua"))) {
  throw new Error(`No se encontró engine/ en ${ENGINE_SOURCE}`);
}

fs.mkdirSync(OUTPUT_DIR, { recursive: true });
fs.copyFileSync(SOURCE, OUTPUT);
fs.chmodSync(OUTPUT, 0o755);

fs.mkdirSync(ASSETS_DIR, { recursive: true });
fs.rmSync(ENGINE_ASSET, { recursive: true, force: true });
fs.cpSync(ENGINE_SOURCE, ENGINE_ASSET, { recursive: true });

fs.copyFileSync(LICENSE_SOURCE, LICENSE_TARGET);

console.error(`CLI generada en ${OUTPUT}`);
console.error(`Engine empaquetado en ${ENGINE_ASSET}`);
