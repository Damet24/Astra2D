import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { CliError } from "../errors.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE_SOURCE = path.join(
  HERE,
  "..",
  "templates",
  "scene",
  "scene.lua",
);
const DEFAULT_SCENES_DIR = path.join("game", "scenes");
const SCENE_NAME_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/;
const PLACEHOLDER = "{{sceneName}}";

export const SCENE_USAGE =
  "Uso: astra2d scene:create <name> [ruta]  (alias: s:c)";

export const SCENE_HELP = `${SCENE_USAGE}

Crea <name>.lua desde la plantilla de escenas.

Argumentos:
  name   Identificador Lua de la escena, por ejemplo MyScene.
  ruta   Directorio destino; por defecto ${DEFAULT_SCENES_DIR}
         (módulo Lua game.scenes).

Ejemplos:
  astra2d scene:create MyScene
  astra2d scene:create MyScene game/scenes
  astra2d s:c MyScene tests/scenes`;

function assertTemplate() {
  if (!fs.existsSync(TEMPLATE_SOURCE) || !fs.statSync(TEMPLATE_SOURCE).isFile()) {
    throw new CliError(`No se encontró la plantilla de escena: ${TEMPLATE_SOURCE}`);
  }
}

function parseArgs(args) {
  const positional = [];

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      return { help: true };
    }

    if (arg.startsWith("-")) {
      throw new CliError(`Opción desconocida: ${arg}`);
    }

    positional.push(arg);
  }

  if (positional.length === 0) {
    throw new CliError(`Falta el nombre de la escena. ${SCENE_USAGE}`);
  }

  if (positional.length > 2) {
    throw new CliError(`Demasiados argumentos. ${SCENE_USAGE}`);
  }

  const [name, basePath = DEFAULT_SCENES_DIR] = positional;

  if (!SCENE_NAME_PATTERN.test(name)) {
    throw new CliError(
      `Nombre de escena no válido: ${JSON.stringify(name)}. Debe ser un identificador Lua.`,
    );
  }

  return { name, basePath };
}

export function runScene(args, options = {}) {
  const cwd = options.cwd || process.cwd();
  const log = options.log || (() => {});
  const parsed = parseArgs(args);

  if (parsed.help) {
    log(SCENE_HELP);
    return null;
  }

  assertTemplate();

  const target = path.resolve(cwd, parsed.basePath, `${parsed.name}.lua`);

  if (fs.existsSync(target)) {
    throw new CliError(`La escena ya existe: ${target}`);
  }

  const template = fs.readFileSync(TEMPLATE_SOURCE, "utf8");

  if (!template.includes(PLACEHOLDER)) {
    throw new CliError(
      `La plantilla de escena no contiene ${PLACEHOLDER}: ${TEMPLATE_SOURCE}`,
    );
  }

  const content = template.split(PLACEHOLDER).join(parsed.name);

  fs.mkdirSync(path.dirname(target), { recursive: true });

  try {
    fs.writeFileSync(target, content, { encoding: "utf8", flag: "wx" });
  } catch (error) {
    if (fs.existsSync(target)) {
      fs.rmSync(target, { force: true });
    }

    throw new CliError(`No se pudo crear la escena: ${error.message}`);
  }

  log(`Escena creada en ${target}`);
  return target;
}

export function createScene(name, basePath, options = {}) {
  if (basePath && typeof basePath === "object") {
    options = basePath;
    basePath = undefined;
  }

  const args = [name];

  if (basePath !== undefined) {
    args.push(basePath);
  }

  return runScene(args, options);
}
