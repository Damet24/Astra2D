# Engine API

Module: `require("engine.engine")`. Composes the shared services and bridges LÖVE callbacks. See [architecture](../architecture/modules/engine.md) and [first project](../getting-started/first-project.md).

## Configuration and dependencies

`Engine.new(config)` accepts a table (nil becomes `{}`, which still fails required fields). It shallow-copies the top level and the `window`, `rendering` and `audio` tables; nested values are not generally copied.

| Field | Contract |
| --- | --- |
| `initialScene` | Required non-empty string, relative to `scenesPath`. |
| `scenesPath` | Non-empty string; default `"game.scenes"`. |
| `inputMaps` | Required table; `{}` is valid. Validated by [InputManager](input-manager.md). |
| `resourceDefinitions` | Table by ID; default `{}`. |
| `resourceLoaders` | Table by type; defaults to the built-in registry. A supplied table replaces it; see [ResourceManager](resource-manager.md). |
| `window` | Optional table; if supplied, `width` and `height` must be positive finite integers; `fullscreen`, `resizable`, `vsync` are booleans defaulting to `false`, `true`, `true`. If absent, window mode is unchanged. |
| `rendering` | Table defaulting to `{}`: `width = 1280`, `height = 720` (positive finite integers), `pixelPerfect = false` (boolean), `backgroundColor = {0, 0, 0, 1}` (contiguous RGB/RGBA numbers in `[0, 1]`; RGB gets alpha 1). Pixel-perfect selects Shove's `pixel` fit, otherwise `aspect`. |
| `audio` | Table defaulting to `{}`; `masterVolume`, `musicVolume`, `sfxVolume` each default to `1.0`. Types and ranges are not validated. |

Constructs ResourceManager, AudioManager, GameContext, SceneLoader, SceneManager and InputManager. The context gains scene/input managers during construction and the Shove viewport during `load`. Loading and drawing require LÖVE and Shove.

## Methods

Unless otherwise stated, methods return **no values**; callback, loader, LÖVE and cleanup errors propagate.

| Signature | Result and effects |
| --- | --- |
| `Engine.new(config)` | Returns an engine, without loading scenes. Invalid config or input maps raise assertions. |
| `engine:load()` | Asserts not loaded or closed; optionally sets window mode (asserts success), sets background and viewport, queues initial scene and processes one batch, then marks loaded. |
| `engine:update(dt)` | `dt`: elapsed seconds. If loaded and not closed, updates scenes and their pending batch, audio, then clears input edges; otherwise no-op. |
| `engine:draw()` | If active, draws scenes between viewport `beginDraw` and `endDraw`; otherwise no-op. |
| `engine:keypressed(key)` / `engine:keyreleased(key)` | Forward the LÖVE key string to input, even before load or after close. |
| `engine:quit()` | If not closed, queues clear, processes one batch, shuts down audio, forcibly releases remaining resources, then marks closed. Subsequent successful calls are no-ops. |

`load` and `quit` are not transactional. Previously queued transitions run before quit's clear; callbacks can queue a later batch, which quit does not drain. Errors may interrupt cleanup and prevent the closed flag from being set. See [SceneManager](scene-manager.md).

## Example

```lua
local Engine = require("engine.engine")
local engine = Engine.new({
    initialScene = "levels.level01",
    inputMaps = require("game.inputMaps"),
    resourceDefinitions = require("game.resources.definitions"),
})
function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.keypressed(key) engine:keypressed(key) end
function love.keyreleased(key) engine:keyreleased(key) end
function love.quit() engine:quit() end
```
