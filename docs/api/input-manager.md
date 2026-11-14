# InputManager API

Module: `require("engine.input.inputManager")`. Maps keyboard events to named actions. See [architecture](../architecture/modules/input-manager.md), the [input guide](../guides/input.md) and [first project](../getting-started/first-project.md).

## Configuration and dependencies

`InputManager.new(inputMaps)` returns a manager with empty key state and retains the original table. `inputMaps` must be a table (empty is valid); each action must be a non-empty string mapped to a non-empty contiguous array of unique non-empty key strings. The same key may occur in different actions. Invalid maps assert; key names are not checked against LÖVE. [Engine](engine.md) requires this map and exposes the manager through the context. Only keyboard events are handled.

## Methods and event timing

`key` is a LÖVE key string; `action` is a mapped action name. Except for queries, methods return **no values**.

| Signature | Result and effects |
| --- | --- |
| `input:keypressed(key)` | Prints the key; if not held, marks it held and just pressed. Repeated presses while held create no new edge. |
| `input:keyreleased(key)` | Prints the key; if held, clears held state and marks it just released. An unheld release is otherwise ignored. |
| `input:isDown(action)` | Boolean: any bound key is held. |
| `input:isJustPressed(action)` | Boolean: any bound key was newly pressed since the last input `update`. |
| `input:isJustReleased(action)` | Boolean: any bound key was released since the last input `update`. |
| `input:update()` | Clears both transient edge tables; held keys remain held. |

Unknown actions return false. Edges are per-key and queries OR the bindings without consuming them: a release may be true while another binding remains down, and a press and release between updates may make both edges true. Focus loss does not reset held state automatically.

Forward both LÖVE keyboard callbacks. During an active `Engine:update(dt)`, scene updates and transitions run first, then audio, then input edges are cleared. Query edges during the scene update; clearing early loses them. Engine forwards key events even before load or after quit.

## Example

```lua
local InputManager = require("engine.input.inputManager")
local input = InputManager.new({ jump = { "space" } })
input:keypressed("space")
local pressed = input:isJustPressed("jump") -- true
input:update() -- clears the edge, not the held key
input:keyreleased("space")
```
