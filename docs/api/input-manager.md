# InputManager API

Module: `require("engine.input.inputManager")`. Maps keyboard, mouse, and gamepad events to named actions. See [architecture](../architecture/modules/input-manager.md), the [input guide](../guides/input.md), and [first project](../getting-started/first-project.md).

## Configuration and dependencies

`InputManager.new(inputMaps, events)` returns a manager with empty device state and retains the original mapping table. `inputMaps` must be a table (empty is valid); each action is a table with optional `keys`, `mouse`, and `gamepad` sections:

```lua
{
    jump = {
        keys = { "space" },
        mouse = { 1 },
        gamepad = {
            "a",
            axes = { leftx = 1 },
        },
    },
}
```

`keys` and `gamepad` list LÖVE key and button names; `mouse` lists LÖVE button numbers. The optional `gamepad.axes` table maps an axis name to `-1` (negative half) or `1` (positive half). Bindings are not validated and names are not checked against LÖVE. `events` is an optional [EventManager](events.md) used to emit `gamepad_connected` and `gamepad_disconnected`; queries work without it, but connecting a gamepad then raises an error.

[Engine](engine.md) constructs the manager from its `inputMaps` and its event manager, then exposes it as `context.inputManager`. The manager keeps the table it receives instead of copying it.

## Methods and event timing

`action` is a mapped action name, `key` a LÖVE key string, `button` a LÖVE mouse number or gamepad button name, and `axis` a LÖVE axis name. Except for queries, methods return **no values**.

| Signature | Result and effects |
| --- | --- |
| `input:keypressed(key)` / `input:keyreleased(key)` | Marks a previously unheld key as held and just pressed, or clears it and marks it just released. Repeated presses while held and releases of unheld keys create no edge. |
| `input:mousepressed(x, y, button, istouch, presses)` / `input:mousereleased(x, y, button, istouch, presses)` | Same edge rules per mouse button; also stores the position. |
| `input:mousemoved(x, y, dx, dy, istouch)` | Stores the position and accumulates `dx`/`dy` into the frame delta. |
| `input:gamepadpressed(joystick, button)` / `input:gamepadreleased(joystick, button)` | Same edge rules per button. Events from a joystick other than the tracked gamepad are ignored. |
| `input:gamepadaxis(joystick, axis, value)` | Stores the raw axis value; it is converted to edges by `update()`. |
| `input:joystickadded(joystick)` | Tracks the first gamepad and emits `gamepad_connected` with `{ joystick, name }`; non-gamepads and additional gamepads are ignored. Requires `events`. |
| `input:joystickremoved(joystick)` | If it is the tracked gamepad, emits `gamepad_disconnected` with `{ joystick, name }` and clears all gamepad state. Requires `events`. |
| `input:isDown(action)` | Boolean: any key, mouse button, gamepad button, or axis half bound to the action is active. |
| `input:isJustPressed(action)` | Boolean: any binding became active since the last `reset`. |
| `input:isJustReleased(action)` | Boolean: any binding became inactive since the last `reset`. |
| `input:isMouseDown(button)`, `input:isMouseJustPressed(button)`, `input:isMouseJustReleased(button)` | Boolean device queries that do not need an action. |
| `input:getMousePosition()` | Last mouse `x, y` in window coordinates. |
| `input:getMouseDelta()` | Accumulated `dx, dy` since the last `reset`. |
| `input:update()` | Recomputes gamepad axis states and creates axis press/release edges. It does **not** clear edges. |
| `input:reset()` | Clears every just-pressed and just-released table and the mouse delta; held state and axis states remain. |

Unknown actions return `false`. An action may mix devices; the queries OR every binding, so releasing one device can report a release while another keeps the action down. Queries do not consume edges.

Axes count as active at or beyond `0.5` in absolute value, and the `-1`/`1` direction selects the negative or positive half. An axis binding cannot report state until `update()` has seen an axis value. `reset()` does not clear held bindings and focus loss does not reset them automatically.

`Engine:update(dt)` dispatches events, calls `input:update()`, updates scenes and audio, then calls `input:reset()`. Read transient actions during the scene or system update, before that final reset. The engine installs the LÖVE callbacks during `load`, so games do not forward them.

## Example

```lua
local InputManager = require("engine.input.inputManager")
local input = InputManager.new({ jump = { keys = { "space" } } })
input:keypressed("space")
local pressed = input:isJustPressed("jump") -- true
input:update() -- recomputes axis edges; does not clear the press
input:reset() -- clears transient edges, not the held key
input:keyreleased("space")
```
