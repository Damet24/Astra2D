# ResourceManager API

Module: `require("engine.resources.resourceManager")`. On-demand cache keyed by resource ID, with consumer-set ownership. See [architecture](../architecture/modules/resource-manager.md), the [resources guide](../guides/resources.md) and [first project](../getting-started/first-project.md).

## Configuration and loaders

`ResourceManager.new(definitions, loaders)` returns an empty manager, retaining the supplied tables without validating them. `definitions[id]` is a definition with `type`; `loaders[type]` provides plain functions `load(definition)` returning the resource and `release(resource)` releasing it. [Engine](engine.md) defaults definitions to `{}` and loaders to the built-in registry; supplying loaders replaces that registry.

| Built-in type | Definition | Load / release |
| --- | --- | --- |
| `image` | `path`: string | `love.graphics.newImage(path)` / `image:release()`. |
| `sound` | `path`: string; `soundType`: `"static"` or `"stream"` | `love.audio.newSource(path, soundType)` / `source:release()`. |
| `font` | `size`: number | `love.graphics.newFont(size)` / `font:release()`; no font path is used. |

Built-in loaders assert these fields; LÖVE can reject invalid assets or sizes. Images use LÖVE's default filter at creation, not a definition field. Engine's Shove setup sets that default before the initial scene loads.

## Methods

`consumer` is a non-nil Lua table key, typically the scene or audio manager; `resourceId` is the definition/cache key. Except for `get`, instance methods return **no values**.

| Signature | Result and effects |
| --- | --- |
| `manager:get(consumer, resourceId)` | Returns the cached resource, loading on first access, and records the consumer. Undefined IDs or missing type loaders assert; loader errors propagate. |
| `manager:release(consumer, resourceId)` | Removes that consumer's interest; when it was the last, calls the loader's release and removes the cache entry. Unknown resources or consumers are ignored. |
| `manager:releaseAll(consumer)` | Releases that consumer's interest in every cached resource. |
| `manager:releaseResource(resourceId)` | Forcibly releases and removes one cached resource regardless of consumers; unknown IDs are ignored. |
| `manager:releaseAllResources()` | Forcibly releases all cached resources regardless of consumers. |

Ownership is a set, not a reference count: repeated `get` by the same consumer needs only one release. Separate IDs cache separately, even for the same file. A later `get` reloads after release. Forced release can invalidate held references; do not directly release a shared cached value. Release errors propagate and can interrupt cleanup.

Scenes must release their interests themselves, normally in `onDestroy`; [AudioManager](audio-manager.md) remains a separate consumer until shutdown. Engine quit clears scenes, shuts audio down, then forces release of remaining resources; an earlier error can prevent later phases.

## Example

```lua
function Pause:onLoad()
    self.font = self.context.resourceManager:get(self, "pause_font")
end
function Pause:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

`pause_font` is defined in the repository's game; the font remains cached while any other consumer holds it.
