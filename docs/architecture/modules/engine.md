# Engine

`engine/engine.lua` is the composition root and LÖVE-facing lifecycle coordinator. The game supplies scene and service descriptions; `Engine` assembles the shared services and drives them, rather than replacing LÖVE's loop. See the [architecture overview](../overview.md).

## Responsibilities and relationships

`Engine.new(config)` normalizes and validates configuration, then constructs [ResourceManager](resource-manager.md), [AudioManager](audio-manager.md), [GameContext](game-context.md), [EventManager](/api/events), [SceneLoader](scene-loader.md), [SceneManager](scene-manager.md), and [InputManager](input-manager.md). The audio manager shares the resource manager. The context is created before the scene manager, passed to the loader, and populated with the scene, event, and input managers. `load` adds the Shove viewport to that same context before loading the initial scene; see [rendering](rendering.md). Scenes receive the context, not the engine.

## Configuration

`config` must be a table. Defaults are applied to missing fields, not invalid values. The engine copies the top-level configuration and the `window`, `rendering`, and `audio` tables; this is not a deep copy.

| Field | Default / requirement | Meaning |
| --- | --- | --- |
| `initialScene` | **Required**, non-empty string | Initial scene identifier, resolved relative to `scenesPath`. |
| `scenesPath` | `"game.scenes"`; non-empty string | Lua module prefix for scenes. |
| `inputMaps` | **Required** table; `{}` is valid | Actions map to tables with optional `keys`, `mouse`, and `gamepad` sections. The engine passes the table to `InputManager` without validating its shape. |
| `resourceDefinitions` | `{}`; table | Definitions keyed by resource ID. |
| `resourceLoaders` | `engine.resources.loaders.loaders`; table | Loader table keyed by resource type; the default has `image`, `sound`, and `font`. A supplied table replaces it. |
| `window` | Omitted: no `love.window.setMode` call | If supplied, must be a table with positive finite integer `width` and `height` (both required). `fullscreen` defaults to `false`, `resizable` to `true`, and `vsync` to `true`; each must be boolean. |
| `rendering` | Table, default `{}` | Logical viewport settings described below. |
| `rendering.width`, `rendering.height` | `1280`, `720` | Positive finite integers; independent of window dimensions. |
| `rendering.pixelPerfect` | `false`; boolean | Selects Shove's `pixel` fit method when true, `aspect` otherwise. |
| `rendering.backgroundColor` | `{ 0, 0, 0, 1 }` | Contiguous RGB or RGBA array of numbers in `[0, 1]`; RGB is normalized to RGBA with alpha `1`. |
| `audio` | Table, default `{}` | Initial volumes passed to the audio manager. |
| `audio.masterVolume`, `audio.musicVolume`, `audio.sfxVolume` | `1.0` each | The engine does not validate their types or ranges; audio playback multiplies master by the corresponding music or SFX volume. |

`Engine.new(nil)` starts with an empty table but cannot succeed without `initialScene` and `inputMaps`. Definitions and loader entries are used when resources are requested; an unknown ID or resource type fails at that point.

## Public lifecycle

| Method | Behavior |
| --- | --- |
| `Engine.new(config)` | Creates services and returns an engine; it does not load a scene. |
| `engine:load()` | Optionally sets window mode, sets the background, configures the viewport, queues `initialScene`, processes one pending batch, then installs the LÖVE input callbacks. Rejects an already loaded or closed engine. |
| `engine:update(dt)` | Dispatches queued events, recomputes gamepad axis edges, updates scenes and processes their pending transitions, updates audio, then clears input's transient flags and mouse delta. No-op before load or after close. |
| `engine:draw()` | Wraps scene drawing in viewport `beginDraw`/`endDraw`. No-op before load or after close. |
| `engine:keypressed(key)`, `engine:keyreleased(key)`, `engine:mousepressed(...)`, `engine:mousereleased(...)`, `engine:mousemoved(...)`, `engine:gamepadpressed(...)`, `engine:gamepadreleased(...)`, `engine:gamepadaxis(...)`, `engine:joystickadded(...)`, `engine:joystickremoved(...)` | Forward the LÖVE input event to `InputManager`; these methods are not guarded by the loaded/closed flags. |
| `engine:quit()` | Queues `clear`, processes one pending batch, shuts down audio, releases remaining resources, then marks the engine closed. A later successful call is a no-op. |

Input is cleared after all selected scenes update, allowing them to inspect `isJustPressed` and `isJustReleased` during that update. Gamepad axes are converted to edges before the scenes update. During shutdown, previously queued operations run **before** the clear. Clear exits only the top scene, then destroys all scenes top to bottom. Operations queued by lifecycle callbacks during processing remain in the next batch; `quit` does not drain that batch. The phases are not protected against errors: a failure can prevent later cleanup and leave the engine not marked closed. See [SceneManager](scene-manager.md) for precise ordering.

## Example: LÖVE entry point

The identifiers below exist in the repository's game. With no `window` table, LÖVE's existing window mode is left unchanged.

```lua
local Engine = require("engine.engine")
local engine = Engine.new({
    initialScene = "levels.level01",
    inputMaps = require("game.inputMaps"),
    resourceDefinitions = require("game.resources.definitions"),
    rendering = { width = 256, height = 240, pixelPerfect = true },
})

function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.quit() engine:quit() end
```

`Engine:load()` installs the LÖVE keyboard, mouse, gamepad, and joystick callbacks, replacing any handlers defined before `load`. Do not forward them from `main.lua`; a custom handler must be installed after `load` and call the corresponding engine method. `load` and `quit` are not transactional; an error in a scene callback can interrupt either operation.
