# SceneLoader

`engine/scene/sceneLoader.lua` turns a scene identifier into an instance. It handles module resolution and construction, not the scene stack or lifecycle; those belong to [SceneManager](scene-manager.md). [Engine](engine.md) constructs the loader with the shared [GameContext](game-context.md). See the [architecture overview](../overview.md).

## Public interface and configuration

- `SceneLoader.new(config)` accepts a configuration table. `config.context` is required and must be truthy; `config.scenesPath` defaults to `"game.scenes"` when nil or false. The loader itself does not validate the path or context interface. When constructed through `Engine`, `scenesPath` must instead be a non-empty string.
- `loader:load(sceneName, dependencies)` requires `sceneName` to be a string, builds `scenesPath .. "." .. sceneName`, and calls `require` inside `pcall`. A require failure is rethrown with the scene name and original error. The loaded module must return a table with a function `new`; the loader returns `SceneClass.new(context)`.
- `dependencies` is currently **ignored**, even though the manager passes a merged table. No extra constructor argument is forwarded. Use the context for shared services.

`require` uses Lua's normal module cache: module code is generally loaded once, while each `load` calls `new` again. The loader does not validate the constructor's return value or call `onLoad`/`onEnter`; the manager does that after construction. Constructor and lifecycle errors are not wrapped by the loader's `pcall`.

## Example: resolving and constructing a scene

With the default prefix, `levels.level01` resolves to the Lua module `game.scenes.levels.level01`, normally `game/scenes/levels/level01.lua`. A scene module can follow this pattern:

```lua
local Scene = require("engine.scene.scene")
local Example = {}
Example.__index = Example
setmetatable(Example, { __index = Scene })

function Example.new(context)
    local self = Scene.new()
    setmetatable(self, Example)
    self.context = context
    return self
end

function Example:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop()
    end
end

return Example
```

Place this example in a module reachable under the configured prefix and provide an `exit` input mapping. The base [Scene](scene.md) supplies the lifecycle and drawing methods the manager calls. A missing module or missing `.new` fails when a queued load is processed, not when the transition is requested. There is no scene registry or factory in this implementation.
