# Tilemaps

Two separate modules exist. `require("engine.tilemap.tilemap")` exports `Map.new(data, width, height, cellSize)`, which stores those arguments and returns a map; `map:render()` is currently empty and returns nothing. This simple map is not the Tiled-style input required by the renderer below.

## Tilemap renderer

`require("engine.tilemap.tilemaprender")` exports `TilemapRender.new(map, tilesets)`, which retains both tables and returns a renderer. It does not load or validate them. Its methods return no values:

| Method | Parameters and effect |
| --- | --- |
| `renderLayer(layer)` | Draws one layer immediately, regardless of type or visibility. |
| `render()` | Draws visible `tilelayer` entries in `map.layers` order. |
| `submit(pipeline)` | Adds a callback for each visible `tilelayer`, at `layer.properties.layer` or its 1-based position in `map.layers` (including non-tile layers). The pipeline validates the layer. |

The finite Tiled-style map needs `width`, `height`, `tilewidth`, `tileheight`, `layers`, and ascending `tilesets = { { name, firstgid }, ... }`. A layer uses flat row-major `data` (1-based Lua array); its `width`/`height` default to the map dimensions. `x`/`y` are tile offsets, `offsetx`/`offsety` pixel offsets, and `opacity` defaults to 1. `visible = false` hides a layer in `render` and `submit`. Tileset resources are keyed by name and contain `image` and `quads`; `loadQuads` creates this structure.

A zero or missing GID is empty. A positive GID selects the corresponding `firstgid` range and `quads[gid - firstgid + 1]`; missing tilesets or individual quads are skipped (an existing tileset must have a `quads` table). The renderer pushes all graphics state, sets white with layer opacity, draws, and pops. Malformed data or graphics errors may propagate; cleanup is not protected on error. It does not decode Tiled flip flags, render object/group/image layers, handle infinite chunks or cull tiles.

## Example

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
renderer:render() -- call during drawing
```

For interleaving with sprites, use [rendering](rendering.md); see [graphics utilities](graphics-utils.md), [rendering architecture](../architecture/modules/rendering.md), and the [Tiled guide](../guides/tiled.md).
