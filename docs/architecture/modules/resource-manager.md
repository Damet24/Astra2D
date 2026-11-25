# ResourceManager

[Architecture overview](/architecture/overview) · [InputManager](./input-manager) · [AudioManager](./audio-manager)

## Purpose and relationships

`engine/resources/resourceManager.lua` loads resources on demand, caches them by ID and tracks the consumers that need each one. The last consumer's release unloads the resource. It is independent of scenes: `Engine` creates one shared manager, exposes it through `GameContext`, and passes it to `AudioManager`. Scenes normally use themselves as consumers and release their resources in `onDestroy`; audio is a separate consumer.

## Configuration and loaders

`ResourceManager.new(definitions, loaders)` takes two tables. `definitions[id]` is passed to the loader selected by `definition.type`; `loaders[type]` must provide plain functions `load(definition)` and `release(resource)`. `Engine.new` accepts these as `resourceDefinitions` (default `{}`) and `resourceLoaders`. A supplied loader table replaces, rather than extends, the default table.

The default registry in `engine/resources/loaders/loaders.lua` contains:

| Type | Definition fields | Load and release |
| --- | --- | --- |
| `image` | `path`: string | `love.graphics.newImage(path)`; calls `image:release()`. |
| `sound` | `path`: string; `soundType`: `"static"` or `"stream"` | `love.audio.newSource(path, soundType)`; calls `source:release()`. |
| `font` | `size`: number | `love.graphics.newFont(size)`; calls `font:release()`. The loader does not use a font path. |

For example, `game/config/resourceDefinitions.lua` defines `pause_font` as `{ type = "font", size = 18 }`, `music` as a streamed sound and `jump` as a static sound. Paths are LÖVE filesystem paths. Loader assertions check the types shown above; LÖVE can still reject invalid paths, sizes or files.

### Image filtering

The image loader does not read a filter field or call `setFilter`; images use LÖVE's default filter at creation. `Engine:load()` configures the Shove viewport before loading the initial scene: `rendering.pixelPerfect = true` selects pixel scaling and `nearest`, otherwise it selects aspect scaling and `linear`. Shove sets the graphics default filter. This is separate from the resource definition, and changing the default later does not retroactively change existing images. A direct `image:setFilter(...)` changes the shared cached image for every consumer.

## Public API

| Method | Behavior |
| --- | --- |
| `ResourceManager.new(definitions, loaders)` | Creates an empty cache with the supplied tables. |
| `get(consumer, resourceId)` | Loads on the first request, registers the consumer and returns the cached value. An undefined ID or missing loader raises an assertion; loader errors propagate. |
| `release(consumer, resourceId)` | Removes that consumer; calls the loader's `release` when none remain. Unknown resources or consumers are ignored. |
| `releaseAll(consumer)` | Releases that consumer's interest in every cached resource. |
| `releaseResource(resourceId)` | Forces release and removes the cached resource, regardless of consumers; unknown IDs are ignored. |
| `releaseAllResources()` | Forces release of every cached resource, regardless of consumers. |

A consumer is a non-nil Lua table key, usually an object. Ownership is a **set**, not a reference count: repeated `get` calls by the same consumer add only one entry, so one `release` removes its interest. Different IDs are cached separately even if their definitions point to the same file. After the last release, another `get` reloads the resource. Forced releases can invalidate references still held by consumers; consumers should not manually release the shared value.

## Example

The pause scene uses the actual `pause_font` definition and gives up its interest only on destruction:

```lua
function Pause:onLoad()
    self.font = self.context.resourceManager:get(self, "pause_font")
end

function Pause:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

If another consumer has requested `pause_font`, it remains cached until that consumer also releases it. On `Engine:quit()`, scenes are cleared, audio shuts down, then remaining resources are forcibly released; errors in an earlier phase can prevent later cleanup.
