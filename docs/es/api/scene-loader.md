# API de SceneLoader

Módulo: `require("engine.scene.sceneLoader")`. Resuelve y construye escenas; no gestiona su ciclo de vida. Consulta la [arquitectura](../architecture/modules/scene-loader.md), la [guía de escenas](../guides/scenes.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y métodos

| Firma | Parámetros, resultado y efectos |
| --- | --- |
| `SceneLoader.new(config)` | Devuelve un cargador. `config` es una tabla opcional, pero `config.context` debe ser verdadero o falla una aserción; `config.scenesPath` vale `"game.scenes"` si es nil o false. Aquí no se valida la interfaz ni la ruta. |
| `loader:load(sceneName, dependencies)` | `sceneName` debe ser una cadena; `dependencies` se ignora. Ejecuta `require` de `scenesPath .. "." .. sceneName` y devuelve `SceneClass.new(context)`. Un fallo de `require` se relanza con el nombre de escena; un módulo que no devuelva una tabla con función `.new` provoca una aserción. Los errores del constructor se propagan sin envolver. |

La caché de `require` de Lua normalmente carga el código del módulo una vez, pero cada llamada invoca de nuevo el constructor. No se valida su retorno. Aquí no se llama a `onLoad` ni `onEnter`; lo hace [SceneManager](scene-manager.md). Sus dependencias fusionadas no se pasan al constructor. [Engine](engine.md) valida además que `scenesPath` sea una cadena no vacía.

## Ejemplo

```lua
local SceneLoader = require("engine.scene.sceneLoader")
-- context es el GameContext compartido; el módulo existe en este juego.
local loader = SceneLoader.new({ context = context })
local scene = loader:load("levels.level01")
```

El prefijo predeterminado resuelve este identificador como `game.scenes.levels.level01`; cargar no entra en la escena.
