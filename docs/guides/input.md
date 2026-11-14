# Move with actions and detect key edges

## Goal and prerequisites

Move a marker with two keys and count presses and releases. Start from [Your First Project](/getting-started/first-project), including its `engine/` directory and LÖVE callbacks. No custom assets are needed.

## 1. Map actions to keys

Add these entries to the table in `game/inputMaps.lua`, preserving other actions:

```lua
guide_left = { "left", "a" },
guide_right = { "right", "d" },
guide_count = { "space" },
```

These are table entries. Ensure `Engine.new` receives `inputMaps = require("game.inputMaps")` and set `initialScene = "guideInput"`. In `main.lua`, keep the callbacks from the first project, especially:

```lua
function love.keypressed(key)
    engine:keypressed(key)
end

function love.keyreleased(key)
    engine:keyreleased(key)
end
```

## 2. Create the input scene

Create `game/scenes/guideInput.lua`:

```lua
local Scene = require("engine.scene.scene")
local InputScene = {}
InputScene.__index = InputScene
setmetatable(InputScene, { __index = Scene })

function InputScene.new(context)
    local self = setmetatable(Scene.new(), InputScene)
    self.context = context
    self.x = 160
    self.presses = 0
    self.releases = 0
    return self
end

function InputScene:update(dt)
    local input = self.context.inputManager
    local direction = 0
    if input:isDown("guide_left") then direction = direction - 1 end
    if input:isDown("guide_right") then direction = direction + 1 end
    self.x = math.max(0, math.min(304, self.x + direction * 100 * dt))
    if input:isJustPressed("guide_count") then self.presses = self.presses + 1 end
    if input:isJustReleased("guide_count") then self.releases = self.releases + 1 end
end

function InputScene:draw()
    love.graphics.print("Arrows/A/D: move; Space: count", 8, 8)
    love.graphics.print("Presses: " .. self.presses .. " Releases: " .. self.releases, 8, 28)
    love.graphics.rectangle("fill", self.x, 70, 16, 16)
end

return InputScene
```

## 3. Run and observe

Run `love .` from the project root. Hold Left/A or Right/D to move; press and release Space to update the two counters. Opposite directions cancel. The bounds assume the first project's 320-pixel logical width; adapt them for a different resolution. The example game's `game/inputMaps.lua` and `game/ecs/systems/playerSystem.lua` also map and query actions.

## Frame lifecycle and key edges

LÖVE sends keyboard events to the engine. During `Engine:update(dt)`, scenes read the current state; after scene transitions and audio update, the engine clears the transient edges. `isDown` remains true while any binding is held; `isJustPressed` and `isJustReleased` describe key events since the last input update. Queries do not consume them. Do not manually clear input before scenes update.

Edges are per key, combined with OR: releasing one binding may report a release while another remains down. Pressing and releasing between updates can make both edge queries true. Repeated keypress events while held do not create new press edges.

## Errors and limitations

- `inputMaps` is required, even if empty. Each action needs a non-empty contiguous array of unique, non-empty key strings; malformed maps fail at construction. Unknown action names return `false`, and binding strings are not validated against LÖVE's key list.
- Only keyboard callbacks are handled; strings resembling gamepad buttons do not add gamepad support. The callbacks currently print keys to the console.
- Held state is not automatically cleared on focus loss. The manager retains the supplied mapping table rather than copying it.

## Further reading

[InputManager architecture](/architecture/modules/input-manager) · [Engine architecture](/architecture/modules/engine) · [InputManager API](/api/input-manager).
