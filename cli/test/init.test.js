import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { initProject } from "../src/commands/init.js";
import { downloadEngine, resolveLatestRef } from "../src/services/engineSource.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const LOCAL_ENGINE = path.resolve(HERE, "..", "..", "engine");

function makeTempDir(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "astra-cli-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  return directory;
}

function localEngineSource() {
  return async () => ({ path: LOCAL_ENGINE, cleanup() {} });
}

test("initProject crea el proyecto en <ruta>/<nombre>", async (t) => {
  const cwd = makeTempDir(t);
  const logs = [];

  const destination = await initProject("demo", "projects", {
    cwd,
    log: (message) => logs.push(message),
    engineSource: localEngineSource(),
  });

  assert.equal(destination, path.join(cwd, "projects", "demo"));
  assert.ok(
    fs.statSync(path.join(destination, "engine", "engine.lua")).isFile(),
  );
  assert.ok(fs.statSync(path.join(destination, "main.lua")).isFile());
  const inputMaps = fs.readFileSync(
    path.join(destination, "game", "config", "inputMaps.lua"),
    "utf8",
  );
  assert.match(inputMaps, /exit = \{/);
  assert.match(inputMaps, /keys = \{ "return" \}/);
  assert.match(inputMaps, /gamepad = \{ "start" \}/);

  const projectMain = fs.readFileSync(
    path.join(destination, "main.lua"),
    "utf8",
  );
  assert.doesNotMatch(projectMain, /love\.keypressed/);
  assert.doesNotMatch(projectMain, /love\.keyreleased/);

  const mainScene = fs.readFileSync(
    path.join(destination, "game", "scenes", "main.lua"),
    "utf8",
  );
  assert.match(mainScene, /self\.elapsed = 0/);
  assert.match(mainScene, /self\.elapsed = self\.elapsed \+ dt/);
  assert.match(mainScene, /Press Enter or gamepad Start to exit/);

  assert.match(logs.join("\n"), /Proyecto creado en/);
});

test("initProject sin ruta usa el directorio actual", async (t) => {
  const cwd = makeTempDir(t);

  const destination = await initProject("demo", {
    cwd,
    log() {},
    engineSource: localEngineSource(),
  });

  assert.equal(destination, path.join(cwd, "demo"));
  assert.ok(fs.existsSync(path.join(destination, "engine")));
});

test("initProject . inicializa en el directorio actual", async (t) => {
  const cwd = makeTempDir(t);

  const destination = await initProject(".", {
    cwd,
    log() {},
    engineSource: localEngineSource(),
  });

  assert.equal(destination, cwd);
  assert.ok(fs.existsSync(path.join(cwd, "engine")));
  assert.ok(fs.existsSync(path.join(cwd, "game")));
});

test("initProject . [ruta] inicializa en esa ruta", async (t) => {
  const cwd = makeTempDir(t);

  const destination = await initProject(".", "projects", {
    cwd,
    log() {},
    engineSource: localEngineSource(),
  });

  assert.equal(destination, path.join(cwd, "projects"));
  assert.ok(fs.existsSync(path.join(destination, "main.lua")));
});

test("initProject no sobrescribe un destino existente", async (t) => {
  const cwd = makeTempDir(t);
  fs.mkdirSync(path.join(cwd, "demo"));

  await assert.rejects(
    initProject("demo", { cwd, log() {}, engineSource: localEngineSource() }),
    /El destino ya existe/,
  );
  assert.equal(fs.existsSync(path.join(cwd, "demo", "engine")), false);
});

test("initProject . falla si ya existe alguna entrada y no toca nada", async (t) => {
  const cwd = makeTempDir(t);
  fs.mkdirSync(path.join(cwd, "engine"));

  await assert.rejects(
    initProject(".", { cwd, log() {}, engineSource: localEngineSource() }),
    /Ya existen entradas.*engine/,
  );
  assert.equal(fs.existsSync(path.join(cwd, "main.lua")), false);
});

test("initProject valida el nombre del proyecto", async (t) => {
  const cwd = makeTempDir(t);

  await assert.rejects(
    initProject("../fuera", { cwd, log() {}, engineSource: localEngineSource() }),
    /Nombre de proyecto no válido/,
  );
});

test("initProject usa el engine descargado y limpia el temporal", async (t) => {
  const cwd = makeTempDir(t);
  const remoteEngine = path.join(cwd, "remote-engine");
  fs.mkdirSync(remoteEngine);
  fs.writeFileSync(path.join(remoteEngine, "engine.lua"), "-- remoto");

  let cleaned = false;
  const destination = await initProject("demo", {
    cwd,
    log() {},
    engineSource: async () => ({
      path: remoteEngine,
      ref: "v9.9.9",
      cleanup() {
        cleaned = true;
      },
    }),
  });

  assert.equal(
    fs.readFileSync(path.join(destination, "engine", "engine.lua"), "utf8"),
    "-- remoto",
  );
  assert.equal(cleaned, true);
});

test("initProject usa el engine incluido si falla la descarga", async (t) => {
  const cwd = makeTempDir(t);
  const logs = [];

  const destination = await initProject("demo", {
    cwd,
    log: (message) => logs.push(message),
    engineSource: async () => {
      throw new Error("sin red");
    },
  });

  assert.ok(fs.statSync(path.join(destination, "engine", "engine.lua")).isFile());
  assert.match(logs.join("\n"), /No se pudo descargar el engine desde GitHub.*sin red/);
  assert.match(logs.join("\n"), /Proyecto creado con el engine incluido/);
});

test("resolveLatestRef usa el release cuando existe", async () => {
  const calls = [];
  const fetchImpl = async (url) => {
    calls.push(url);
    return {
      ok: true,
      json: async () => ({ tag_name: "v2.0.0" }),
    };
  };

  assert.equal(await resolveLatestRef({ fetch: fetchImpl }), "v2.0.0");
  assert.equal(calls.length, 1);
});

test("resolveLatestRef cae al primer tag si no hay releases", async () => {
  const fetchImpl = async (url) => {
    if (url.includes("/releases/latest")) {
      return { ok: false, status: 404 };
    }

    return {
      ok: true,
      json: async () => [{ name: "v0.1.0" }],
    };
  };

  assert.equal(await resolveLatestRef({ fetch: fetchImpl }), "v0.1.0");
});

test("downloadEngine devuelve una ruta limpia y temporal", async (t) => {
  const tarball = makeTarballWithEngine(t);
  const fetchImpl = async () => ({
    ok: true,
    arrayBuffer: async () => tarball,
  });

  const engine = await downloadEngine({
    ref: "v0.1.0",
    fetch: fetchImpl,
  });

  assert.equal(engine.ref, "v0.1.0");
  assert.ok(fs.statSync(path.join(engine.path, "engine.lua")).isFile());
  assert.equal(fs.existsSync(path.join(engine.path, "main.lua")), false);

  const enginePath = engine.path;
  engine.cleanup();
  assert.equal(fs.existsSync(enginePath), false);
});

function makeTarballWithEngine(t) {
  const source = makeTempDir(t);
  const root = path.join(source, "Astra2D-0.1.0");
  fs.mkdirSync(path.join(root, "engine"), { recursive: true });
  fs.mkdirSync(path.join(root, "game"));
  fs.writeFileSync(path.join(root, "engine", "engine.lua"), "-- engine");
  fs.writeFileSync(path.join(root, "game", "main.lua"), "-- no copiar");

  const output = path.join(source, "repo.tar.gz");

  return tarCreateSync(root, output);
}

function tarCreateSync(root, output) {
  const result = spawnSync(
    "tar",
    ["-czf", output, "-C", path.dirname(root), path.basename(root)],
    { encoding: "buffer" },
  );

  assert.equal(result.status, 0, result.stderr.toString());
  return fs.readFileSync(output);
}
