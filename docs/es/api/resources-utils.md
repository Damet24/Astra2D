# Utilidades de definición de recursos

`require("engine.resources.utils")` exporta utilidades para completar la tabla de definiciones que consume [ResourceManager](resource-manager.md). Evitan repetir la raíz de los recursos y concentran la comprobación de IDs duplicados.

## API

| Función | Efecto |
| --- | --- |
| `Utils.addImages(definitions, root, directory, images)` | Añade una entrada `{ type = "image", path = root .. directory .. filename }` por cada par `id -> filename`. |
| `Utils.addSound(definitions, root, directory, sounds, soundType)` | Añade una entrada `{ type = "sound", path = root .. directory .. filename, soundType = soundType }` por cada par `id -> filename`. |

`definitions` es la tabla que después se pasa a `Engine.new` como `resourceDefinitions`. `root` y `directory` se concatenan tal cual, así que incluye las barras finales necesarias; `filename` también puede contener subdirectorios. Si el ID ya existe, se lanza `duplicate resource id: <id>` y su definición permanece intacta. Se usa `pairs`, por lo que el orden de inserción no está garantizado.

Estas funciones solo construyen definiciones: no comprueban que los archivos existan, no validan `soundType` y no cargan nada. Eso lo hace el cargador correspondiente en el primer `get`. Indica `soundType = "static"` o `"stream"` según exija el [cargador de sonido](resource-manager.md).

## Ejemplo

```lua
local Utils = require("engine.resources.utils")

local definitions = {}
local IMAGES_ROOT = "game/assets/images/"

Utils.addImages(definitions, IMAGES_ROOT, "character_animations/", {
    player_idle = "Idle/Player Idle 48x48.png",
    player_run = "Run/player run 48x48.png",
})

Utils.addSound(definitions, "game/assets/sounds/", "", {
    jump = "jump.wav",
}, "static")

return definitions
```

Consulta [ResourceManager](resource-manager.md) y la [guía de recursos](../guides/resources.md).
