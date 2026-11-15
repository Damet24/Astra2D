# InputManager

[Architecture overview](/architecture/overview) · [ResourceManager](./resource-manager) · [AudioManager](./audio-manager)

## Purpose and relationships

`engine/input/inputManager.lua` maps named actions to key names and tracks held, just-pressed and just-released keys. `Engine` constructs it from `inputMaps`, exposes it as `context.inputManager` and forwards LÖVE keyboard callbacks. Scenes query the context; systems such as `PlayerSystem` receive the manager directly. The implementation handles keyboard events only; it does not subscribe to mouse or gamepad callbacks.

## Configuration

`InputManager.new(inputMaps)` requires a table, also required as `Engine.new`'s `inputMaps`. An empty table is valid. Each action name must be a non-empty string and its value a non-empty contiguous array starting at index 1 of unique, non-empty binding strings. The same key may belong to different actions. Invalid maps raise assertions at construction; binding names are not checked against LÖVE's key list. The original table is retained, not copied.

For example, `game/inputMaps.lua` contains:

```lua
return {
    accept = { "return" },
    exit = { "escape" },
    move_left = { "left", "a" },
    move_right = { "right", "e" },
    jump = { "space" },
}
```

## Public API and frame lifecycle

| Method | Behavior |
| --- | --- |
| `InputManager.new(inputMaps)` | Validates the map and creates empty key states. |
| `keypressed(key)` | Marks a previously unheld key as held and just pressed. Repeated presses while held do not create another edge. |
| `keyreleased(key)` | Clears a held key and marks it just released; releases of keys not held are ignored. |
| `isDown(action)` | Returns `true` if any binding is held. |
| `isJustPressed(action)` | Returns `true` if any binding was newly pressed since the last `update`. |
| `isJustReleased(action)` | Returns `true` if any binding was released since the last `update`. |
| `update()` | Replaces the transient just-pressed and just-released tables with empty ones; held keys remain held. |

Unknown actions return `false`. Edges are tracked **per key**, then combined with OR for an action: releasing one binding can report `isJustReleased` while another still makes `isDown` true. A press and release between updates can make both edge queries true. Queries do not consume edges, so multiple systems can read them. Both event methods currently print the key, including repeated or ignored events.

`main.lua` forwards `love.keypressed` and `love.keyreleased` to `Engine`. On each loaded frame, `Engine:update(dt)` updates scenes (including pending transitions), updates audio, then clears input edges. Read transient actions during scene/system update, before that final clear; calling `update()` prematurely loses the edges. Held state is not automatically reset on focus loss.

## Example

The level checks the configured `exit` action during its update:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

In `game/ecs/systems/playerSystem.lua`, `isDown("move_left")` and `isDown("move_right")` drive movement, while `isJustPressed("jump")` triggers a jump and a sound.
