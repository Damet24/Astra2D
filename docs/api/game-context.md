# GameContext API

Module: `require("engine.core.gameContext")`. A mutable service container shared by scenes, not an owner of their lifecycle. See [architecture](../architecture/modules/game-context.md) and [first project](../getting-started/first-project.md).

## Construction and fields

`GameContext.new(services)` returns a context. `services` must be truthy and provide truthy `resourceManager` and `audioManager`; missing values raise assertions. Optional `sceneManager` is copied; no interface validation or other fields are copied. This is the only method.

| Field | Availability and dependency |
| --- | --- |
| `resourceManager` | Required at construction; shared [ResourceManager](resource-manager.md). |
| `audioManager` | Required at construction; shared [AudioManager](audio-manager.md). |
| `sceneManager` | Optional at construction; [Engine](engine.md) assigns it after creating the loader and manager. |
| `inputManager` | Assigned by `Engine.new`, not by this constructor. |
| `events` | Assigned by `Engine.new`; shared [EventManager](events.md). |
| `viewport` | Assigned by `Engine:load()` before the initial scene is constructed. |

The built-in [SceneLoader](scene-loader.md) passes the same context reference to each scene constructor. Manually created contexts do not acquire input, events, or viewport automatically, even if those keys were supplied in `services`. The container neither updates nor releases services.

## Example

In a scene that stores its constructor's `context`:

```lua
function MyScene:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

This releases the scene's consumer interest; the context does not do so automatically.
