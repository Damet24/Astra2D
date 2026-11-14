# Cargar y liberar una imagen compartida

## Objetivo y requisitos

Muestra una imagen y una fuente mediante el gestor de recursos y libera el interés de la escena cuando se destruya. Parte de [Tu primer proyecto](/es/getting-started/first-project), incluidos sus callbacks de LÖVE. Proporciona tu propio PNG en `game/assets/guide-logo.png`; un proyecto nuevo no incluye esa imagen.

## 1. Registrar los recursos

Crea `game/resources/definitions.lua` y su directorio padre si no existen; comienza el archivo con `return {}`. Añade estas entradas dentro de la tabla devuelta, conservando las existentes:

```lua
guide_logo = { type = "image", path = "game/assets/guide-logo.png" },
guide_font = { type = "font", size = 18 },
```

Son entradas de tabla, no un archivo Lua independiente. Asegúrate de que `Engine.new` en `main.lua` reciba `resourceDefinitions = require("game.resources.definitions")` y establece `initialScene = "guideResources"`. El cargador predeterminado de imágenes usa una ruta del sistema de archivos de LÖVE; el de fuentes crea una fuente por tamaño y no acepta una ruta de archivo de fuente.

## 2. Crear la escena que consume recursos

Crea `game/scenes/guideResources.lua`:

```lua
local Scene = require("engine.scene.scene")
local Resources = {}
Resources.__index = Resources
setmetatable(Resources, { __index = Scene })

function Resources.new(context)
    local self = setmetatable(Scene.new(), Resources)
    self.context = context
    return self
end

function Resources:onLoad()
    local resources = self.context.resourceManager
    self.logo = resources:get(self, "guide_logo")
    self.font = resources:get(self, "guide_font")
end

function Resources:draw()
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.print("Shared image", 16, 16)
    love.graphics.draw(self.logo, 16, 48)
    love.graphics.pop()
end

function Resources:onDestroy()
    self.context.resourceManager:releaseAll(self)
    self.logo, self.font = nil, nil
end

return Resources
```

## 3. Ejecutar y comprobar la compartición

Ejecuta `love .` desde la raíz del proyecto. La imagen debería aparecer debajo del texto. Al cerrar el juego se destruye la escena y se liberan sus intereses. Para liberar solo la imagen antes, llama a `self.context.resourceManager:release(self, "guide_logo")` y deja de dibujar o usar `self.logo` después.

`game/scenes/pause.lua` del repositorio utiliza `get(self, "pause_font")` y `releaseAll(self)` de la misma manera. Sus definiciones están en `game/resources/definitions.lua`; esos IDs del juego de ejemplo no se proporcionan automáticamente en un proyecto nuevo.

## Ciclo de vida y compartición

El primer `get(consumer, id)` carga y almacena el valor en caché; las peticiones posteriores del mismo ID lo comparten. Un consumidor es una clave Lua no nula, normalmente el objeto de escena. La propiedad es un conjunto, no un contador de referencias: varias llamadas a `get` del mismo consumidor solo requieren una liberación. Otro consumidor mantiene el recurso hasta que también lo libere. Tras la última liberación, otro `get` vuelve a cargarlo.

`onLoad` se ejecuta para cada instancia de escena construida; `onExit` puede significar solo que la escena está cubierta. Libera en `onDestroy`. En una salida normal el motor destruye las escenas, cierra audio y finalmente fuerza la liberación de los recursos restantes.

## Errores y limitaciones

- Los IDs no definidos y los cargadores ausentes producen errores; los archivos o rutas inválidos fallan en LÖVE al cargarse por primera vez. Los IDs distinguen mayúsculas y minúsculas. Comprueba que el archivo esté en el sistema de archivos del juego y que la definición se pase al motor.
- Los tipos predeterminados son `image`, `font` y `sound`; las definiciones de sonido requieren `path` y `soundType = "static"` o `"stream"`. Proporcionar `resourceLoaders` sustituye el registro predeterminado en lugar de ampliarlo.
- No llames a `:release()` en la imagen o fuente compartida. `releaseResource` y `releaseAllResources` invalidan los valores forzosamente aunque otros consumidores los conserven. `releaseAll(self)` no libera la propiedad del gestor de audio.
- El filtrado de imágenes se establece según el valor predeterminado de LÖVE al crearlas, no mediante un campo de definición. Un `setFilter` en la imagen en caché afecta a todos sus consumidores.

## Más información

[Arquitectura de ResourceManager](/es/architecture/modules/resource-manager) · [Arquitectura de Scene](/es/architecture/modules/scene) · [API de ResourceManager](/es/api/resource-manager).
