import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { createScene } from "../src/commands/scene.js";

function makeTempDir(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "astra-cli-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  return directory;
}

test("createScene usa games/scenes por defecto", (t) => {
  const cwd = makeTempDir(t);
  const logs = [];

  const target = createScene("MyScene", {
    cwd,
    log: (message) => logs.push(message),
  });

  assert.equal(target, path.join(cwd, "games", "scenes", "MyScene.lua"));

  const content = fs.readFileSync(target, "utf8");
  assert.match(content, /local MyScene = \{\}/);
  assert.match(content, /function MyScene\.new\(context\)/);

  for (const callback of [
    "onLoad",
    "onEnter",
    "onExit",
    "onDestroy",
    "update",
    "draw",
  ]) {
    assert.match(content, new RegExp(`function MyScene:${callback}\\(`));
  }

  assert.match(content, /return MyScene/);
  assert.doesNotMatch(content, /\{\{sceneName\}\}/);
  assert.match(logs.join("\n"), /Escena creada en/);
});

test("createScene acepta una ruta personalizada", (t) => {
  const cwd = makeTempDir(t);

  const target = createScene("OtherScene", "scenes", { cwd, log() {} });

  assert.equal(target, path.join(cwd, "scenes", "OtherScene.lua"));
  assert.ok(fs.existsSync(target));
});

test("createScene no sobrescribe una escena existente", (t) => {
  const cwd = makeTempDir(t);
  const target = path.join(cwd, "games", "scenes", "MyScene.lua");
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, "-- existente\n");

  assert.throws(
    () => createScene("MyScene", { cwd, log() {} }),
    /La escena ya existe/,
  );
  assert.equal(fs.readFileSync(target, "utf8"), "-- existente\n");
});

test("createScene valida el nombre como identificador Lua", (t) => {
  const cwd = makeTempDir(t);

  assert.throws(
    () => createScene("mi-scena", { cwd, log() {} }),
    /Nombre de escena no válido/,
  );
  assert.throws(
    () => createScene("2Scene", { cwd, log() {} }),
    /Nombre de escena no válido/,
  );
});
