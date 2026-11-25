# Renderizado

`require("engine.graphics.RenderPipeline")` ordena callbacks de dibujo; `require("engine.ecs.systems.renderSystem")` envía sprites ECS. Ninguno es obligatorio para dibujar una escena. Usan gráficos de LÖVE y deben ejecutarse en el contexto de dibujo apropiado.

## Pipeline de renderizado

`RenderPipeline.new()` devuelve un pipeline vacío. Los métodos no devuelven valores.

| Método | Parámetros y efecto |
| --- | --- |
| `add(layer, draw)` | Añade un callback sin argumentos; si la capa es `nil`/`false`, vale 0. Exige una capa numérica y una función de dibujo. |
| `draw()` | Ordena por capa ascendente y luego por orden de inserción, y llama a cada callback. No vacía los elementos; llamadas repetidas los redibujan. Los errores de callbacks se propagan e interrumpen el dibujo. |
| `clear()` | Descarta todos los elementos. |

El orden entre tilemaps y sprites de igual capa depende del orden de envío. Vacía y vuelve a enviar cuando cambie el contenido deseado.

## Sistema de renderizado ECS

`RenderSystem.submit(world, pipeline)` consulta `Transform` y `Sprite`, ordena los IDs coincidentes de menor a mayor y añade un callback por sprite con `Sprite.layer` (0 por defecto). `RenderSystem.draw(world)` crea y dibuja un pipeline temporal independiente; puede registrarse como sistema de dibujo del mundo, pero no intercalarse con un tilemap dibujado por separado. `RenderSystem.drawEntity(world, renderable)` dibuja inmediatamente un registro `{ entity, transform, sprite }` suministrado. Ninguno devuelve valores.

Los datos necesarios para dibujar son `Transform.x/y` y normalmente `Sprite.image`; los campos opcionales son `Transform.rotation` (radianes, 0 por defecto), `Sprite.origin = { x, y }` (0 por defecto), `flipH`/`flipV` y `layer` numérico. Si `Animation.current` selecciona `Sprite.animations[current]` y `Animation.frame` selecciona un frame, se dibujan la imagen y quad de esa animación; en caso contrario se dibuja la imagen estática. Cada dibujo de entidad guarda todo el estado gráfico, establece blanco, dibuja y restaura el estado. No se añade validación explícita de datos ni limpieza protegida; se propagan los errores de LÖVE.

## Ejemplo

```lua
local Pipeline = require("engine.graphics.RenderPipeline")
local RenderSystem = require("engine.ecs.systems.renderSystem")
local pipeline = Pipeline.new()
-- En el dibujo de una escena, con world y tileRenderer creados al iniciar:
pipeline:clear()
tileRenderer:submit(pipeline)
RenderSystem.submit(world, pipeline)
pipeline:draw() -- o camera:draw(function() pipeline:draw() end)
```

Consulta [tilemaps](tilemap.md), [utilidades gráficas](graphics-utils.md), [cámara](camera.md), la [arquitectura de renderizado](../architecture/modules/rendering.md) y la [guía de Tiled](../guides/tiled.md).
