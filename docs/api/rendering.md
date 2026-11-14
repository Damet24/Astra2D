# Rendering

`require("engine.graphics.render_pipeline")` orders draw callbacks; `require("engine.ecs.systems.renderSystem")` submits ECS sprites. Neither is required to draw a scene. They use LÖVE graphics and should run within the appropriate draw context.

## Render pipeline

`RenderPipeline.new()` returns an empty pipeline. Methods return no values.

| Method | Parameters and effect |
| --- | --- |
| `add(layer, draw)` | Appends a no-argument callback; `nil`/`false` layer defaults to 0. Asserts unless layer is numeric and draw is a function. |
| `draw()` | Sorts by ascending layer, then insertion order, and calls each callback. Does not clear items; repeated calls redraw them. Callback errors propagate and interrupt drawing. |
| `clear()` | Discards all items. |

Equal-layer ordering across tilemaps and sprites depends on submission order. Clear and resubmit when the desired contents change.

## ECS render system

`RenderSystem.submit(world, pipeline)` queries `Transform` and `Sprite`, sorts matching entity IDs ascending, then adds a callback per sprite with `Sprite.layer` (default 0). `RenderSystem.draw(world)` creates and draws a separate temporary pipeline; it can be registered as a world draw system but cannot interleave with a separately drawn tilemap. `RenderSystem.drawEntity(world, renderable)` draws one supplied `{ entity, transform, sprite }` record immediately. All return no values.

Required draw data is `Transform.x/y` and normally `Sprite.image`; optional fields are `Transform.rotation` (radians, default 0), `Sprite.origin = { x, y }` (defaults 0), `flipH`/`flipV`, and numeric `layer`. If `Animation.current` selects `Sprite.animations[current]` and `Animation.frame` selects a frame, that animation's `image` and quad are drawn instead; otherwise the static image is drawn. Each entity draw pushes all graphics state, sets white, draws, then pops. No explicit data validation or protected cleanup is added; LÖVE errors propagate.

## Example

```lua
local Pipeline = require("engine.graphics.render_pipeline")
local RenderSystem = require("engine.ecs.systems.renderSystem")
local pipeline = Pipeline.new()
-- In a scene draw, with world and tileRenderer created during setup:
pipeline:clear()
tileRenderer:submit(pipeline)
RenderSystem.submit(world, pipeline)
pipeline:draw() -- or camera:draw(function() pipeline:draw() end)
```

See [tilemaps](tilemap.md), [graphics utilities](graphics-utils.md), [camera](camera.md), [rendering architecture](../architecture/modules/rendering.md), and the [Tiled guide](../guides/tiled.md).
