# Engine API

Module: `require("engine.engine")`. Composes the shared services and bridges LÖVE callbacks. See [architecture](../architecture/modules/engine.md) and [first project](../getting-started/first-project.md).

## Configuration and dependencies

`Engine.new(config)` accepts a table (nil becomes `{}`, which still fails required fields). It shallow-copies the top level and the `window`, `rendering` and `audio` tables; nested values are not generally copied.

| Field | Contract |
| --- | --- |
| `initialScene` | Required non-empty string, relative to `scenesPath`. |
| `scenesPath` | Non-empty string; default `"game.scenes"`. |
| `inputMaps` | Required table; `{}` is valid. Each action is a table with optional `keys`, `mouse`, and `gamepad` sections. It is passed to [InputManager](input-manager.md) without validation. |
| `resourceDefinitions` | Table by ID; default `{}`. |
| `resourceLoaders` | Table by type; defaults to the built-in registry. A supplied table replaces it; see [ResourceManager](resource-manager.md). |
| `window` | Optional table; if supplied, `width` and `height` must be positive finite integers; `fullscreen`, `resizable`, `vsync` are booleans defaulting to `false`, `true`, `true`. If absent, window mode is unchanged. |
| `rendering` | Table defaulting to `{}`: `width = 1280`, `height = 720` (positive finite integers), `pixelPerfect = false` (boolean), `backgroundColor = {0, 0, 0, 1}` (contiguous RGB/RGBA numbers in `[0, 1]`; RGB gets alpha 1). Pixel-perfect selects Shove's `pixel` fit, otherwise `aspect`. |
| `audio` | Table defaulting to `{}`; `masterVolume`, `musicVolume`, `sfxVolume` each default to `1.0`. Types and ranges are not validated. |

Constructs ResourceManager, AudioManager, GameContext, EventManager, SceneLoader, SceneManager and InputManager. The context gains the scene, event, and input managers during construction and the Shove viewport during `load`. Loading and drawing require LÖVE and Shove.

## Methods

Unless otherwise stated, methods return **no values**; callback, loader, LÖVE and cleanup errors propagate.

| Signature | Result and effects |
| --- | --- |
| `Engine.new(config)` | Returns an engine, without loading scenes. Invalid config or input maps raise assertions. |
| `engine:load()` | Asserts not loaded or closed; optionally sets window mode (asserts success), sets background and viewport, queues initial scene and processes one batch, marks loaded, then installs the LÖVE input callbacks. |
| `engine:update(dt)` | `dt`: elapsed seconds. If loaded and not closed, dispatches queued events, recomputes gamepad axis edges, updates scenes and their pending batch, updates audio, then clears input edges and mouse delta; otherwise no-op. |
| `engine:draw()` | If active, draws scenes between viewport `beginDraw` and `endDraw`; otherwise no-op. |
| `engine:keypressed(key)`, `engine:keyreleased(key)`, `engine:mousepressed(...)`, `engine:mousereleased(...)`, `engine:mousemoved(...)`, `engine:gamepadpressed(...)`, `engine:gamepadreleased(...)`, `engine:gamepadaxis(...)`, `engine:joystickadded(...)`, `engine:joystickremoved(...)` | Forward the LÖVE input event to the input manager, even before load or after close. |
| `engine:quit()` | If not closed, queues clear, processes one batch, shuts down audio, forcibly releases remaining resources, then marks closed. Subsequent successful calls are no-ops. |

`load` and `quit` are not transactional. Previously queued transitions run before quit's clear; callbacks can queue a later batch, which quit does not drain. Errors may interrupt cleanup and prevent the closed flag from being set. See [SceneManager](scene-manager.md).

## Example

```lua
local Engine = require("engine.engine")
local engine = Engine.new({
    initialScene = "mainMenu",
    inputMaps = require("game.config.inputMaps"),
    resourceDefinitions = require("game.config.resourceDefinitions"),
})
function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.quit() engine:quit() end
```

`Engine:load()` installs the LÖVE keyboard, mouse, gamepad, and joystick callbacks, replacing any handlers defined before `load`. Do not forward them from `main.lua`; define custom handlers after `engine:load()` and call the matching engine method yourself.
