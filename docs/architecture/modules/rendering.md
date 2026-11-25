# Rendering

Rendering combines independent pieces: the engine's logical-resolution viewport, an optional camera transform, and optional draw ordering through a pipeline. A scene can draw directly without a world, camera, or pipeline. The level in `game/scenes/levels/level.lua` draws a background in logical space, then a tilemap, sprites, and physics debug geometry through its active camera.

```text
LÖVE window (physical coordinates)
  └─ Shove viewport (logical coordinates)
       ├─ logical-space background / UI
       └─ optional Camera (world transform)
            └─ optional RenderPipeline (layer order)
```

## Engine viewport

`Engine:load()` configures Shove using `rendering.width` and `rendering.height` (positive integers, default `1280 × 720`). `rendering.pixelPerfect` defaults to false: false uses aspect-fit scaling, true uses integer scaling and nearest filtering. A window smaller than the logical resolution is clipped in integer mode. `rendering.backgroundColor` is an RGB or RGBA array in the range 0–1, default opaque black. `window.width` / `window.height`, when window settings are supplied, set the physical window independently. The normal LÖVE loop clears to the background color; custom loops must clear themselves.

`Engine:draw()` calls `viewport.beginDraw()`, draws the scene stack, then calls `viewport.endDraw()`. A scene can call `context.viewport.getViewportDimensions()` and `context.viewport.screenToViewport(screenX, screenY)`, which returns `inside, logicalX, logicalY`. Shove is shared; only one engine should render at a time. Engine drawing is not protected against errors: an error in a scene can prevent `endDraw()`.

## Pipeline API and ordering

`RenderPipeline.new()` creates an empty list. `pipeline:add(layer, draw)` adds a no-argument callback with a numeric layer (nil defaults to 0); invalid layer or callback types assert. `pipeline:draw()` sorts by ascending layer, then insertion order for equal layers, and invokes the callbacks. It does not clear the list; callbacks run again on the next draw. `pipeline:clear()` discards all items. Callbacks are not protected; an error interrupts drawing. Deterministic equal-layer ordering depends on deterministic submission order.

## Tilemaps and ECS sprites

`TilemapRender.new(map, tilesets)` retains the supplied Tiled-style map and a table keyed by tileset name, where each entry has `image` and `quads`. `engine.graphics.utils.loadQuads(image, tileWidth, tileHeight)` builds that shape in row-major order. `submit(pipeline)` adds one item for each visible `tilelayer`, using `layer.properties.layer` or, if absent, the layer's 1-based position in `map.layers` (including non-tile layers). `render()` draws visible tile layers directly in map order, without pipeline interleaving; `renderLayer(layer)` draws one layer directly.

The renderer reads a flat row-major `layer.data`, layer or map width/height, map `tilewidth`/`tileheight`, layer tile offsets `x`/`y`, pixel offsets `offsetx`/`offsety`, and opacity (default 1). It selects a tileset using ascending `map.tilesets` `firstgid` ranges and looks up `quads[gid - firstgid + 1]`; missing tilesets/quads are skipped. It does not decode Tiled GID flip flags, render object/group/image layers, handle infinite/chunked tile data, or implement culling. Supply compatible finite tile layers and tilesets.

`RenderSystem.submit(world, pipeline)` queries `Transform` + `Sprite`, sorts matching entity IDs ascending before submission, and uses `Sprite.layer` (default 0). Equal-layer sprites therefore follow entity ID order, but their order relative to tile layers follows submission order. It uses `Transform.x`, `y`, optional `rotation`, `Sprite.image`, optional `origin.x/y`, and `flipH`/`flipV`. If `Animation` selects a valid `Sprite.animations[current].frames[frame]`, it draws that quad with the animation image; otherwise it draws `Sprite.image`. `RenderSystem.draw(world)` makes a separate temporary pipeline; registering it as a world draw system is convenient but does not interleave sprites with a separately rendered tilemap. The `World` does not register it automatically.

A typical scene with a world and optional camera can submit both types together:

```lua
local RenderPipeline = require("engine.graphics.RenderPipeline")
local RenderSystem = require("engine.ecs.systems.renderSystem")
-- During setup: self.pipeline = RenderPipeline.new()
-- self.tilemapRender, self.world, and optionally self.cameraManager are scene-owned.
function Level:draw()
    self.pipeline:clear()
    self.tilemapRender:submit(self.pipeline)
    RenderSystem.submit(self.world, self.pipeline)
    local camera = self.cameraManager and self.cameraManager:getActive()
    if camera then
        camera:draw(function() self.pipeline:draw() end)
    else
        self.pipeline:draw() -- explicit policy: draw without a world transform
    end
    -- Draw logical-space UI here.
end
```

Use a different fallback if world-space rendering requires a camera. `camera:draw` restores its graphics state on callback errors subject to the stack restrictions described in [Camera manager](camera-manager.md); it does not protect the engine's outer viewport. See [World](world.md) and [Scene](scene.md) for update and ownership.
