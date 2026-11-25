# Astra 2D CLI

CLI oficial para crear proyectos LÖVE y escenas con Astra 2D. Usa
[Commander](https://github.com/tj/commander.js) y se genera en `bin/`.

## Requisitos

Node.js 20 o superior.

## Instalación desde npm

```sh
npm install -g astra2d-cli
astra2d --help
```

## Instalación local (desarrollo)

```sh
npm install
npm run build
npm link
```

Eso deja disponible el comando `astra2d` en el sistema. Para ejecutar la build
sin instalarla:

```sh
node bin/astra2d.js --help
```

La fuente está en `src/`. `npm run build` copia `src/cli.js` en
`bin/astra2d.js`, le da permisos de ejecución y copia `engine/` en
`assets/engine/` para que el paquete publicado pueda crear proyectos.

## Publicar en npm

Desde esta carpeta:

```sh
npm login
npm publish
```

`prepack` ejecuta `npm run build` automáticamente, por lo que `bin/` y
`assets/engine/` quedan incluidos en el tarball. `files` en `package.json`
excluye `node_modules/` y archivos de desarrollo.

## Uso

```sh
astra2d init <project-name> [ruta]
astra2d scene:create <name> [ruta]
astra2d s:c <name> [ruta]
```

### `init`

Descarga `engine/` desde el último release (o, si no hay releases, desde el
último tag) del repositorio `Damet24/Astra2D` y copia el contenido de
`src/templates/project/` en `<ruta>/<project-name>`. Si se omite `ruta`, usa `.`.

Si la descarga falla (sin conexión, límite de la API, etc.), el CLI avisa y usa
el `engine/` incluido en el paquete npm, así que `init` sigue funcionando sin red.
Para repositorios privados o evitar límites de la API, define `GITHUB_TOKEN`.

```sh
astra2d init mi-juego              # ./mi-juego
astra2d init mi-juego ../proyectos # ../proyectos/mi-juego
astra2d init .                     # directorio actual
astra2d init . ../proyectos        # esa ruta, sin subcarpeta
```

Falla y no escribe nada si el destino ya existe, o si al usar `.` ya están
`engine/`, `main.lua` o `game/`.

La plantilla genera `main.lua`, que importa `game.config.resourceDefinitions` y
`game.config.inputMaps`, y `game/config/` con `collisionLayer.lua`,
`inputMaps.lua` y `resourceDefinitions.lua`. Las escenas se crean en
`game/scenes/`.

### `scene:create`

Crea `<name>.lua` desde `src/templates/scene/scene.lua`, sustituyendo
`{{sceneName}}` por el nombre indicado. La plantilla incluye todos los callbacks
de escena: `onLoad`, `onEnter`, `onExit`, `onDestroy`, `update` y `draw`.

```sh
astra2d scene:create MyScene
astra2d scene:create MyScene game/scenes
astra2d s:c MyScene tests/scenes
astra2d scene:create --help
```

Por defecto escribe en `game/scenes/MyScene.lua` (módulo Lua
`game.scenes.MyScene`). El segundo argumento permite elegir otro directorio.
El nombre debe ser un identificador Lua válido y no se sobrescriben archivos
existentes.

## Desarrollo

```sh
npm test
npm run build
```
