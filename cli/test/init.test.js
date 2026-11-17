import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { initProject } from "../src/commands/init.js";

function makeTempDir(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "astra-cli-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  return directory;
}

test("initProject crea el proyecto en <ruta>/<nombre>", (t) => {
  const cwd = makeTempDir(t);
  const logs = [];

  const destination = initProject("demo", "projects", {
    cwd,
    log: (message) => logs.push(message),
  });

  assert.equal(destination, path.join(cwd, "projects", "demo"));
  assert.ok(
    fs.statSync(path.join(destination, "engine", "engine.lua")).isFile(),
  );
  assert.ok(fs.statSync(path.join(destination, "main.lua")).isFile());
  const inputMaps = fs.readFileSync(
    path.join(destination, "game", "inputMaps.lua"),
    "utf8",
  );
  assert.match(inputMaps, /exit = \{ "return" \}/);

  const mainScene = fs.readFileSync(
    path.join(destination, "game", "scenes", "main.lua"),
    "utf8",
  );
  assert.match(mainScene, /self\.elapsed = 0/);
  assert.match(mainScene, /self\.elapsed = self\.elapsed \+ dt/);
  assert.match(mainScene, /Press enter to exit/);

  assert.match(logs.join("\n"), /Proyecto creado en/);
});

test("initProject sin ruta usa el directorio actual", (t) => {
  const cwd = makeTempDir(t);

  const destination = initProject("demo", { cwd, log() {} });

  assert.equal(destination, path.join(cwd, "demo"));
  assert.ok(fs.existsSync(path.join(destination, "engine")));
});

test("initProject . inicializa en el directorio actual", (t) => {
  const cwd = makeTempDir(t);

  const destination = initProject(".", { cwd, log() {} });

  assert.equal(destination, cwd);
  assert.ok(fs.existsSync(path.join(cwd, "engine")));
  assert.ok(fs.existsSync(path.join(cwd, "game")));
});

test("initProject . [ruta] inicializa en esa ruta", (t) => {
  const cwd = makeTempDir(t);

  const destination = initProject(".", "projects", { cwd, log() {} });

  assert.equal(destination, path.join(cwd, "projects"));
  assert.ok(fs.existsSync(path.join(destination, "main.lua")));
});

test("initProject no sobrescribe un destino existente", (t) => {
  const cwd = makeTempDir(t);
  fs.mkdirSync(path.join(cwd, "demo"));

  assert.throws(
    () => initProject("demo", { cwd, log() {} }),
    /El destino ya existe/,
  );
  assert.equal(fs.existsSync(path.join(cwd, "demo", "engine")), false);
});

test("initProject . falla si ya existe alguna entrada y no toca nada", (t) => {
  const cwd = makeTempDir(t);
  fs.mkdirSync(path.join(cwd, "engine"));

  assert.throws(
    () => initProject(".", { cwd, log() {} }),
    /Ya existen entradas.*engine/,
  );
  assert.equal(fs.existsSync(path.join(cwd, "main.lua")), false);
});

test("initProject valida el nombre del proyecto", (t) => {
  const cwd = makeTempDir(t);

  assert.throws(
    () => initProject("../fuera", { cwd, log() {} }),
    /Nombre de proyecto no válido/,
  );
});
