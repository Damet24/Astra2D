# GameContext

`engine/core/gameContext.lua` is a small, shared service container and the boundary through which scenes access engine services. It does not construct, update, or release those services. See the [architecture overview](../overview.md).

## Responsibilities and relationships

[Engine](engine.md) creates the context with the resource and audio managers. It then constructs the [SceneLoader](scene-loader.md) with that context, constructs the [SceneManager](scene-manager.md), and adds the scene and input managers to the context. During `Engine:load()`, it adds the viewport before the first scene is constructed. The loader passes the **same context reference** to every scene constructor for that engine. This avoids requiring a scene to receive the engine or create shared services itself.

## Public construction and fields

`GameContext.new(services)` requires a truthy `services` object and truthy `services.resourceManager` and `services.audioManager`; it accepts `services.sceneManager` as optional. It returns a context with those three fields. The constructor does not copy other fields from `services`, validate service interfaces, or provide other methods.

| Field | Availability in the normal engine lifecycle | Use |
| --- | --- | --- |
| [`resourceManager`](resource-manager.md) | Required at construction | Acquire resources using the scene as consumer; release them when no longer needed. |
| [`audioManager`](audio-manager.md) | Required at construction | Play and control shared audio. |
| `sceneManager` | Optional at construction; assigned by `Engine.new` | Request deferred transitions. |
| [`inputManager`](input-manager.md) | Added by `Engine.new`, not by `GameContext.new` | Query mapped actions. |
| [`viewport`](rendering.md) | Added by `Engine:load()` | Access Shove's logical viewport and conversions. |

A manually constructed context does not automatically gain `inputManager` or `viewport`, even if those keys are passed in `services`. They must be assigned by its owner. Since the object is shared and mutable, changes are visible to other scenes; treat adding or replacing services as an architectural decision rather than using it as a global service locator.

## Example: scene access

In a scene whose constructor stores `context` as `self.context`, use the shared services without constructing them:

```lua
function MyScene:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop() -- deferred
    end
end

function MyScene:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

This assumes `exit` is present in `inputMaps` and that the scene uses itself as a resource consumer. A `pop` does not change the stack immediately; see [SceneManager](scene-manager.md). The context itself does not enforce cleanup or prevent direct access to other objects.
