# ResourceManager

[Descripción general de la arquitectura](/es/architecture/overview) · [InputManager](./input-manager) · [AudioManager](./audio-manager)

## Propósito y relaciones

`engine/resources/resourceManager.lua` carga recursos bajo demanda, los guarda en caché por ID y registra los consumidores que los necesitan. La liberación del último consumidor descarga el recurso. Es independiente de las escenas: `Engine` crea un gestor compartido, lo expone mediante `GameContext` y se lo pasa a `AudioManager`. Las escenas suelen usar su propio objeto como consumidor y liberar sus recursos en `onDestroy`; audio es otro consumidor independiente.

## Configuración y cargadores

`ResourceManager.new(definitions, loaders)` recibe dos tablas. `definitions[id]` se pasa al cargador seleccionado por `definition.type`; `loaders[type]` debe proporcionar las funciones normales `load(definition)` y `release(resource)`. `Engine.new` las recibe como `resourceDefinitions` (por defecto `{}`) y `resourceLoaders`. Una tabla de cargadores proporcionada sustituye a la tabla predeterminada, no la amplía.

El registro predeterminado en `engine/resources/loaders/loaders.lua` contiene:

| Tipo | Campos de la definición | Carga y liberación |
| --- | --- | --- |
| `image` | `path`: cadena | `love.graphics.newImage(path)`; llama a `image:release()`. |
| `sound` | `path`: cadena; `soundType`: `"static"` o `"stream"` | `love.audio.newSource(path, soundType)`; llama a `source:release()`. |
| `font` | `size`: número | `love.graphics.newFont(size)`; llama a `font:release()`. El cargador no utiliza una ruta de fuente. |

Por ejemplo, `game/config/resourceDefinitions.lua` define `pause_font` como `{ type = "font", size = 18 }`, `music` como sonido en streaming y `jump` como sonido estático. Las rutas pertenecen al sistema de archivos de LÖVE. Las aserciones de los cargadores comprueban los tipos indicados; LÖVE aún puede rechazar rutas, tamaños o archivos inválidos.

### Filtrado de imágenes

El cargador de imágenes no lee un campo de filtro ni llama a `setFilter`; las imágenes utilizan el filtro predeterminado de LÖVE al crearse. `Engine:load()` configura el viewport Shove antes de cargar la escena inicial: `rendering.pixelPerfect = true` selecciona escalado pixel y `nearest`; en caso contrario selecciona escalado aspect y `linear`. Shove establece el filtro gráfico predeterminado. Esto es independiente de la definición del recurso, y cambiar después el filtro predeterminado no cambia las imágenes ya creadas. Una llamada directa a `image:setFilter(...)` modifica la imagen compartida en caché para todos sus consumidores.

## API pública

| Método | Comportamiento |
| --- | --- |
| `ResourceManager.new(definitions, loaders)` | Crea una caché vacía con las tablas proporcionadas. |
| `get(consumer, resourceId)` | Carga en la primera solicitud, registra al consumidor y devuelve el valor en caché. Un ID indefinido o un cargador ausente provoca una aserción; los errores del cargador se propagan. |
| `release(consumer, resourceId)` | Elimina al consumidor; llama a `release` del cargador cuando no queda ninguno. Ignora recursos o consumidores desconocidos. |
| `releaseAll(consumer)` | Libera el interés del consumidor en todos los recursos en caché. |
| `releaseResource(resourceId)` | Fuerza la liberación y elimina el recurso de la caché, independientemente de sus consumidores; ignora IDs desconocidos. |
| `releaseAllResources()` | Fuerza la liberación de todos los recursos en caché, independientemente de sus consumidores. |

Un consumidor es una clave de tabla Lua distinta de `nil`, normalmente un objeto. La propiedad se registra como **conjunto**, no como contador de referencias: varias llamadas a `get` del mismo consumidor añaden una sola entrada, por lo que un solo `release` elimina su interés. IDs distintos se almacenan por separado incluso si apuntan al mismo archivo. Tras liberar al último consumidor, otro `get` vuelve a cargar el recurso. Las liberaciones forzadas pueden invalidar referencias que aún conservan los consumidores; estos no deberían liberar manualmente el valor compartido.

## Ejemplo

La escena de pausa usa la definición real `pause_font` y renuncia a su interés solo al destruirse:

```lua
function Pause:onLoad()
    self.font = self.context.resourceManager:get(self, "pause_font")
end

function Pause:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

Si otro consumidor ha solicitado `pause_font`, permanece en caché hasta que también lo libere. En `Engine:quit()` se vacían las escenas, se cierra audio y después se liberan forzosamente los recursos restantes; un error en una fase anterior puede impedir la limpieza posterior.
