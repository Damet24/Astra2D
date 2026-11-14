# Build a pause overlay with scenes

## Goal and prerequisites

Create a running counter and a pause overlay. Escape pauses and resumes it; the counter remains visible underneath. Start from [Your First Project](/getting-started/first-project), including its LÖVE callbacks and `engine/` directory. This tutorial creates its own scenes and needs no image or audio files.

## 1. Configure the action and initial scene

Add `pause = { "escape" }` to the table in `game/inputMaps.lua`, keeping any existing actions. In `main.lua`, set `initialScene = "guideLevel"` in `Engine.new`; keep `inputMaps = require("game.inputMaps")` and the existing callbacks.

## 2. Create the running scene

Create `game/scenes/guideLevel.lua`:

```lua
local Scene = require("engine.scene.scene")
local Level = {}
Level.__index = Level
setmetatable(Level, { __index = Scene })

function Level.new(context)
    local self = setmetatable(Scene.new(), Level)
    self.context = context
    self.elapsed = 0
    return self
end

function Level:update(dt)
    self.elapsed = self.elapsed + dt
    if self.context.inputManager:isJustPressed("pause") then
        self.context.sceneManager:push("guidePause")
    end
end

function Level:draw()
    love.graphics.print(string.format("Time: %.1f", self.elapsed), 16, 16)
    love.graphics.print("Escape: pause", 16, 40)
end

return Level
```

## 3. Create the overlay and run

Create `game/scenes/guidePause.lua`:

```lua
local Scene = require("engine.scene.scene")
local Pause = {}
Pause.__index = Pause
setmetatable(Pause, { __index = Scene })

function Pause.new(context)
    local self = setmetatable(Scene.new(), Pause)
    self.context = context
    self.drawBelow = true
    return self
end

function Pause:update(dt)
    if self.context.inputManager:isJustPressed("pause") then
        self.context.sceneManager:pop()
    end
end

function Pause:draw()
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 320, 180)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Paused - press Escape", 16, 80)
    love.graphics.pop()
end

return Pause
```

Run `love .` from the project root. With the first project's 320 × 180 logical resolution, the overlay covers the screen; adapt the rectangle to your resolution. Press and release Escape, observe the counter freeze, then press Escape again to resume. The repository's `game/scenes/pause.lua` uses the same overlay pattern, and `game/scenes/levels/level.lua` pushes it.

## Lifecycle and transitions

The default `scenesPath` is `game.scenes`, so `guidePause` resolves to the module just created. `push` loads the new scene and calls its `onLoad`, then the previous top's `onExit`, then the new top's `onEnter`. `pop` calls the top's `onExit` and `onDestroy`, then the uncovered scene's `onEnter`. Put scene-owned resource cleanup in `onDestroy`, not `onExit`, because a covered scene can return. The base `Scene` supplies no-op hooks.

Here `drawBelow = true` draws the counter underneath, while the default `updateBelow = false` freezes it. The flags work independently and are evaluated down the stack. `replace` discards only the top; `clear` destroys the whole stack; `clearAndPush` clears it and starts a new scene.

## Errors and limitations

- Transitions are queued: the current update finishes before they are applied. Operations queued by lifecycle hooks during processing wait for another pass. Don't expect an immediate stack change.
- Missing modules or a module without a `.new(context)` constructor fail when the queued load is processed. The built-in loader ignores the optional transition `dependencies` argument; use `context` for shared services.
- `clearAndPush` calls `onExit` even on covered scenes; hooks should tolerate repeated exits. Lifecycle errors are not rolled back and can interrupt cleanup.
- Forward both keyboard callbacks and supply the action mapping; otherwise Escape will not work. The overlay pauses scene updates, not audio globally.

## Further reading

[SceneManager architecture](/architecture/modules/scene-manager) · [SceneLoader architecture](/architecture/modules/scene-loader) · [Scene architecture](/architecture/modules/scene) · [SceneManager API](/api/scene-manager).
