# SceneLoader API

Module: `require("engine.scene.sceneLoader")`. Resolves and constructs scenes; it does not manage their lifecycle. See [architecture](../architecture/modules/scene-loader.md), the [scenes guide](../guides/scenes.md) and [first project](../getting-started/first-project.md).

## Configuration and methods

| Signature | Parameters, result and effects |
| --- | --- |
| `SceneLoader.new(config)` | Returns a loader. `config` is an optional table, but `config.context` must be truthy or an assertion fails; `config.scenesPath` defaults to `"game.scenes"` when nil or false. Neither interface nor path is validated here. |
| `loader:load(sceneName, dependencies)` | `sceneName` must be a string; `dependencies` is ignored. Requires `scenesPath .. "." .. sceneName` and returns `SceneClass.new(context)`. A failed `require` is rethrown with the scene name; a module without a table-valued class and function `.new` triggers an assertion. Constructor errors propagate unwrapped. |

Lua's `require` cache normally loads module code once, but each call invokes the constructor again. The constructor return is not validated. No `onLoad` or `onEnter` is called here; [SceneManager](scene-manager.md) calls them. Its merged dependencies are not forwarded to the constructor. [Engine](engine.md) additionally validates `scenesPath` as a non-empty string.

## Example

```lua
local SceneLoader = require("engine.scene.sceneLoader")
-- context is the shared GameContext; the module exists in this game.
local loader = SceneLoader.new({ context = context })
local scene = loader:load("levels.level01")
```

The default prefix resolves this identifier to `game.scenes.levels.level01`; loading alone does not enter the scene.
