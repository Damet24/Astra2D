# Tilemaps

Existen dos módulos distintos. `require("engine.tilemap.tilemap")` exporta `Map.new(data, width, height, cellSize)`, que guarda esos argumentos y devuelve un mapa; `map:render()` está vacío actualmente y no devuelve nada. Este mapa simple no es la entrada de estilo Tiled que requiere el renderizador siguiente.

## Renderizador de tilemaps

`require("engine.tilemap.tilemaprender")` exporta `TilemapRender.new(map, tilesets)`, que conserva ambas tablas y devuelve un renderizador. No las carga ni valida. Sus métodos no devuelven valores:

| Método | Parámetros y efecto |
| --- | --- |
| `renderLayer(layer)` | Dibuja una capa inmediatamente, independientemente de su tipo o visibilidad. |
| `render()` | Dibuja las entradas `tilelayer` visibles en el orden de `map.layers`. |
| `submit(pipeline)` | Añade un callback por cada `tilelayer` visible, en `layer.properties.layer` o su posición desde 1 en `map.layers` (incluidas capas no tile). El pipeline valida la capa. |

El mapa finito de estilo Tiled necesita `width`, `height`, `tilewidth`, `tileheight`, `layers` y `tilesets = { { name, firstgid }, ... }` en orden ascendente. Una capa usa `data` plano por filas (array Lua desde 1); su `width`/`height` toma por defecto las dimensiones del mapa. `x`/`y` son desplazamientos en tiles, `offsetx`/`offsety` en píxeles y `opacity` vale 1 por defecto. `visible = false` oculta la capa en `render` y `submit`. Los recursos de tileset se indexan por nombre y contienen `image` y `quads`; `loadQuads` crea esta estructura.

Un GID cero o ausente es vacío. Un GID positivo selecciona el intervalo `firstgid` correspondiente y `quads[gid - firstgid + 1]`; se omiten los tilesets o quads individuales ausentes (un tileset existente debe tener una tabla `quads`). El renderizador guarda todo el estado gráfico, establece blanco con la opacidad de la capa, dibuja y restaura el estado. Pueden propagarse errores de datos mal formados o gráficos; la limpieza no está protegida ante errores. No decodifica flags de volteo de Tiled, no dibuja capas de objetos/grupos/imágenes, no maneja chunks infinitos ni descarta tiles fuera de pantalla.

## Ejemplo

```lua
local Utils = require("engine.graphics.utils")
local TilemapRender = require("engine.tilemap.tilemaprender")
local image = love.graphics.newImage("terrain.png")
local map = {
    width = 2, height = 1, tilewidth = 16, tileheight = 16,
    tilesets = { { name = "terrain", firstgid = 1 } },
    layers = { { type = "tilelayer", data = { 1, 0 }, properties = { layer = 10 } } },
}
local renderer = TilemapRender.new(map, { terrain = Utils.loadQuads(image, 16, 16) })
renderer:render() -- llamar durante el dibujo
```

Para intercalar sprites, consulta [renderizado](rendering.md); consulta también [utilidades gráficas](graphics-utils.md), la [arquitectura de renderizado](../architecture/modules/rendering.md) y la [guía de Tiled](../guides/tiled.md).
