import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { CliError } from "../errors.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = path.resolve(HERE, "..", "..");
const DEV_ENGINE_SOURCE = path.resolve(PACKAGE_ROOT, "..", "engine");
const PACKAGED_ENGINE_SOURCE = path.join(PACKAGE_ROOT, "assets", "engine");
const TEMPLATE_SOURCE = path.join(HERE, "..", "templates", "project");

function findEngineSource() {
  return [DEV_ENGINE_SOURCE, PACKAGED_ENGINE_SOURCE].find((candidate) =>
    fs.existsSync(path.join(candidate, "engine.lua")),
  );
}

export const USAGE = "Uso: astra2d init <project-name> [ruta]";

export const INIT_HELP = `${USAGE}

Copia engine/ y el contenido de la plantilla de proyecto en <ruta>/<project-name>.

Argumentos:
  project-name   Nombre de la carpeta del proyecto. Usa "." para inicializar
                 directamente en una carpeta existente sin crear subcarpeta.
  ruta           Ruta donde se crea el proyecto; por defecto ".".

Ejemplos:
  astra2d init mi-juego
  astra2d init mi-juego ../proyectos
  astra2d init .
  astra2d init . ../proyectos

Si el destino o alguna entrada ya existe, no se sobrescribe nada.`;

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
    throw new CliError(`Falta el nombre del proyecto. ${USAGE}`);
  }

  if (positional.length > 2) {
    throw new CliError(`Demasiados argumentos. ${USAGE}`);
  }

  const [name, basePath = "."] = positional;

  if (name === ".") {
    return { inPlace: true, basePath };
  }

  if (
    !name ||
    name !== name.trim() ||
    name === ".." ||
    path.isAbsolute(name) ||
    name.includes("/") ||
    name.includes("\\")
  ) {
    throw new CliError(`Nombre de proyecto no válido: ${JSON.stringify(name)}`);
  }

  return { name, basePath };
}

function assertSources() {
  if (!findEngineSource()) {
    throw new CliError(
      `No se encontró engine/. Buscado en: ${DEV_ENGINE_SOURCE} y ${PACKAGED_ENGINE_SOURCE}`,
    );
  }

  if (!fs.existsSync(TEMPLATE_SOURCE) || !fs.statSync(TEMPLATE_SOURCE).isDirectory()) {
    throw new CliError(`No se encontró la plantilla de proyecto: ${TEMPLATE_SOURCE}`);
  }
}

function getEntries() {
  const templateNames = fs.readdirSync(TEMPLATE_SOURCE).sort();

  return [
    { name: "engine", source: findEngineSource() },
    ...templateNames.map((name) => ({
      name,
      source: path.join(TEMPLATE_SOURCE, name),
    })),
  ];
}

export function runInit(args, options = {}) {
  const cwd = options.cwd || process.cwd();
  const log = options.log || (() => {});
  const parsed = parseArgs(args);

  if (parsed.help) {
    log(INIT_HELP);
    return null;
  }

  assertSources();

  const entries = getEntries();
  const destination = parsed.inPlace
    ? path.resolve(cwd, parsed.basePath)
    : path.resolve(cwd, parsed.basePath, parsed.name);

  if (!parsed.inPlace && fs.existsSync(destination)) {
    throw new CliError(`El destino ya existe: ${destination}`);
  }

  const conflicts = parsed.inPlace
    ? entries
        .map((entry) => entry.name)
        .filter((name) => fs.existsSync(path.join(destination, name)))
    : [];

  if (conflicts.length > 0) {
    throw new CliError(
      `Ya existen entradas en ${destination}: ${conflicts.join(", ")}. No se sobrescribió nada.`,
    );
  }

  let createdDestination = false;
  const copied = [];

  try {
    if (!parsed.inPlace) {
      fs.mkdirSync(destination, { recursive: true });
      createdDestination = true;
    }

    for (const entry of entries) {
      const target = path.join(destination, entry.name);

      fs.cpSync(entry.source, target, {
        recursive: true,
        force: false,
        errorOnExist: true,
      });

      copied.push(target);
    }
  } catch (error) {
    if (createdDestination) {
      fs.rmSync(destination, { recursive: true, force: true });
    } else {
      for (const target of copied.reverse()) {
        fs.rmSync(target, { recursive: true, force: true });
      }
    }

    throw new CliError(`No se pudo crear el proyecto: ${error.message}`);
  }

  log(`Proyecto creado en ${destination}`);
  return destination;
}

export function initProject(projectName, targetPath, options = {}) {
  if (targetPath && typeof targetPath === "object") {
    options = targetPath;
    targetPath = undefined;
  }

  const args = [projectName];

  if (targetPath !== undefined) {
    args.push(targetPath);
  }

  return runInit(args, options);
}
