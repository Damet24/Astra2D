# Graphics utilities

`require("engine.graphics.utils")` exports two functions for slicing an existing LÖVE image into quads. They call `image:getDimensions()` and `love.graphics.newQuad`; they do not load images or manage their lifetime.

## API

| Function | Parameters, return and effect |
| --- | --- |
| `loadQuads(image, width, height)` | Returns `{ image = image, quads = quads }`, with a quad per complete cell. Suitable for [tilemap rendering](tilemap.md). |
| `loadAnimation(image, frameWidth, frameHeight, frameDuration)` | Returns `{ image = image, frames = frames, frameDuration = frameDuration }`. Suitable for `Sprite.animations`. Duration is stored unchanged. |

Both enumerate left-to-right, top-to-bottom, using the full image dimensions as the quad reference; incomplete right or bottom edges are ignored. If no complete cells fit, the array is empty. Supply positive numeric cell dimensions and a valid image; the helpers do not explicitly validate input, and Lua or LÖVE errors can propagate. `loadAnimation` does not validate duration, but `AnimationSystem` asserts a positive numeric `frameDuration` when the selected animation is playing.

## Example

```lua
local Utils = require("engine.graphics.utils")
local image = love.graphics.newImage("sprites.png")
local animation = Utils.loadAnimation(image, 32, 32, 0.1)
local tileset = Utils.loadQuads(image, 16, 16)
-- animation.frames and tileset.quads are 1-based arrays.
```

See [rendering](rendering.md), [world](world.md), [rendering architecture](../architecture/modules/rendering.md), and the [Tiled guide](../guides/tiled.md).
