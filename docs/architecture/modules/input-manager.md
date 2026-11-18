# InputManager

[Architecture overview](/architecture/overview) · [ResourceManager](./resource-manager) · [AudioManager](./audio-manager)

## Purpose and relationships

`engine/input/inputManager.lua` maps named actions to keyboard keys, mouse buttons, gamepad buttons, and gamepad axes. It tracks held, just-pressed, and just-released state per device and resolves queries across every binding of an action. [Engine](engine.md) constructs it from `inputMaps` and its [EventManager](/api/events), exposes it as `context.inputManager`, and installs all LÖVE input callbacks during `load`. Scenes query the context; systems such as `PlayerSystem` receive the manager directly.

The manager owns three state groups: `keyboard`, `mouse`, and `gamepad`. Each group stores pressed, just-pressed, and just-released tables; mouse state adds position and frame delta; gamepad state adds raw axes, threshold states, and the tracked joystick.

## Configuration

`InputManager.new(inputMaps, events)` expects the mapping table and an optional event manager, also supplied as `Engine.new`'s `inputMaps`. An empty table is valid. Each action maps to a table with optional sections:

```lua
return {
    accept = {
        keys = { "return", "space" },
        mouse = { 1 },
        gamepad = { "a" },
    },
    move_left = {
        keys = { "left", "a" },
        gamepad = {
            "dpleft",
            axes = { leftx = -1 },
        },
    },
    jump = {
        keys = { "space" },
        gamepad = { "a" },
    },
}
```

`keys` contains LÖVE key names, `mouse` contains LÖVE button numbers, and `gamepad` contains LÖVE button names plus an optional `axes` table whose values are `-1` (negative half) or `1` (positive half). The same key or button may belong to different actions. The manager performs no validation: a missing section simply contributes no bindings, unknown actions return `false`, and a non-table action value fails when queried. Binding names are not checked against LÖVE. The original mapping table is retained, not copied.

The `events` argument is used only for gamepad connection notifications. Without it the manager still handles keyboard and mouse queries, but `joystickadded` raises when it tries to emit. The engine always passes its event manager.

## Public API and frame lifecycle

| Method | Behavior |
| --- | --- |
| `InputManager.new(inputMaps, events)` | Creates empty device states and retains both arguments. |
| `keypressed(key)` / `keyreleased(key)` | Updates keyboard edges: a previously unheld key becomes held and just pressed; a held key becomes released and just released. Other events are ignored. |
| `mousepressed(...)` / `mousereleased(...)` | Updates mouse button edges with the same rules and stores the position. |
| `mousemoved(x, y, dx, dy, istouch)` | Stores the position and accumulates the frame delta. |
| `gamepadpressed(joystick, button)` / `gamepadreleased(joystick, button)` | Updates button edges for the tracked gamepad only. |
| `gamepadaxis(joystick, axis, value)` | Stores the raw axis value for the tracked gamepad. |
| `joystickadded(joystick)` / `joystickremoved(joystick)` | Tracks the first gamepad, emits `gamepad_connected` / `gamepad_disconnected`, and clears state on disconnect. |
| `isDown(action)` / `isJustPressed(action)` / `isJustReleased(action)` | OR every keyboard, mouse, gamepad-button, and axis binding of the action. |
| `isMouseDown(button)` / `isMouseJustPressed(button)` / `isMouseJustReleased(button)` | Direct mouse button queries. |
| `getMousePosition()` / `getMouseDelta()` | Window-space position and per-frame movement. |
| `update()` | Converts raw axes to threshold states and axis edges. Does not clear existing edges. |
| `reset()` | Empties all just-pressed and just-released tables and the mouse delta; held and axis states remain. |

Axes become active at or beyond `0.5` absolute value. `update()` compares each axis with its previous positive/negative state and records edges under the synthetic names `<axis>_positive` and `<axis>_negative`; a binding's `-1`/`1` direction selects which half it reads. An axis binding reports nothing until `update()` has processed at least one value.

Queries return `false` for unknown actions and for actions without a matching section. Edges are tracked **per binding**, then combined with OR: releasing one binding can report `isJustReleased` while another still makes `isDown` true, and a press and release between resets can make both edge queries true. Queries do not consume edges, so multiple systems can read them.

`Engine:load()` installs the LÖVE callbacks and forwards keyboard, mouse, gamepad, and joystick events. Each loaded frame runs:

1. `EventManager:dispatch()` delivers queued events, including gamepad connections from the previous event batch.
2. `InputManager:update()` recomputes axis edges.
3. Scenes and systems update and read the current input state.
4. `AudioManager:update(dt)` runs.
5. `InputManager:reset()` clears the transient edges and mouse delta.

Read transient actions during the scene or system update, before the final reset; calling `reset()` earlier loses them. Focus loss does not reset held state. Only the first connected gamepad is tracked; additional gamepads are ignored until it is removed.

## Example

The level checks the configured `exit` action during its update:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

In `game/ecs/systems/playerSystem.lua`, `isDown("move_left")` and `isDown("move_right")` drive movement, while `isJustPressed("jump")` triggers a jump and a sound. The same actions can include gamepad buttons and axes without changing the scene code.
