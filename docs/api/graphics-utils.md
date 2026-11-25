# Graphics utilities

`require("engine.graphics.utils")` exports helpers for slicing an existing LÖVE image into quads, for building the character map used by [sprite fonts](sprite-font.md), and for converting RGBA components or hex strings to LÖVE's normalized range. The slicing functions call `image:getDimensions()` and `love.graphics.newQuad`; they do not load images or manage their lifetime.

## API

| Function | Parameters, return and effect |
| --- | --- |
| `loadQuads(image, width, height)` | Returns `{ image = image, quads = quads }`, with a quad per complete cell. Suitable for [tilemap rendering](tilemap.md). |
| `loadAnimation(image, frameWidth, frameHeight, frameDuration)` | Returns `{ image = image, frames = frames, frameDuration = frameDuration }`. Suitable for `Sprite.animations`. Duration is stored unchanged. |
| `createGlyphMap(characters)` | Returns a table mapping each string in the 1-based `characters` array to its index. Suitable for `SpriteFont`'s `glyphs` field. |
| `rgba(r, g, b, a)` | Returns `{ r / 255, g / 255, b / 255, a / 255 }` for components given in the 0-255 range. `a` defaults to 255. |
| `hexToRgb(hex)` | Returns four numbers `r, g, b, a` in `[0, 1]`. Accepts 3, 6, or 8 hex digits with an optional leading `#`; 3-digit values are expanded (`#abc` becomes `#aabbcc`). Alpha is `1` unless 8 digits are given. |

`loadQuads` and `loadAnimation` enumerate left-to-right, top-to-bottom, using the full image dimensions as the quad reference; incomplete right or bottom edges are ignored. If no complete cells fit, the array is empty. Supply positive numeric cell dimensions and a valid image; the helpers do not explicitly validate input, and Lua or LÖVE errors can propagate. `loadAnimation` does not validate duration, but `AnimationSystem` asserts a positive numeric `frameDuration` when the selected animation is playing.

`createGlyphMap` iterates with `ipairs`, so the list must be a dense array starting at 1; it does not validate types. Repeated characters keep their last index, which is convenient for padding placeholders, but a repeated real character cannot map to two quads. The resulting values index the `quads` array and must match the sheet layout.

`rgba` returns a 4-element array suitable for `love.graphics.setColor(color)` or `rendering.backgroundColor`. Each component must be a number between 0 and 255; otherwise an error is raised. Passing `nil` for `a` uses 255 (opaque). Unlike the other helpers, it validates its input because an out-of-range result would be rejected by the [engine config](engine.md).

`hexToRgb` returns **four separate values**, not an array, so pass them directly to `love.graphics.setColor(r, g, b, a)` or unpack them where a table is expected. It accepts a string with an optional leading `#` and asserts `hex must be a string` / `hex must contain 3, 6, or 8 hexadecimal digits`; other characters are rejected. Use it for LÖVE calls; `rgba` is more convenient for config fields such as `rendering.backgroundColor`.

## Example

```lua
local Utils = require("engine.graphics.utils")
local image = love.graphics.newImage("sprites.png")
local animation = Utils.loadAnimation(image, 32, 32, 0.1)
local tileset = Utils.loadQuads(image, 16, 16)
local glyphs = Utils.createGlyphMap({ "a", "b", " " })
local background = Utils.rgba(46, 64, 87)
local translucent = Utils.rgba(255, 128, 0, 128)
local r, g, b, a = Utils.hexToRgb("#FF800080")
love.graphics.setColor(r, g, b, a) -- 1, 128/255, 0, 128/255
love.graphics.setColor(Utils.hexToRgb("fff")) -- blanco opaco
-- animation.frames and tileset.quads are 1-based arrays.
-- glyphs.a == 1, glyphs.b == 2, glyphs[" "] == 3.
-- background == { 46 / 255, 64 / 255, 87 / 255, 1 }
-- love.graphics.setColor(translucent)
```

See [sprite fonts](sprite-font.md), [rendering](rendering.md), [world](world.md), [rendering architecture](../architecture/modules/rendering.md), and the [Tiled guide](../guides/tiled.md).
