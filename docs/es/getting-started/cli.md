# CLI del proyecto

`astra2d` es una herramienta opcional de línea de comandos basada en Node.js (publicada en npm como `astra2d-cli`) que genera proyectos LÖVE con Astra 2D y crea módulos de escena. También puedes crear los archivos a mano en [Tu primer proyecto](/es/getting-started/first-project).

## Requisitos e instalación

- **Node.js 20 o superior** para ejecutar la CLI.
- **LÖVE 11.5** para ejecutar el juego generado; la CLI no lo instala.

```sh
npm install -g astra2d-cli
astra2d --help
```

Para desarrollar localmente, instala las dependencias desde el directorio `cli/` del repositorio, ejecuta `npm run build` y usa `npm link` o `node bin/astra2d.js`.

## Crear un proyecto

```sh
astra2d init my-game
cd my-game
love .
```

`astra2d init <project-name> [ruta]` crea `<ruta>/<project-name>`, o usa `.` si se omite `ruta`. Usa `.` como nombre de proyecto para inicializar el directorio actual en el mismo sitio:

```sh
astra2d init mi-juego ../proyectos
astra2d init .
astra2d init . ../proyectos
```

El comando descarga `engine/` desde el último release o tag de GitHub de `Damet24/Astra2D`. Si la descarga falla, avisa y usa la copia del motor incluida en el paquete npm, así que funciona también sin conexión. Define `GITHUB_TOKEN` si necesitas más límite de la API o acceso a un repositorio privado. Se niega a escribir si el destino ya existe, o si ya están `engine/`, `main.lua` o `game/` al inicializar en el mismo sitio.

El proyecto generado tiene esta estructura:

```text
my-game/
  engine/                 # código del motor, incluido engine/lib/
  main.lua
  game/
    config/
      collisionLayer.lua  # IDs habituales de categorías de colisión
      inputMaps.lua       # acciones con nombre
      resourceDefinitions.lua
    scenes/
      main.lua            # escena inicial
```

`main.lua` importa `game.config.resourceDefinitions` y `game.config.inputMaps`, y establece `initialScene = "main"`. La escena inicial muestra un temporizador y sale con Enter o el botón Start del mando. Es un punto de partida mínimo: no tiene assets, cámaras ni física, y no sustituye al juego de ejemplo de [Instalación](/es/getting-started/installation).

## Crear escenas

```sh
astra2d scene:create Level1
astra2d s:c Level1 game/scenes
```

`scene:create` (alias `s:c`) copia una plantilla de escena y sustituye el marcador por el nombre indicado. Por defecto escribe `game/scenes/Level1.lua`, que resuelve al módulo Lua `game.scenes.Level1`; el segundo argumento opcional elige otro directorio. El nombre debe ser un identificador Lua válido y los archivos existentes nunca se sobrescriben. La plantilla incluye `onLoad`, `onEnter`, `onExit`, `onDestroy`, `update` y `draw`.

## Notas

- La versión de la CLI es independiente de la versión del motor. Consulta el [paquete en npm](https://www.npmjs.com/package/astra2d-cli) para ver la versión actual.
- La copia incluida del motor se regenera con `npm run build` (y automáticamente mediante `prepack` antes de publicar).
- La CLI no añade assets, no instala LÖVE ni ejecuta el juego por ti.

## Consulta también

[Instalación](/es/getting-started/installation) · [Tu primer proyecto](/es/getting-started/first-project) · [Guía de escenas](/es/guides/scenes) · [API de SceneManager](/es/api/scene-manager)
