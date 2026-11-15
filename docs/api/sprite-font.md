# Sprite fonts

`require("engine.graphics.spriteFont")` exports `SpriteFont.new(config)`, a bitmap font that draws text glyph by glyph from a prepared image. Each character is a quad in the sheet; the font positions and scales those quads itself.

Unlike the `font` resource type, which creates a LÖVE font from a numeric size, a sprite font uses a glyph sheet and a character-to-quad map. It does not load images, slice sheets, or register with `ResourceManager`. Load the sheet through a resource or directly, create quads with [`loadQuads`](graphics-utils.md), and build the map with [`createGlyphMap`](graphics-utils.md) or by hand.

## Constructor

`SpriteFont.new(config)` returns a font. It asserts only that `config.image`, `config.quads` and `config.glyphs` are present; it does not validate their types or contents.

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `image` | LÖVE image | required | Sheet used for every glyph. |
| `quads` | array of quads | required | 1-based quads drawn for glyphs. |
| `glyphs` | table | required | Maps a character key to an index in `quads`. |
| `glyphWidth` | number | `8` | Horizontal advance per character, before scale. |
| `glyphHeight` | number | `8` | Only the default for `lineHeight`; it does not size glyphs. |
| `spacing` | number | `0` | Extra horizontal distance after each character. |
| `lineHeight` | number | `glyphHeight` | Vertical advance per line, before scale. |
| `fallback` | string | `nil` | Glyph key used when a character has no mapping. |
| `uppercase` | boolean | `false` | Uppercases each character before lookup. |

`glyphWidth` must match the cell width in the sheet. `draw` places each quad at the cursor and advances by `glyphWidth + spacing`; the quad's own dimensions determine the pixels drawn, so a different cell width causes gaps or overlap. `glyphHeight` is not used while drawing, only to derive `lineHeight` when that field is omitted.

## Methods

| Method | Parameters, return and effect |
| --- | --- |
| `getWidth(text)` | Returns the widest line in pixels, using `glyphWidth + spacing` per character and removing the final spacer. Empty text returns `0`. It takes no scale, so multiply the result yourself when drawing scaled. |
| `getHeight(text)` | Returns `lines * lineHeight`, where lines is `1` plus the number of `"\n"` characters. Empty text is one line; a trailing newline adds an empty line. It takes no scale. |
| `draw(text, x, y, scale)` | Draws text with its top-left at `x, y`; `scale` is uniform and defaults to `1`. `"\n"` returns the cursor to `x` and advances `y` by `lineHeight * scale`. Returns no value. |

`draw` uses the current LÖVE graphics state: it does not set color, blend mode, shader, or font, and it does not push or pop. Isolate any changes with `love.graphics.push("all")` and `love.graphics.pop()`. All measurement and drawing happen immediately; nothing is queued for a [render pipeline](rendering.md).

## Glyph lookup and limitations

The lookup key is the character itself, or `char:upper()` when `uppercase = true`. An absent key falls back to `glyphs[config.fallback]`; if that key is also absent, no quad is drawn. A missing glyph still advances the cursor by the fixed width, and a space is a normal character: if `" "` has no mapping, a configured fallback glyph is drawn for every space. Map `" "` explicitly, and remember that failed lookups silently render nothing rather than raising an error.

Only `"\n"` is treated specially. Other control characters, including `"\r"` and `"\t"`, are looked up like ordinary characters and need glyphs or a fallback. Iteration is byte by byte (`gmatch(".")`), so multi-byte UTF-8 characters are split into separate bytes and cannot be mapped as one glyph.

The font assumes fixed-width glyphs. It has no kerning, per-character widths, word wrapping, alignment, or rich text; build those above `getWidth`, `getHeight` and `draw`. Glyph indexes that do not exist in `quads` are skipped while still advancing. Supplying invalid tables or a non-string `text` can raise Lua or LÖVE errors.

## Example

```lua
local GraphicsUtils = require("engine.graphics.utils")
local SpriteFont = require("engine.graphics.spriteFont")

-- Slice 8x10 cells from a sheet. The glyph order must match the sheet layout.
local sheet = GraphicsUtils.loadQuads(love.graphics.newImage("text.png"), 8, 10)

local font = SpriteFont.new({
    image = sheet.image,
    quads = sheet.quads,
    glyphs = GraphicsUtils.createGlyphMap({
        "h", "e", "l", "o", "w", "r", "d", " ", "?",
    }),
    glyphWidth = 8,
    glyphHeight = 10,
    lineHeight = 10,
    spacing = 0,
    fallback = "?",
    uppercase = false,
})

local text = "hello\nworld"
local width = font:getWidth(text) -- unscaled
local height = font:getHeight(text)

-- In a scene's draw method:
love.graphics.push("all")
love.graphics.setColor(1, 1, 1, 1)
font:draw(text, (1280 - width) / 2, (720 - height) / 2)
love.graphics.pop()
```

The repository's `game/scenes/mainMenu.lua` and `game/scenes/pause.lua` use the same pattern with the `menu_text_white` sheet and the full character list.

See [graphics utilities](graphics-utils.md), [rendering](rendering.md), [resource manager](resource-manager.md), and the [resources guide](../guides/resources.md). For the separate LÖVE-font resource type, see [resource manager](resource-manager.md).
