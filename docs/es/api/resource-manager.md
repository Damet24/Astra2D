# API de ResourceManager

Módulo: `require("engine.resources.resourceManager")`. Caché bajo demanda por ID de recurso, con propiedad mediante conjuntos de consumidores. Consulta la [arquitectura](../architecture/modules/resource-manager.md), la [guía de recursos](../guides/resources.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y cargadores

`ResourceManager.new(definitions, loaders)` devuelve un gestor vacío y conserva las tablas suministradas sin validarlas. `definitions[id]` es una definición con `type`; `loaders[type]` proporciona funciones simples `load(definition)`, que devuelve el recurso, y `release(resource)`, que lo libera. [Engine](engine.md) usa por defecto `{}` para definiciones y el registro integrado para cargadores; una tabla suministrada reemplaza ese registro.

| Tipo integrado | Definición | Carga / liberación |
| --- | --- | --- |
| `image` | `path`: cadena | `love.graphics.newImage(path)` / `image:release()`. |
| `sound` | `path`: cadena; `soundType`: `"static"` o `"stream"` | `love.audio.newSource(path, soundType)` / `source:release()`. |
| `font` | `size`: número | `love.graphics.newFont(size)` / `font:release()`; no usa ruta de fuente. |

Los cargadores integrados verifican estos campos mediante aserciones; LÖVE puede rechazar archivos o tamaños inválidos. Las imágenes usan el filtro predeterminado de LÖVE al crearse, no un campo de la definición. La configuración de Shove de Engine establece ese filtro antes de cargar la escena inicial.

## Métodos

`consumer` es una clave de tabla Lua no nula, normalmente la escena o el gestor de audio; `resourceId` es la clave de definición/caché. Excepto `get`, los métodos de instancia **no devuelven valores**.

| Firma | Resultado y efectos |
| --- | --- |
| `manager:get(consumer, resourceId)` | Devuelve el recurso en caché, cargándolo en el primer acceso, y registra al consumidor. IDs sin definición o tipos sin cargador provocan aserciones; los errores del cargador se propagan. |
| `manager:release(consumer, resourceId)` | Elimina el interés del consumidor; si era el último, llama a la liberación del cargador y elimina la entrada de caché. Ignora recursos o consumidores desconocidos. |
| `manager:releaseAll(consumer)` | Libera el interés de ese consumidor en todos los recursos en caché. |
| `manager:releaseResource(resourceId)` | Fuerza la liberación y eliminación de un recurso en caché sin importar sus consumidores; ignora IDs desconocidos. |
| `manager:releaseAllResources()` | Fuerza la liberación de todos los recursos en caché sin importar sus consumidores. |

La propiedad es un conjunto, no un contador de referencias: repetir `get` para el mismo consumidor solo requiere una liberación. Los IDs distintos se almacenan por separado, aunque usen el mismo archivo. Un `get` posterior recarga tras la liberación. La liberación forzada puede invalidar referencias existentes; no liberes directamente un valor compartido en caché. Los errores de liberación se propagan y pueden interrumpir la limpieza.

Las escenas deben liberar su interés ellas mismas, normalmente en `onDestroy`; [AudioManager](audio-manager.md) sigue siendo un consumidor independiente hasta su cierre. Al salir, Engine limpia escenas, cierra audio y fuerza la liberación de los recursos restantes; un error anterior puede impedir las fases posteriores.

## Ejemplo

```lua
function Pause:onLoad()
    self.font = self.context.resourceManager:get(self, "pause_font")
end
function Pause:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

`pause_font` está definido en el juego del repositorio; la fuente permanece en caché mientras otro consumidor la necesite.
