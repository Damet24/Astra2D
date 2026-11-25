# Resource definition utilities

`require("engine.resources.utils")` exports helpers for filling the plain definition table consumed by [ResourceManager](resource-manager.md). They reduce repetition when many IDs share an asset root and directory, and keep the duplicate-ID assertion in one place.

## API

| Function | Effect |
| --- | --- |
| `Utils.addImages(definitions, root, directory, images)` | Adds one `{ type = "image", path = root .. directory .. filename }` entry per `id -> filename` pair. |
| `Utils.addSound(definitions, root, directory, sounds, soundType)` | Adds one `{ type = "sound", path = root .. directory .. filename, soundType = soundType }` entry per `id -> filename` pair. |

`definitions` is the table later passed to `Engine.new` as `resourceDefinitions`. `root` and `directory` are concatenated verbatim, so include trailing slashes where needed; `filename` may itself contain subdirectories. An existing ID raises `duplicate resource id: <id>` and leaves its definition unchanged. Iteration uses `pairs`, so entries are added in no particular order.

The helpers only build definitions. They do not check that files exist, validate `soundType`, or load anything; the corresponding loaders do that on first `get`. Supply `soundType = "static"` or `"stream"` as required by the [sound loader](resource-manager.md).

## Example

```lua
local Utils = require("engine.resources.utils")

local definitions = {}
local IMAGES_ROOT = "game/assets/images/"

Utils.addImages(definitions, IMAGES_ROOT, "character_animations/", {
    player_idle = "Idle/Player Idle 48x48.png",
    player_run = "Run/player run 48x48.png",
})

Utils.addSound(definitions, "game/assets/sounds/", "", {
    jump = "jump.wav",
}, "static")

return definitions
```

See [ResourceManager](resource-manager.md) and the [resources guide](../guides/resources.md).
