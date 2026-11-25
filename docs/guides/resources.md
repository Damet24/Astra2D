# Load and release a shared image

## Goal and prerequisites

Display an image and a font through the resource manager, then release the scene's interest when it is destroyed. Start from [Your First Project](/getting-started/first-project), including its LÖVE callbacks. Supply your own PNG at `game/assets/guide-logo.png`; a new project does not include that image.

## 1. Register the resources

Create `game/config/resourceDefinitions.lua` and its parent directory if they do not exist; start the file with `return {}`. Add these entries inside the returned table, preserving any existing entries:

```lua
guide_logo = { type = "image", path = "game/assets/guide-logo.png" },
guide_font = { type = "font", size = 18 },
```

These are table entries, not a standalone Lua file. Ensure `Engine.new` in `main.lua` receives `resourceDefinitions = require("game.config.resourceDefinitions")`, and set `initialScene = "guideResources"`. The default image loader uses a LÖVE filesystem path; the font loader creates a font by size and does not accept a font file path. For many images or sounds sharing a root directory, [resource definition utilities](/api/resources-utils) provide `addImages` and `addSound`.

## 2. Create the resource-consuming scene

Create `game/scenes/guideResources.lua`:

```lua
local Scene = require("engine.scene.scene")
local Resources = {}
Resources.__index = Resources
setmetatable(Resources, { __index = Scene })

function Resources.new(context)
    local self = setmetatable(Scene.new(), Resources)
    self.context = context
    return self
end

function Resources:onLoad()
    local resources = self.context.resourceManager
    self.logo = resources:get(self, "guide_logo")
    self.font = resources:get(self, "guide_font")
end

function Resources:draw()
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.print("Shared image", 16, 16)
    love.graphics.draw(self.logo, 16, 48)
    love.graphics.pop()
end

function Resources:onDestroy()
    self.context.resourceManager:releaseAll(self)
    self.logo, self.font = nil, nil
end

return Resources
```

## 3. Run and check sharing

Run `love .` from the project root. The image should appear under the text. Closing the game destroys the scene and releases its interests. To release just the image earlier, call `self.context.resourceManager:release(self, "guide_logo")` and stop drawing or using `self.logo` afterward.

The repository's `game/scenes/pause.lua` uses `get(self, "pause_font")` and `releaseAll(self)` in the same way. Its definitions live in `game/config/resourceDefinitions.lua`; these example-game IDs are not supplied automatically to a new project.

## Lifecycle and sharing

The first `get(consumer, id)` loads and caches the value; subsequent requests for that ID share it. A consumer is a non-nil Lua key, typically the scene object. Ownership is a set, not a reference count: multiple `get` calls by the same consumer require only one release. Another consumer retains the resource until it also releases it. After the last release, another `get` loads it again.

`onLoad` runs for each constructed scene instance; `onExit` may only mean the scene is covered. Release in `onDestroy`. On normal quit the engine destroys scenes, shuts down audio and finally force-releases remaining resources.

## Errors and limitations

- Undefined IDs and missing loaders raise errors; invalid files or paths fail in LÖVE when first loaded. IDs are case-sensitive. Check the file is in the game filesystem and the definition is passed to the engine.
- Default types are `image`, `font`, and `sound`; sound definitions require `path` and `soundType = "static"` or `"stream"`. Supplying `resourceLoaders` replaces the default registry rather than extending it.
- Do not call `:release()` on the shared image or font yourself. `releaseResource` and `releaseAllResources` forcibly invalidate values even if other consumers still hold them. `releaseAll(self)` does not release audio manager ownership.
- Image filtering is set by LÖVE's default at creation, not by a definition field. A `setFilter` on the cached image affects all its consumers.

## Further reading

[ResourceManager architecture](/architecture/modules/resource-manager) · [Scene architecture](/architecture/modules/scene) · [ResourceManager API](/api/resource-manager).
