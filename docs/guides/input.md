# Map keyboard, mouse, and gamepad actions

## Goal and prerequisites

Move a marker with keys, mouse clicks, or a gamepad, and count presses and releases. Start from [Your First Project](/getting-started/first-project), including its `engine/` directory. No custom assets are needed. The engine installs the LÖVE input callbacks during `Engine:load()`, so `main.lua` only forwards `load`, `update`, `draw`, and `quit`.

## 1. Map actions to devices

Add these entries to the table in `game/inputMaps.lua`, preserving other actions:

```lua
guide_left = {
    keys = { "left", "a" },
    gamepad = {
        "dpleft",
        axes = { leftx = -1 },
    },
},
guide_right = {
    keys = { "right", "d" },
    gamepad = {
        "dpright",
        axes = { leftx = 1 },
    },
},
guide_count = {
    keys = { "space" },
    mouse = { 1 },
    gamepad = { "a" },
},
```

Each action is a table with optional `keys`, `mouse`, and `gamepad` sections. `keys` holds LÖVE key names, `mouse` holds LÖVE button numbers (`1` left, `2` right, `3` middle), and `gamepad` holds LÖVE gamepad button names plus an optional `axes` table that maps an axis name to `-1` or `1`. Ensure `Engine.new` receives `inputMaps = require("game.inputMaps")` and set `initialScene = "guideInput"`.

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
    self.y = 90
    self.presses = 0
    self.releases = 0
    return self
end

function InputScene:update(dt)
    local input = self.context.inputManager
    local direction = 0
    if input:isDown("guide_left") then direction = direction - 1 end
    if input:isDown("guide_right") then direction = direction + 1 end
    self.x = math.max(8, math.min(312, self.x + direction * 100 * dt))

    if input:isJustPressed("guide_count") then self.presses = self.presses + 1 end
    if input:isJustReleased("guide_count") then self.releases = self.releases + 1 end
end

function InputScene:draw()
    local input = self.context.inputManager
    local mx, my = input:getMousePosition()

    love.graphics.print("Arrows/A/D or d-pad/stick: move", 8, 8)
    love.graphics.print("Space, click, or gamepad A: count", 8, 28)
    love.graphics.print("Presses: " .. self.presses .. " Releases: " .. self.releases, 8, 48)
    love.graphics.print("Mouse: " .. mx .. ", " .. my, 8, 68)
    love.graphics.rectangle("fill", self.x, self.y, 16, 16)
end

return InputScene
```

## 3. Run and observe

Run `love .` from the project root. Hold Left/A, Right/D, the d-pad, or the left stick to move; press and release Space, a mouse button, or gamepad A to update the counters. Opposite directions cancel. The bounds assume the first project's `320 x 180` logical viewport; adapt them for a different resolution. The example game's `game/inputMaps.lua` and `game/ecs/systems/playerSystem.lua` also map and query actions.

## Frame lifecycle and edges

`Engine:load()` replaces LÖVE's `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `mousemoved`, `gamepadpressed`, `gamepadreleased`, `gamepadaxis`, `joystickadded`, and `joystickremoved` handlers with its own. Do not forward those callbacks yourself. If a game needs extra handling, define its callbacks after `engine:load()` and call the matching `engine` method too.

During `Engine:update(dt)` the engine dispatches queued events, recomputes gamepad axis edges, updates the scenes, updates audio, and finally clears transient edges and mouse delta. `isDown` remains true while any binding is held; `isJustPressed` and `isJustReleased` describe bindings that changed since the previous frame. Queries do not consume edges, and pressing a binding that is already held does not create a new press.

Edges are tracked per binding and combined with OR across devices: releasing one binding may report a release while another remains down, and a press and release between updates can make both edge queries true.

## Mouse

`InputManager` records the last mouse position on press, release, and move, and accumulates movement in a per-frame delta that `reset()` clears. `getMousePosition()` and `getMouseDelta()` return window coordinates, not logical viewport coordinates; convert them with `context.viewport.screenToViewport(...)` before drawing or comparing against camera-world positions.

## Gamepad

Only the first connected gamepad is tracked. A second gamepad is ignored until the first is removed. Buttons use LÖVE names such as `a`, `b`, `x`, `y`, `dpup`, `dpleft`, or `start`. Axes use names such as `leftx`, `lefty`, or `triggerleft` and count as pressed when their value reaches `0.5` in absolute value; `-1` reads the negative half of the axis and `1` the positive half. Axis bindings need at least one `InputManager:update()` before they report state.

When a gamepad is connected or removed, the manager emits `gamepad_connected` or `gamepad_disconnected` through the engine's event manager. Both payloads contain `{ joystick = joystick, name = joystick:getName() }`; see [Events](/api/events).

## Errors and limitations

- Maps are not validated. Any action name can be queried: unknown actions return `false`, and an action without `keys`, `mouse`, or `gamepad` simply has no bindings. A non-table action value fails when it is queried.
- Key, button, axis, and gamepad names are not checked against LÖVE; typos silently never match.
- Held state is not cleared automatically on focus loss. The manager retains the supplied mapping table rather than copying it.
- Mouse button numbers and gamepad names follow LÖVE's conventions; this page does not map them per platform.
- `InputManager` only emits gamepad events when it is given an event manager; the engine always provides one.

## Further reading

[InputManager architecture](/architecture/modules/input-manager) · [Engine architecture](/architecture/modules/engine) · [InputManager API](/api/input-manager) · [Events API](/api/events).
