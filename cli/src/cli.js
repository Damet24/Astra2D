#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { Command } from "commander";

import { initProject, INIT_HELP } from "../src/commands/init.js";
import { createScene, SCENE_HELP } from "../src/commands/scene.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const { version } = JSON.parse(
  fs.readFileSync(path.join(HERE, "..", "package.json"), "utf8"),
);

const program = new Command();

program
  .name("astra2d")
  .description("CLI oficial para el motor Astra2D")
  .version(version)
  .showHelpAfterError();

const log = (message) => process.stdout.write(`${message}\n`);

program
  .command("init <project-name> [ruta]")
  .description("Inicializa un nuevo proyecto Astra2D")
  .addHelpText("after", `\n${INIT_HELP}`)
  .action(async (projectName, ruta) => {
    await initProject(projectName, ruta, { log });
  });

program
  .command("scene:create <name> [ruta]")
  .alias("s:c")
  .description("Crea una nueva escena para tu juego")
  .addHelpText("after", `\n${SCENE_HELP}`)
  .action((name, ruta) => {
    createScene(name, ruta, { log });
  });

try {
  await program.parseAsync(process.argv);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
