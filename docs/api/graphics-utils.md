# Graphics utilities

`require("engine.graphics.utils")` exports helpers for slicing an existing LÖVE image into quads and for building the character map used by [sprite fonts](sprite-font.md). The slicing functions call `image:getDimensions()` and `love.graphics.newQuad`; they do not load images or manage their lifetime.

## API

| Function | Parameters, return and effect |
| --- | --- |
| `loadQuads(image, width, height)` | Returns `{ image = image, quads = quads }`, with a quad per complete cell. Suitable for [tilemap rendering](tilemap.md). |
| `loadAnimation(image, frameWidth, frameHeight, frameDuration)` | Returns `{ image = image, frames = frames, frameDuration = frameDuration }`. Suitable for `Sprite.animations`. Duration is stored unchanged. |
| `createGlyphMap(characters)` | Returns a table mapping each string in the 1-based `characters` array to its index. Suitable for `SpriteFont`'s `glyphs` field. |

`loadQuads` and `loadAnimation` enumerate left-to-right, top-to-bottom, using the full image dimensions as the quad reference; incomplete right or bottom edges are ignored. If no complete cells fit, the array is empty. Supply positive numeric cell dimensions and a valid image; the helpers do not explicitly validate input, and Lua or LÖVE errors can propagate. `loadAnimation` does not validate duration, but `AnimationSystem` asserts a positive numeric `frameDuration` when the selected animation is playing.

`createGlyphMap` iterates with `ipairs`, so the list must be a dense array starting at 1; it does not validate types. Repeated characters keep their last index, which is convenient for padding placeholders, but a repeated real character cannot map to two quads. The resulting values index the `quads` array and must match the sheet layout.

## Example

```lua
local Utils = require("engine.graphics.utils")
local image = love.graphics.newImage("sprites.png")
local animation = Utils.loadAnimation(image, 32, 32, 0.1)
local tileset = Utils.loadQuads(image, 16, 16)
local glyphs = Utils.createGlyphMap({ "a", "b", " " })
-- animation.frames and tileset.quads are 1-based arrays.
-- glyphs.a == 1, glyphs.b == 2, glyphs[" "] == 3.
```

See [sprite fonts](sprite-font.md), [rendering](rendering.md), [world](world.md), [rendering architecture](../architecture/modules/rendering.md), and the [Tiled guide](../guides/tiled.md).
