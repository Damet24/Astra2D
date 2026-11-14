# Scene

`engine/scene/scene.lua` defines the minimal interface for a part of the game: a menu, level, pause overlay, or another independently managed state. A scene coordinates its own behavior and any resources it chooses to create; it does not need a `World`, camera, or render pipeline. For example, `game/scenes/pause.lua` draws a logical-space overlay without any of them, while `game/scenes/levels/level.lua` creates all three.

## Construction and public hooks

- `Scene.new()` returns an instance with `updateBelow = false` and `drawBelow = false`. It does not store the context or allocate other services.
- Override `onLoad()`, `onEnter()`, `onExit()`, and `onDestroy()` for lifecycle work; the base implementations do nothing.
- Override `update(dt)` and `draw()` for per-frame behavior; the base implementations do nothing. `dt` is the elapsed frame time in seconds supplied by LÖVE.
- The loader calls a scene module's `new(context)`. A subclass must store `context` itself if needed. The context provides shared services such as `sceneManager`, `resourceManager`, `audioManager`, `inputManager`, and, after engine loading, `viewport`.

A minimal overlay, with no world or camera:

```lua
local Scene = require("engine.scene.scene")
local Overlay = {}
Overlay.__index = Overlay
setmetatable(Overlay, { __index = Scene })

function Overlay.new(context)
    local self = setmetatable(Scene.new(), Overlay)
    self.context = context
    self.drawBelow = true
    return self
end

function Overlay:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop()
    end
end

function Overlay:draw()
    love.graphics.print("Paused", 10, 10)
end

return Overlay
```

Place the module under the configured `scenesPath` and push its identifier. With `drawBelow = true` and the default `updateBelow = false`, lower scenes can be drawn but are not updated. The flags are independent: the manager walks down from the top until it finds a false flag, then updates or draws the selected range from bottom to top. A lower scene's own flag decides whether the walk continues beneath it.

## Lifecycle and relationships

`SceneLoader` resolves `scenesPath .. "." .. sceneName` (default prefix `game.scenes`), requires a table with a `.new` function and calls `new(context)`. `SceneManager` owns the stack; scenes request `push`, `pop`, `replace`, `clear`, or `clearAndPush` through `context.sceneManager`. Requests are queued, not applied immediately: normally they are processed after scene updates; engine load and quit process them explicitly. Operations enqueued during processing wait for a later processing pass. Although transitions accept a `dependencies` table, the current loader ignores it.

For nonempty stacks, callback order is:

| Operation | Order |
| --- | --- |
| `push` | New `onLoad`; previous top `onExit`; new `onEnter`. |
| `pop` | Top `onExit`, then `onDestroy`; revealed scene `onEnter`. |
| `replace` | New `onLoad`; old top `onExit` and `onDestroy`; new `onEnter`. |
| `clear` | Top `onExit`; every scene `onDestroy`, top to bottom. |
| `clearAndPush` | New `onLoad`; every old scene `onExit`, then every old scene `onDestroy`, each top to bottom; new `onEnter`. |

An empty `pop` is a no-op. `onEnter` and `onExit` may run again as a scene is covered or revealed; notably, `clearAndPush` calls `onExit` even for already covered scenes. Callbacks are not protected transactions: an error can interrupt the sequence and cleanup. A scene that acquires resources should release them in `onDestroy`, e.g. `context.resourceManager:releaseAll(self)`; no automatic world, camera, or resource cleanup is supplied by the base class.

During an engine frame, the scene manager updates first, then audio, then input's transient state is cleared. Drawing occurs inside the engine's logical-resolution viewport. See [World](world.md), [Camera manager](camera-manager.md), and [Rendering](rendering.md) for optional scene-owned building blocks.
