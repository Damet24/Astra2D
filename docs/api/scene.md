# Scene API

Module: `require("engine.scene.scene")`. Base scene interface with no automatic world, camera or resource management. See [architecture](../architecture/modules/scene.md), the [scenes guide](../guides/scenes.md) and [first project](../getting-started/first-project.md).

## Construction and fields

`Scene.new()` takes no arguments and returns a scene with `updateBelow = false` and `drawBelow = false`. It does not store a context. Scene modules loaded by [SceneLoader](scene-loader.md) must instead expose `new(context)` and may store the shared context themselves.

Each truthy flag lets [SceneManager](scene-manager.md) continue down the stack for the respective update or draw pass; selected scenes run bottom to top. Flags are independent.

## Methods

These base hooks do nothing and return **no values**. Override them as needed; the manager calls them without protecting against errors.

| Signature | Invocation / intended use |
| --- | --- |
| `scene:onLoad()` | Once for a normally constructed instance, before it is inserted and entered. Acquire scene-owned resources here. |
| `scene:onEnter()` | When made the top scene, including when uncovered after a pop. |
| `scene:onExit()` | When covered or removed; clear-and-push also exits already covered scenes. |
| `scene:onDestroy()` | When discarded. Release scene-owned resources here; the base implementation does not release them. |
| `scene:update(dt)` | During selected updates; `dt` is elapsed seconds. |
| `scene:draw()` | During selected draws, inside the engine viewport when driven by Engine. |

See the [lifecycle order and queue](scene-manager.md#lifecycle-and-queue): `onEnter`/`onExit` may repeat; an error can interrupt callbacks and cleanup. A scene retained beneath another is not destroyed merely by being covered.

## Example

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
function Overlay:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
return Overlay
```

This overlay draws lower scenes but, with the default `updateBelow`, does not update them.
