import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { x as extract } from "tar";

const REPOSITORY = "Damet24/Astra2D";
const API_BASE = `https://api.github.com/repos/${REPOSITORY}`;
const RELEASE_URL = `${API_BASE}/releases/latest`;
const TAGS_URL = `${API_BASE}/tags?per_page=1`;

function headers() {
  const result = {
    Accept: "application/vnd.github+json",
    "User-Agent": "astra2d-cli",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  if (process.env.GITHUB_TOKEN) {
    result.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  }

  return result;
}

async function getJson(url, fetchImpl, timeoutMs) {
  const response = await fetchImpl(url, {
    headers: headers(),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const error = new Error(`GitHub respondió ${response.status} para ${url}`);
    error.status = response.status;
    throw error;
  }

  return response.json();
}

export async function resolveLatestRef(options = {}) {
  const fetchImpl = options.fetch || fetch;
  const timeoutMs = options.timeoutMs ?? 10_000;

  try {
    const release = await getJson(RELEASE_URL, fetchImpl, timeoutMs);

    if (typeof release.tag_name === "string" && release.tag_name) {
      return release.tag_name;
    }
  } catch (error) {
    if (error.status !== 404) {
      throw error;
    }
  }

  const tags = await getJson(TAGS_URL, fetchImpl, timeoutMs);

  if (!Array.isArray(tags) || typeof tags[0]?.name !== "string") {
    throw new Error("GitHub no devolvió ningún tag para Astra2D");
  }

  return tags[0].name;
}

function isEngineEntry(entryPath) {
  const parts = entryPath.split("/");

  // El tarball de GitHub tiene una carpeta raíz con el nombre del repo/tag.
  return parts.length > 1 && parts[1] === "engine";
}

export async function downloadEngine(options = {}) {
  const fetchImpl = options.fetch || fetch;
  const timeoutMs = options.timeoutMs ?? 30_000;
  const ref = options.ref || (await resolveLatestRef(options));
  const url = `https://codeload.github.com/${REPOSITORY}/tar.gz/refs/tags/${encodeURIComponent(ref)}`;

  const temporaryDir = fs.mkdtempSync(path.join(os.tmpdir(), "astra2d-engine-"));
  const tarball = path.join(temporaryDir, "engine.tar.gz");

  const cleanup = () => fs.rmSync(temporaryDir, { recursive: true, force: true });

  try {
    const response = await fetchImpl(url, {
      headers: headers(),
      signal: AbortSignal.timeout(timeoutMs),
    });

    if (!response.ok) {
      throw new Error(`No se pudo descargar ${url} (${response.status})`);
    }

    fs.writeFileSync(tarball, Buffer.from(await response.arrayBuffer()));

    await extract({
      cwd: temporaryDir,
      file: tarball,
      strip: 1,
      filter: isEngineEntry,
    });

    const enginePath = path.join(temporaryDir, "engine");

    if (!fs.existsSync(path.join(enginePath, "engine.lua"))) {
      throw new Error("El tarball descargado no contiene engine/engine.lua");
    }

    return { path: enginePath, ref, cleanup };
  } catch (error) {
    cleanup();
    throw error;
  }
}
